import '../../../../core/utils/documentos.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/repositories/contato_repository.dart';
import '../../../crm/domain/repositories/imovel_repository.dart';
import '../../../locacao/domain/entities/cobranca.dart';
import '../../../locacao/domain/entities/locacao_enums.dart';
import '../../../locacao/domain/repositories/cobranca_repository.dart';
import '../../../locacao/domain/repositories/contrato_locacao_repository.dart';
import '../../../locacao/domain/repositories/despesa_repository.dart';
import '../../../locacao/domain/usecases/repasse_usecases.dart';
import '../../../vendas/domain/entities/venda.dart';
import '../../../vendas/domain/entities/venda_enums.dart';
import '../../../vendas/domain/repositories/parcela_repository.dart';
import '../../../vendas/domain/repositories/venda_repository.dart';
import '../entities/declarante_dimob.dart';
import '../entities/dimob.dart';
import '../repositories/declarante_repository.dart';

/// Monta a DIMOB do ano-calendário a partir dos contratos de locação, das
/// cobranças pagas e das vendas, listando as pendências de preenchimento.
class GerarDimob {
  const GerarDimob(
    this._contratos,
    this._cobrancas,
    this._despesas,
    this._vendas,
    this._parcelas,
    this._contatos,
    this._imoveis,
    this._declarante, [
    this._repasse = const CalcularRepasse(),
  ]);

  final ContratoLocacaoRepository _contratos;
  final CobrancaRepository _cobrancas;
  final DespesaRepository _despesas;
  final VendaRepository _vendas;
  final ParcelaRepository _parcelas;
  final ContatoRepository _contatos;
  final ImovelRepository _imoveis;
  final DeclaranteRepository _declarante;
  final CalcularRepasse _repasse;

  Future<DeclaracaoDimob> call(int ano) async {
    final declarante = await _declarante.obter();
    final contatos = await _contatos.listar();
    final imoveis = await _imoveis.listar();
    final pendencias = <PendenciaDimob>[];

    Contato? contato(String? id) =>
        contatos.where((c) => c.id == id).firstOrNull;
    Imovel? imovel(String id) => imoveis.where((i) => i.id == id).firstOrNull;
    bool pj(String id) => contato(id)?.tipoPessoa == TipoPessoa.juridica;

    _validarDeclarante(declarante, pendencias);

    final locacoes = await _locacoes(ano, contato, imovel, pj, pendencias);
    final vendas = await _vendasDoAno(ano, contato, imovel, pendencias);

    return DeclaracaoDimob(
      ano: ano,
      declarante: declarante,
      locacoes: locacoes,
      vendas: vendas,
      pendencias: pendencias,
    );
  }

  Future<List<DimobLocacao>> _locacoes(
    int ano,
    Contato? Function(String?) contato,
    Imovel? Function(String) imovel,
    bool Function(String) pj,
    List<PendenciaDimob> pendencias,
  ) async {
    final contratos = await _contratos.listar();
    final cobrancas = await _cobrancas.listar();
    final despesas = await _despesas.listar();
    final lista = <DimobLocacao>[];

    for (final k in contratos) {
      final pagas = cobrancas
          .where(
            (c) =>
                c.contratoId == k.id &&
                c.status == StatusCobranca.paga &&
                c.dataPagamento?.year == ano,
          )
          .toList();
      final vigente = k.dataInicio.year <= ano && k.dataFim.year >= ano;
      if (pagas.isEmpty &&
          !(vigente && k.status != StatusContrato.rescindido)) {
        continue;
      }

      final aluguel = List<double>.filled(12, 0);
      final encargos = List<double>.filled(12, 0);
      final comissao = List<double>.filled(12, 0);
      final irrf = List<double>.filled(12, 0);
      for (final Cobranca c in pagas) {
        final m = c.dataPagamento!.month - 1;
        for (final l in _repasse(
          cobranca: c,
          contrato: k,
          despesas: despesas,
          locatarioPessoaJuridica: pj(k.locatarioId),
          beneficiarioPessoaJuridica: pj,
        )) {
          aluguel[m] += l.aluguel;
          encargos[m] += l.encargos;
          comissao[m] += l.taxaAdministracao + l.taxaIntermediacao;
          irrf[m] += l.irrf;
        }
      }

      final locatario = contato(k.locatarioId);
      final d = DimobLocacao(
        numero: k.numero,
        dataContrato: k.dataInicio,
        locadores: [
          for (final b in k.beneficiarios)
            _parte(contato(b.contatoId), b.percentual),
        ],
        locatario: _parte(locatario),
        imovel: _imovel(imovel(k.imovelId)),
        aluguel: _arredondar(aluguel),
        encargos: _arredondar(encargos),
        comissao: _arredondar(comissao),
        irrf: _arredondar(irrf),
      );
      lista.add(d);

      final ref = 'Locação ${k.numero}';
      _validarPartes(ref, [
        ...d.locadores.map((p) => ('Locador', p)),
        ('Locatário', d.locatario),
      ], pendencias);
      _validarImovel(ref, d.imovel, pendencias);
      if (d.semRecebimento) {
        pendencias.add(
          PendenciaDimob(
            GravidadePendencia.aviso,
            ref,
            'Sem aluguel recebido em $ano. Confira se há cobranças pagas não registradas.',
          ),
        );
      }
    }
    return lista..sort((a, b) => a.numero.compareTo(b.numero));
  }

  Future<List<DimobVenda>> _vendasDoAno(
    int ano,
    Contato? Function(String?) contato,
    Imovel? Function(String) imovel,
    List<PendenciaDimob> pendencias,
  ) async {
    final vendas = await _vendas.listar();
    final lista = <DimobVenda>[];

    for (final Venda v in vendas) {
      if (v.status == StatusVenda.distratada) continue;
      final parcelas = await _parcelas.daVenda(v.id);
      final pagas = parcelas
          .where(
            (p) =>
                p.status == StatusParcela.paga && p.dataPagamento?.year == ano,
          )
          .toList();
      final recebido = List<double>.filled(12, 0);
      var presumido = false;

      if (v.financiamentoProprio) {
        for (final p in pagas) {
          recebido[p.dataPagamento!.month - 1] += p.valorPago ?? p.valor;
        }
      } else if (v.dataVenda.year == ano) {
        // Sem parcelas no sistema: considera o preço recebido na data da venda.
        recebido[v.dataVenda.month - 1] += v.valorVenda;
        presumido = true;
      }
      if (v.dataVenda.year != ano && pagas.isEmpty) continue;

      final d = DimobVenda(
        numero: v.numero,
        dataContrato: v.dataVenda,
        valorOperacao: v.valorVenda,
        vendedores: [
          for (final p in v.vendedores)
            _parte(contato(p.contatoId), p.percentual),
        ],
        compradores: [for (final id in v.compradores) _parte(contato(id))],
        imovel: _imovel(imovel(v.imovelId)),
        recebido: _arredondar(recebido),
        presumido: presumido,
      );
      lista.add(d);

      final ref = 'Venda ${v.numero}';
      _validarPartes(ref, [
        ...d.vendedores.map((p) => ('Vendedor', p)),
        ...d.compradores.map((p) => ('Comprador', p)),
      ], pendencias);
      _validarImovel(ref, d.imovel, pendencias);
      if (presumido) {
        pendencias.add(
          PendenciaDimob(
            GravidadePendencia.aviso,
            ref,
            'Valor recebido presumido na data da venda (sem parcelas no sistema). Confirme os valores efetivamente recebidos.',
          ),
        );
      }
    }
    return lista..sort((a, b) => a.numero.compareTo(b.numero));
  }

  void _validarDeclarante(DeclaranteDimob d, List<PendenciaDimob> p) {
    if (d.documento.isEmpty) {
      p.add(
        const PendenciaDimob(
          GravidadePendencia.erro,
          'Declarante',
          'Informe o CNPJ ou CPF do declarante.',
        ),
      );
    } else if (!validarCpfCnpj(d.documento)) {
      p.add(
        const PendenciaDimob(
          GravidadePendencia.erro,
          'Declarante',
          'CNPJ/CPF do declarante inválido.',
        ),
      );
    }
    if (d.responsavelCpf.isEmpty) {
      p.add(
        const PendenciaDimob(
          GravidadePendencia.erro,
          'Declarante',
          'Informe o CPF do responsável perante o CNPJ.',
        ),
      );
    } else if (!validarCpf(d.responsavelCpf)) {
      p.add(
        const PendenciaDimob(
          GravidadePendencia.erro,
          'Declarante',
          'CPF do responsável inválido.',
        ),
      );
    }
    if (d.retificadora && d.numeroRecibo.isEmpty) {
      p.add(
        const PendenciaDimob(
          GravidadePendencia.erro,
          'Declarante',
          'Declaração retificadora exige o número do recibo da original.',
        ),
      );
    }
  }

  void _validarPartes(
    String ref,
    List<(String, ParteDimob)> partes,
    List<PendenciaDimob> p,
  ) {
    for (final (papel, parte) in partes) {
      if (parte.documento.isEmpty) {
        p.add(
          PendenciaDimob(
            GravidadePendencia.erro,
            ref,
            '$papel ${parte.nome.isEmpty ? '(não encontrado)' : parte.nome} sem CPF/CNPJ.',
          ),
        );
      } else if (!validarCpfCnpj(parte.documento)) {
        p.add(
          PendenciaDimob(
            GravidadePendencia.erro,
            ref,
            '$papel ${parte.nome} com CPF/CNPJ inválido (${parte.documento}).',
          ),
        );
      }
    }
  }

  void _validarImovel(String ref, ImovelDimob i, List<PendenciaDimob> p) {
    if (!i.enderecoCompleto) {
      p.add(
        PendenciaDimob(
          GravidadePendencia.erro,
          ref,
          'Endereço do imóvel incompleto (logradouro, cidade e UF) em "${i.descricao}".',
        ),
      );
    } else if (i.cep.isEmpty) {
      p.add(
        PendenciaDimob(
          GravidadePendencia.aviso,
          ref,
          'Imóvel "${i.descricao}" sem CEP.',
        ),
      );
    }
  }

  ParteDimob _parte(Contato? c, [double? percentual]) => ParteDimob(
    nome: c?.nome ?? '',
    documento: c?.documento ?? '',
    percentual: percentual,
  );

  ImovelDimob _imovel(Imovel? i) => i == null
      ? const ImovelDimob(descricao: 'Imóvel não encontrado', rural: false)
      : ImovelDimob(
          descricao: '${i.codigo} • ${i.titulo}',
          rural: i.tipo == TipoImovel.sitio || i.tipo == TipoImovel.fazenda,
          logradouro: i.logradouro,
          numero: i.numero,
          complemento: i.complemento,
          bairro: i.bairro,
          cidade: i.cidade,
          uf: i.uf,
          cep: i.cep,
          matricula: i.matricula,
        );

  List<double> _arredondar(List<double> v) => [
    for (final x in v) (x * 100).roundToDouble() / 100,
  ];
}
