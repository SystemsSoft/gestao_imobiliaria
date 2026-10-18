// Teste de integração com o servidor de verdade: grava pelos repositórios do
// app, relê do servidor (sem cache) e confere campo a campo. Só roda com
// um servidor de teste (nunca aponte para o banco de produção):
//
//   flutter test test/integracao --dart-define=API_REAL=http://localhost:8010 \
//     --dart-define=API_USUARIO=... --dart-define=API_SENHA=...
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/api/api_client.dart';
import 'package:marceloimob_gestao/core/api/sessao_api.dart';
import 'package:marceloimob_gestao/core/api/status_conexao.dart';
import 'package:marceloimob_gestao/core/arquivos/arquivo_repository.dart';
import 'package:marceloimob_gestao/core/arquivos/arquivo_repository_api.dart';
import 'package:marceloimob_gestao/core/config/empresa_info.dart';
import 'package:marceloimob_gestao/core/utils/id.dart';
import 'package:marceloimob_gestao/features/auth/data/repositories/auth_repository_api.dart';
import 'package:marceloimob_gestao/features/contratos/data/repositories/modelo_contrato_api_repository.dart';
import 'package:marceloimob_gestao/features/contratos/domain/entities/modelo_contrato.dart';
import 'package:marceloimob_gestao/features/contratos/domain/entities/parametro_modelo.dart';
import 'package:marceloimob_gestao/features/contratos/domain/usecases/modelo_usecases.dart';
import 'package:marceloimob_gestao/features/crm/data/datasources/crm_api_datasource.dart';
import 'package:marceloimob_gestao/features/crm/data/models/crm_json.dart';
import 'package:marceloimob_gestao/features/crm/data/repositories/crm_api_repositories.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/contato.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/enums.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/evento.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/imovel.dart';
import 'package:marceloimob_gestao/features/equipe/data/models/equipe_json.dart';
import 'package:marceloimob_gestao/features/equipe/data/repositories/equipe_api_repositories.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/chat.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/comissao_equipe.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/equipe_enums.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/fila.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/permissoes.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/usuario_sistema.dart';
import 'package:marceloimob_gestao/features/financeiro/data/models/financeiro_json.dart';
import 'package:marceloimob_gestao/features/financeiro/data/repositories/financeiro_api_repositories.dart';
import 'package:marceloimob_gestao/features/financeiro/domain/entities/conta_bancaria.dart';
import 'package:marceloimob_gestao/features/financeiro/domain/entities/financeiro_enums.dart';
import 'package:marceloimob_gestao/features/financeiro/domain/entities/indice_mensal.dart';
import 'package:marceloimob_gestao/features/financeiro/domain/entities/lancamento.dart';
import 'package:marceloimob_gestao/features/financeiro/domain/entities/linha_extrato.dart';
import 'package:marceloimob_gestao/features/financeiro/domain/usecases/boleto_usecases.dart';
import 'package:marceloimob_gestao/features/financeiro/domain/usecases/financeiro_usecases.dart';
import 'package:marceloimob_gestao/features/financeiro/domain/usecases/lancamento_usecases.dart';
import 'package:marceloimob_gestao/features/fiscal/data/repositories/declarante_api_repository.dart';
import 'package:marceloimob_gestao/features/fiscal/domain/entities/declarante_dimob.dart';
import 'package:marceloimob_gestao/features/locacao/data/datasources/locacao_api_datasource.dart';
import 'package:marceloimob_gestao/features/locacao/data/models/locacao_json.dart';
import 'package:marceloimob_gestao/features/locacao/data/repositories/locacao_api_repositories.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/cobranca.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/contrato_locacao.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/despesa.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/locacao_enums.dart';
import 'package:marceloimob_gestao/features/locacao/domain/repositories/repasse_repository.dart';
import 'package:marceloimob_gestao/features/locacao/domain/usecases/contrato_usecases.dart';
import 'package:marceloimob_gestao/features/manutencao/data/models/manutencao_json.dart';
import 'package:marceloimob_gestao/features/manutencao/data/repositories/manutencao_api_repository.dart';
import 'package:marceloimob_gestao/features/manutencao/domain/entities/manutencao.dart';
import 'package:marceloimob_gestao/features/personalizacao/data/repositories/empresa_repositories.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/data/repositories/portal_repositories.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/domain/entities/portal.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/domain/usecases/portal_usecases.dart';
import 'package:marceloimob_gestao/features/temporada/data/models/reserva_json.dart';
import 'package:marceloimob_gestao/features/temporada/data/repositories/reserva_api_repository.dart';
import 'package:marceloimob_gestao/features/temporada/domain/entities/reserva.dart';
import 'package:marceloimob_gestao/features/temporada/domain/entities/reserva_enums.dart';
import 'package:marceloimob_gestao/features/temporada/domain/usecases/reserva_usecases.dart';
import 'package:marceloimob_gestao/features/vendas/data/models/vendas_json.dart';
import 'package:marceloimob_gestao/features/vendas/data/repositories/vendas_api_repositories.dart';
import 'package:marceloimob_gestao/features/vendas/domain/entities/venda.dart';
import 'package:marceloimob_gestao/features/vendas/domain/entities/venda_enums.dart';
import 'package:marceloimob_gestao/features/vendas/domain/usecases/parcela_usecases.dart';
import 'package:marceloimob_gestao/features/vendas/domain/usecases/venda_usecases.dart';

const _url = String.fromEnvironment('API_REAL');
const _usuario = String.fromEnvironment('API_USUARIO');
const _senha = String.fromEnvironment('API_SENHA');

final _sessao = SessaoApi();
ApiClient _api() => ApiClient(_url, sessao: _sessao);

/// Normaliza para comparar (inteiro x decimal, ordem das chaves).
Object? _norm(Object? v) => switch (v) {
  num n => n.toDouble(),
  Map m => {
    for (final k in (m.keys.map((e) => '$e').toList()..sort())) k: _norm(m[k]),
  },
  List l => l.map(_norm).toList(),
  _ => v,
};

/// Confere que o que voltou do servidor é igual ao enviado, menos os campos
/// que o servidor gera.
void _igual(
  Map<String, Object?> enviado,
  Map<String, Object?> lido, {
  Set<String> ignorar = const {},
}) {
  Map<String, Object?> limpo(Map<String, Object?> m) => {
    for (final e in m.entries)
      if (!ignorar.contains(e.key)) e.key: e.value,
  };
  expect(jsonEncode(_norm(limpo(lido))), jsonEncode(_norm(limpo(enviado))));
}

/// CPF válido aleatório (o login do portal é único).
String _cpf() {
  final d = [
    for (var i = 0; i < 9; i++) (DateTime.now().microsecond + i * 7) % 10,
  ];
  for (final n in [10, 11]) {
    var soma = 0;
    for (var i = 0; i < n - 1; i++) {
      soma += d[i] * (n - i);
    }
    final r = soma * 10 % 11;
    d.add(r == 10 ? 0 : r);
  }
  return d.join();
}

final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
  ),
);

void main() {
  if (_url.isEmpty) {
    test('integração com servidor real', () {}, skip: 'defina API_REAL');
    return;
  }

  // Cadastros usados pelos outros módulos.
  late Contato dono, cliente;
  late Imovel imovel;

  setUpAll(() async {
    await AuthRepositoryApi(
      _api(),
      _sessao,
      StatusConexao(),
    ).entrar(usuario: _usuario, senha: _senha);
  });
  tearDownAll(() => AuthRepositoryApi(_api(), _sessao, StatusConexao()).sair());

  group('Cadastros e CRM', () {
    test('contatos, imóvel com mídias enviadas e evento', () async {
      final ds = CrmApiDataSource(_api(), StatusConexao());
      dono = Contato(
        id: gerarId(),
        nome: 'Roberto Proprietário',
        criadoEm: DateTime(2026),
        tipoPessoa: TipoPessoa.fisica,
        papeis: {PapelContato.proprietario},
        documento: '529.982.247-25',
        rg: '12.345.678-9',
        dataNascimento: DateTime(1970, 3, 4),
        profissao: 'Engenheiro',
        telefone: '(21) 2222-3333',
        celular: '(21) 99999-0000',
        email: 'roberto@exemplo.com',
        cep: '24220-000',
        logradouro: 'Rua Moreira César',
        numero: '100',
        bairro: 'Icaraí',
        cidade: 'Niterói',
        uf: 'RJ',
        etapa: EtapaFunil.fechado,
        rendaMensal: 15000.5,
        banco: 'Itaú',
        agencia: '0001',
        conta: '12345-6',
        pix: 'roberto@exemplo.com',
      );
      cliente = Contato(
        id: gerarId(),
        nome: 'Ana Compradora',
        criadoEm: DateTime(2026),
        papeis: {PapelContato.comprador, PapelContato.locatario},
        etapa: EtapaFunil.visita,
        perfil: const PerfilInteresse(
          finalidade: Finalidade.venda,
          tipos: {TipoImovel.apartamento, TipoImovel.casa},
          cidade: 'Niterói',
          bairros: 'Icaraí',
          valorMin: 300000,
          valorMax: 900000,
          quartosMin: 2,
          vagasMin: 1,
          comodidades: {'Piscina'},
        ),
      );
      final contatos = ContatoApiRepository(ds);
      await contatos.salvar(dono);
      await contatos.salvar(cliente);

      final arquivos = ArquivoRepositoryApi(_api());
      final foto = await arquivos.enviar(
        bytes: _png,
        nome: 'fachada.png',
        categoria: CategoriaArquivo.foto,
      );
      imovel = Imovel(
        id: gerarId(),
        codigo: '',
        titulo: 'Apartamento 3 quartos em Icaraí',
        finalidades: {Finalidade.venda, Finalidade.locacao},
        tipo: TipoImovel.apartamento,
        proprietarioId: dono.id,
        cep: '24220-000',
        logradouro: 'Rua Moreira César',
        numero: '200',
        complemento: 'Apto 801',
        bairro: 'Icaraí',
        cidade: 'Niterói',
        uf: 'RJ',
        condominioNome: 'Edifício Mar Azul',
        valorVenda: 850000,
        valorLocacao: 4500,
        valorCondominio: 1200.5,
        valorIptu: 300,
        comissao: 6,
        aceitaFinanciamento: true,
        quartos: 3,
        suites: 1,
        banheiros: 2,
        vagas: 1,
        andar: 8,
        anoConstrucao: 2010,
        areaUtil: 110.5,
        mobiliado: Mobiliado.sim,
        comodidades: {'Piscina', 'Academia'},
        personalizadas: const [
          CaracteristicaPersonalizada(nome: 'Vista', valor: 'Mar'),
        ],
        descricao: 'Vista para o mar.',
        observacoesInternas: 'Chaves na portaria.',
        captador: 'Marcelo',
        dataCaptacao: DateTime(2026, 9, 1),
        matricula: '12345',
        inscricaoMunicipal: '987654',
        exclusividade: true,
        anexos: [
          Anexo(tipo: AnexoTipo.foto, titulo: 'Fachada', url: foto.referencia),
          const Anexo(
            tipo: AnexoTipo.link,
            titulo: 'Tour 360',
            url: 'https://exemplo.com/tour',
          ),
        ],
      );
      final salvo = await ImovelApiRepository(ds).salvar(imovel);
      expect(salvo.codigo, matches(RegExp(r'^IM-\d{4}$')));
      imovel = salvo;

      final evento = Evento(
        id: gerarId(),
        titulo: 'Visita ao apartamento',
        criadoEm: DateTime(2026),
        tipo: TipoEvento.visita,
        descricao: 'Levar a chave',
        dataHora: DateTime(2026, 10, 20, 9, 30),
        prioridade: Prioridade.alta,
        contatoId: cliente.id,
        imovelId: imovel.id,
      );
      await EventoApiRepository(ds).salvar(evento);

      // Relê tudo do servidor.
      final novo = CrmApiDataSource(_api(), StatusConexao());
      const gerados = {'criadoEm', 'atualizadoEm', 'codigo'};
      final lidos = {for (final c in await novo.contatos.all()) c.id: c};
      _igual(
        contatoParaJson(dono),
        contatoParaJson(lidos[dono.id]!),
        ignorar: gerados,
      );
      _igual(
        contatoParaJson(cliente),
        contatoParaJson(lidos[cliente.id]!),
        ignorar: gerados,
      );
      final imovelLido = (await novo.imoveis.all()).firstWhere(
        (i) => i.id == imovel.id,
      );
      _igual(
        imovelParaJson(imovel),
        imovelParaJson(imovelLido),
        ignorar: gerados,
      );
      expect(
        await arquivos.endereco(imovelLido.primeiraFoto!),
        isNotNull,
        reason: 'foto enviada abre pelo link assinado',
      );
      _igual(
        eventoParaJson(evento),
        eventoParaJson(
          (await novo.eventos.all()).firstWhere((e) => e.id == evento.id),
        ),
        ignorar: gerados,
      );
    });
  });

  group('Administração de Locação', () {
    late ContratoLocacao contrato;

    test('contrato, despesa, cobrança e repasse', () async {
      final ds = LocacaoApiDataSource(_api(), StatusConexao());
      final contratos = ContratoLocacaoApiRepository(ds);
      contrato = await SalvarContrato(contratos)(
        ContratoLocacao(
          id: gerarId(),
          numero: '',
          imovelId: imovel.id,
          locatarioId: cliente.id,
          beneficiarios: [Beneficiario(contatoId: dono.id, percentual: 100)],
          dataInicio: DateTime(2026, 1, 1),
          valorAluguel: 4500,
          finalidade: FinalidadeLocacao.residencial,
          garantia: GarantiaLocacao.caucao,
          valorGarantia: 13500,
          prazoMeses: 30,
          diaVencimento: 10,
          taxaAdministracao: 8.5,
          taxaIntermediacao: 100,
          indiceReajuste: IndiceReajuste.ipca,
          multaAtraso: 10,
          jurosMes: 1,
          descontoPontualidade: 5,
          clausulasAdicionais: 'Proibido animais de grande porte.',
          observacoes: 'Pago via PIX.',
        ),
      );
      expect(contrato.numero, matches(RegExp(r'^LOC-\d{4}$')));

      final despesa = Despesa(
        id: gerarId(),
        contratoId: contrato.id,
        descricao: 'IPTU',
        valor: 300,
        responsavel: ResponsavelDespesa.proprietario,
        competenciaInicio: DateTime(2026, 1),
        competenciaFim: DateTime(2026, 12),
        dedutivelIR: true,
      );
      await DespesaApiRepository(ds).salvar(despesa);
      final cobranca = Cobranca(
        id: gerarId(),
        contratoId: contrato.id,
        competencia: DateTime(2026, 2),
        vencimento: DateTime(2026, 2, 10),
        itens: const [
          ItemCobranca(
            descricao: 'Aluguel 02/2026',
            valor: 4500,
            tipo: TipoItemCobranca.aluguel,
          ),
          ItemCobranca(
            descricao: 'IPTU',
            valor: 300,
            tipo: TipoItemCobranca.despesa,
          ),
        ],
        status: StatusCobranca.paga,
        dataPagamento: DateTime(2026, 2, 15),
        valorPago: 5330.5,
        multa: 480,
        juros: 50.5,
      );
      await CobrancaApiRepository(ds).salvar(cobranca);
      await RepasseApiRepository(
        ds,
      ).marcar(cobranca.id, dono.id, DateTime(2026, 2, 20));

      final novo = LocacaoApiDataSource(_api(), StatusConexao());
      const gerados = {'criadoEm', 'atualizadoEm', 'numero'};
      _igual(
        contratoParaJson(contrato),
        contratoParaJson(
          (await novo.contratos.all()).firstWhere((c) => c.id == contrato.id),
        ),
        ignorar: gerados,
      );
      _igual(
        despesaParaJson(despesa),
        despesaParaJson(
          (await novo.despesas.all()).firstWhere((d) => d.id == despesa.id),
        ),
        ignorar: gerados,
      );
      _igual(
        cobrancaParaJson(cobranca),
        cobrancaParaJson(
          (await novo.cobrancas.all()).firstWhere((c) => c.id == cobranca.id),
        ),
        ignorar: gerados,
      );
      final repasses = await RepasseApiRepository(novo).realizados();
      expect(
        repasses[chaveRepasse(cobranca.id, dono.id)],
        DateTime(2026, 2, 20),
      );
    });

    test('manutenção com diário', () async {
      final repo = ManutencaoApiRepository(_api(), StatusConexao());
      final m = Manutencao(
        id: gerarId(),
        contexto: ContextoManutencao.locacao,
        imovelId: imovel.id,
        tipo: TipoManutencao.outros,
        tipoOutro: 'Hidráulica',
        descricao: 'Vazamento no banheiro',
        criadaEm: DateTime(2026),
        status: StatusManutencao.emAndamento,
        dataPrevista: DateTime(2026, 10, 30),
        diario: [
          RegistroDiario(
            id: gerarId(),
            data: DateTime(2026, 10, 5),
            profissional: 'Carlos Bombeiro',
            servico: 'Troca do sifão',
            material: 'Sifão e veda-rosca',
            valorMaterial: 80.5,
            valorMaoDeObra: 150,
            valorTaxa: 30,
          ),
        ],
      );
      await repo.observar().first;
      await repo.salvar(m);
      final novo = ManutencaoApiRepository(_api(), StatusConexao());
      await novo.observar().first;
      _igual(
        manutencaoParaJson(m),
        manutencaoParaJson(novo.porId(m.id)!),
        ignorar: {'criadaEm', 'atualizadaEm'},
      );
    });
  });

  group('Administração de Vendas', () {
    test('venda financiada, parcelas, pagamento e comissão', () async {
      final ds = VendasApiDataSource(_api(), StatusConexao());
      final vendas = VendaApiRepository(ds);
      final parcelas = ParcelaApiRepository(ds);
      var venda = await SalvarVenda(vendas, parcelas)(
        Venda(
          id: gerarId(),
          numero: '',
          imovelId: imovel.id,
          compradores: [cliente.id],
          vendedores: [Participacao(contatoId: dono.id, percentual: 100)],
          dataVenda: DateTime(2026, 10, 1),
          valorVenda: 850000,
          valorEntrada: 170000,
          vencimentoEntrada: DateTime(2026, 10, 5),
          formaPagamento: FormaPagamento.financiamentoProprio,
          plano: PlanoFinanciamento(
            numeroParcelas: 12,
            taxaJurosMes: 1,
            sistema: SistemaAmortizacao.price,
            primeiroVencimento: DateTime(2026, 11, 10),
          ),
          corretores: [
            const Participacao(percentual: 60),
            Participacao(contatoId: dono.id, percentual: 40),
          ],
        ),
      );
      expect(venda.numero, matches(RegExp(r'^VEN-\d{4}$')));
      final tabela = await parcelas.daVenda(venda.id);
      expect(tabela, hasLength(13));

      final entrada = tabela.firstWhere((p) => p.tipo == TipoParcela.entrada);
      await RegistrarPagamentoParcela(
        parcelas,
        vendas,
        const CalcularEncargosParcela(),
      )(entrada, DateTime(2026, 10, 5));
      venda = (await vendas.obter(venda.id))!;
      await MarcarComissaoPaga(vendas)(venda, 0, DateTime(2026, 10, 6));
      venda = (await vendas.obter(venda.id))!;

      final novo = VendasApiDataSource(_api(), StatusConexao());
      const gerados = {'criadoEm', 'atualizadoEm', 'numero'};
      _igual(
        vendaParaJson(venda),
        vendaParaJson(
          (await novo.vendas.all()).firstWhere((v) => v.id == venda.id),
        ),
        ignorar: gerados,
      );
      final relidas = {
        for (final p in await novo.parcelas.all())
          if (p.vendaId == venda.id) p.id: p,
      };
      expect(relidas, hasLength(13));
      final paga = (await parcelas.daVenda(
        venda.id,
      )).firstWhere((p) => p.id == entrada.id);
      expect(paga.status, StatusParcela.paga);
      for (final p in await parcelas.daVenda(venda.id)) {
        _igual(
          parcelaParaJson(p),
          parcelaParaJson(relidas[p.id]!),
          ignorar: gerados,
        );
      }
    });
  });

  group('Locação por Temporada', () {
    test('reserva e conflito de datas recusado pelo servidor', () async {
      final repo = ReservaApiRepository(_api(), StatusConexao());
      final salvar = SalvarReserva(repo, ConsultarDisponibilidade(repo));
      final r = await salvar(
        Reserva(
          id: gerarId(),
          imovelId: imovel.id,
          hospedeId: cliente.id,
          checkIn: DateTime(2026, 12, 20),
          checkOut: DateTime(2026, 12, 27),
          hospedes: 3,
          valorDiaria: 450,
          taxaLimpeza: 150,
          desconto: 50,
          valorPago: 1000,
          origem: OrigemReserva.airbnb,
          observacoes: 'Chegada à noite',
        ),
      );
      expect(r.numero, matches(RegExp(r'^RES-\d{4}$')));
      final outro = ReservaApiRepository(_api(), StatusConexao());
      _igual(
        reservaParaJson(r),
        reservaParaJson((await outro.listar()).firstWhere((x) => x.id == r.id)),
        ignorar: {'criadoEm', 'atualizadoEm', 'numero'},
      );
      // Outro usuário (sem a reserva no cache) tenta o mesmo período.
      await expectLater(
        ReservaApiRepository(_api(), StatusConexao()).salvar(
          Reserva(
            id: gerarId(),
            imovelId: imovel.id,
            hospedeId: dono.id,
            checkIn: DateTime(2026, 12, 22),
            checkOut: DateTime(2026, 12, 24),
            valorDiaria: 450,
          ),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Financeiro', () {
    test('conta, lançamentos, baixa, extrato, boleto e índices', () async {
      final ds = FinanceiroApiDataSource(_api(), StatusConexao());
      final conta = ContaBancaria(
        id: gerarId(),
        nome: 'Itaú Empresa',
        banco: '341',
        agencia: '0001',
        conta: '12345-6',
        saldoInicial: 1000.5,
        convenio: '123456',
        carteira: '109',
      );
      final contas = ContaBancariaApiRepository(ds);
      await contas.salvar(conta);
      final lancamentos = LancamentoApiRepository(ds);
      final descricao = 'Comissão de venda ${gerarId().substring(0, 8)}';
      final base = Lancamento(
        id: gerarId(),
        tipo: TipoLancamento.receber,
        descricao: descricao,
        categoria: 'Comissão de venda',
        valor: 5000,
        vencimento: DateTime(2026, 10, 10),
        contatoId: cliente.id,
        documento: 'NF 123',
        observacoes: 'Parcelado',
        multaPercentual: 2,
        jurosMesPercentual: 1,
        indice: IndiceMonetario.igpm,
      );
      await SalvarLancamento(lancamentos)(base, repetir: 3);
      final grupo = (await lancamentos.listar())
          .where((l) => l.descricao == descricao)
          .toList();
      expect(grupo, hasLength(3));

      final primeiro = grupo.firstWhere((l) => l.vencimento.month == 10);
      final baixado =
          await BaixarLancamento(
            lancamentos,
            IndiceApiRepository(ds),
            const CalcularEncargosLancamento(),
          )(
            primeiro,
            DateTime(2026, 10, 10),
            meio: MeioPagamento.pix,
            contaId: conta.id,
          );
      final extrato = ExtratoApiRepository(ds);
      final linha = LinhaExtrato(
        id: gerarId(),
        contaId: conta.id,
        data: DateTime(2026, 10, 10),
        descricao: 'PIX recebido',
        valor: baixado.valorBaixa!,
        documento: 'E123',
      );
      await extrato.salvar(linha);
      await ConciliarLinha(extrato)(linha, baixado);

      final segundo = grupo.firstWhere((l) => l.vencimento.month == 11);
      final boletos = BoletoApiRepository(ds);
      final boleto = await EmitirBoleto(boletos, contas)(segundo, conta.id);
      expect(boleto.nossoNumero, isNotEmpty);

      final indices = IndiceApiRepository(ds);
      await SalvarIndice(indices)(
        const IndiceMensal(
          indice: IndiceMonetario.ipca,
          ano: 2026,
          mes: 9,
          percentual: 0.44,
        ),
      );
      final cfg = ConfiguracaoFinanceiraApiRepository(ds);
      await cfg.salvar(
        const ConfiguracaoFinanceira(
          multaPercentual: 2,
          jurosMesPercentual: 1,
          indicePadrao: IndiceMonetario.ipca,
        ),
      );

      final novo = FinanceiroApiDataSource(_api(), StatusConexao());
      const gerados = {'criadoEm', 'atualizadoEm'};
      _igual(
        contaBancariaParaJson(conta),
        contaBancariaParaJson(
          (await novo.contas.all()).firstWhere((c) => c.id == conta.id),
        ),
        ignorar: gerados,
      );
      final lidos = {for (final l in await novo.lancamentos.all()) l.id: l};
      for (final l in await lancamentos.listar()) {
        _igual(
          lancamentoParaJson(l),
          lancamentoParaJson(lidos[l.id]!),
          ignorar: gerados,
        );
      }
      expect(lidos[primeiro.id]!.status, StatusLancamento.baixado);
      final linhaLida = (await novo.extrato.all()).firstWhere(
        (x) => x.id == linha.id,
      );
      expect(linhaLida.lancamentoId, primeiro.id);
      _igual(
        boletoParaJson(boleto),
        boletoParaJson(
          (await novo.boletos.all()).firstWhere((b) => b.id == boleto.id),
        ),
        ignorar: gerados,
      );
      expect(
        (await novo.indices.all()).map((i) => i.id),
        contains('ipca-2026-9'),
      );
      expect(
        (await ConfiguracaoFinanceiraApiRepository(novo).obter()).indicePadrao,
        IndiceMonetario.ipca,
      );
    });
  });

  group('Fiscal, Contratos e Personalização', () {
    test('declarante da DIMOB', () async {
      final repo = DeclaranteApiRepository(_api(), StatusConexao());
      await repo.salvar(
        DeclaranteDimob(
          documento: '11.222.333/0001-81',
          nome: 'Marcelo Bonifácio Imóveis',
          responsavelCpf: '529.982.247-25',
          retificadora: true,
          numeroRecibo: '1234567890',
        ),
      );
      final lido = await DeclaranteApiRepository(
        _api(),
        StatusConexao(),
      ).obter();
      expect(
        (lido.documento, lido.retificadora, lido.numeroRecibo),
        ('11.222.333/0001-81', true, '1234567890'),
      );
    });

    test('modelos de contrato', () async {
      final repo = ModeloContratoApiRepository(_api(), StatusConexao());
      final padrao = await repo.listar();
      expect(padrao.map((m) => m.tipo), containsAll([TipoModelo.locacao]));
      await SalvarModelo(repo)(
        ModeloContrato(
          id: '',
          nome: 'Autorização de venda',
          tipo: TipoModelo.autorizacao,
          texto: 'Prazo de {{prazo}} dias.',
          parametros: const [
            ParametroModelo(
              chave: 'prazo',
              rotulo: 'Prazo (dias)',
              tipo: TipoParametro.numero,
              valorPadrao: '90',
            ),
          ],
        ),
      );
      final lidos = await ModeloContratoApiRepository(
        _api(),
        StatusConexao(),
      ).listar();
      final m = lidos.firstWhere((m) => m.tipo == TipoModelo.autorizacao);
      expect(m.parametros.single.valorPadrao, '90');
      expect(lidos.length, padrao.length + 1);
    });

    test('dados da imobiliária e logotipo', () async {
      final repo = EmpresaApiRepository(_api());
      const dados = DadosEmpresa(
        nome: 'Marcelo Bonifácio Imóveis',
        atividade: 'Corretor de Imóveis',
        creci: 'CRECI 065655 RJ',
        documento: '11.222.333/0001-81',
        endereco: 'Rua Moreira César, 100 - Icaraí, Niterói/RJ',
        telefone: '(21) 99999-0000',
        email: 'contato@exemplo.com',
        site: 'exemplo.com',
        chavePix: '11222333000181',
      );
      await repo.salvar(dados);
      await repo.salvarLogo(_png);
      final lido = await EmpresaApiRepository(_api()).obter();
      expect(
        (lido.nome, lido.documento, lido.chavePix),
        (dados.nome, dados.documento, dados.chavePix),
      );
      expect(await repo.obterLogo(), _png);
      await repo.removerLogo();
      expect(await repo.obterLogo(), isNull);
    });
  });

  group('Portal do inquilino', () {
    test('acesso, documento publicado e aviso', () async {
      final inquilino = Contato(
        id: gerarId(),
        nome: 'Inquilina do Portal',
        criadoEm: DateTime(2026),
        documento: _cpf(),
        papeis: {PapelContato.locatario},
      );
      await ContatoApiRepository(
        CrmApiDataSource(_api(), StatusConexao()),
      ).salvar(inquilino);
      final contrato =
          await SalvarContrato(
            ContratoLocacaoApiRepository(
              LocacaoApiDataSource(_api(), StatusConexao()),
            ),
          )(
            ContratoLocacao(
              id: gerarId(),
              numero: '',
              imovelId: imovel.id,
              locatarioId: inquilino.id,
              beneficiarios: [
                Beneficiario(contatoId: dono.id, percentual: 100),
              ],
              dataInicio: DateTime(2026, 1, 1),
              valorAluguel: 2500,
            ),
          );
      final portal = PortalInquilinoApiRepository(_api());
      final senha = await portal.liberarAcesso(inquilino.id);
      expect(senha.login, inquilino.documento);
      expect(senha.senha, hasLength(10));
      final acesso = (await portal.acessos()).firstWhere(
        (a) => a.contatoId == inquilino.id,
      );
      expect((acesso.ativo, acesso.trocarSenha), (true, true));

      await PublicarDocumentoContrato(portal, ArquivoRepositoryApi(_api()))(
        contratoId: contrato.id,
        tipo: TipoArquivoContrato.vistoria,
        titulo: 'Vistoria de entrada',
        arquivo: ArquivoEscolhido(
          nome: 'vistoria.png',
          tamanho: _png.length,
          ler: () async => _png,
        ),
      );
      final docs = await portal.arquivos(contratoId: contrato.id);
      expect(docs.single.titulo, 'Vistoria de entrada');
      expect(docs.single.referencia, startsWith('arquivo:'));
      await portal.salvarArquivo(docs.single.comVisibilidade(false));
      expect(
        (await portal.arquivos(
          contratoId: contrato.id,
        )).single.visivelInquilino,
        isFalse,
      );

      await EnviarComunicado(portal)(
        contratoId: contrato.id,
        titulo: 'Bem-vinda',
        mensagem: 'Seu portal está pronto.',
      );
      final avisos = await portal.comunicados(contratoId: contrato.id);
      expect(
        avisos.map((c) => c.titulo),
        containsAll(['Bem-vinda', 'Novo documento disponível']),
      );
      await portal.revogarAcesso(inquilino.id);
      expect(
        (await portal.acessos()).where((a) => a.contatoId == inquilino.id),
        isEmpty,
      );
    });
  });

  group('Equipe e Segurança', () {
    test('usuário, fila, chat, atendimento, comissões e permissões', () async {
      final ds = EquipeApiDataSource(_api(), _sessao, StatusConexao());
      final corretor = UsuarioSistema(
        id: gerarId(),
        nome: 'Carla Corretora',
        login: 'carla${DateTime.now().millisecondsSinceEpoch % 100000}',
        email: 'carla@exemplo.com',
        perfil: PerfilAcesso.corretor,
        permissoes: Permissoes.perfil(PerfilAcesso.corretor),
        criadoEm: DateTime(2026),
        telefone: '(21) 98888-7777',
        creci: '123456',
        atendeNaFila: true,
      );
      await UsuarioApiRepository(ds).salvar(corretor, senha: 'senha-da-carla');

      await FilaApiRepository(ds).salvar([
        ItemFila(
          usuarioId: corretor.id,
          status: StatusFila.disponivel,
          desde: DateTime(2026, 10, 16, 9),
        ),
      ]);
      final atendimento = Atendimento(
        id: gerarId(),
        corretorId: corretor.id,
        clienteNome: 'Ana Compradora',
        origem: OrigemAtendimento.whatsapp,
        iniciadoEm: DateTime(2026, 10, 16, 9, 5),
        contatoId: cliente.id,
        observacao: 'Quer 3 quartos',
      );
      await AtendimentoApiRepository(ds).salvar(atendimento);
      final comissoes = ComissaoEquipeApiRepository(ds);
      await comissoes.salvarRegra(
        RegraComissao(
          usuarioId: corretor.id,
          percentualVenda: 40,
          percentualLocacao: 30,
          percentualCaptacao: 10,
          metaMensal: 20000,
        ),
      );
      final comissao = LancamentoComissao(
        id: gerarId(),
        usuarioId: corretor.id,
        tipo: TipoComissao.venda,
        competencia: DateTime(2026, 10),
        valor: 20400,
        referencia: 'VEN-0001',
        baseValor: 51000,
        percentual: 40,
        observacao: 'Apto Icaraí',
      );
      await comissoes.salvarLancamento(comissao);
      final msg = Mensagem(
        id: gerarId(),
        conversaId: conversaGeral,
        remetenteId: _sessao.usuarioId!,
        texto: 'Bom dia, equipe!',
        enviadaEm: DateTime(2026, 10, 16, 9),
      );
      await MensagemApiRepository(ds).salvar(msg);

      final novo = EquipeApiDataSource(_api(), _sessao, StatusConexao());
      final u = (await novo.usuarios.all()).firstWhere(
        (x) => x.id == corretor.id,
      );
      _igual(
        usuarioParaJson(corretor),
        usuarioParaJson(u),
        ignorar: {'criadoEm', 'atualizadoEm'},
      );
      expect(
        (await novo.fila.all()).map((i) => i.usuarioId),
        contains(corretor.id),
      );
      _igual(
        atendimentoParaJson(atendimento),
        atendimentoParaJson(
          (await novo.atendimentos.all()).firstWhere(
            (a) => a.id == atendimento.id,
          ),
        ),
      );
      _igual(
        comissaoParaJson(comissao),
        comissaoParaJson(
          (await novo.comissoes.all()).firstWhere((c) => c.id == comissao.id),
        ),
        ignorar: {'criadoEm', 'atualizadoEm'},
      );
      expect(
        (await novo.mensagens.all()).map((m) => m.texto),
        contains('Bom dia, equipe!'),
      );

      // Corretor entra: vê CRM, não vê o Financeiro (lista vazia, sem erro).
      final sessaoCarla = SessaoApi();
      final apiCarla = ApiClient(_url, sessao: sessaoCarla);
      await AuthRepositoryApi(
        apiCarla,
        sessaoCarla,
        StatusConexao(),
      ).entrar(usuario: corretor.login, senha: 'senha-da-carla');
      final crm = CrmApiDataSource(apiCarla, StatusConexao());
      expect(await crm.imoveis.all(), isNotEmpty);
      final status = StatusConexao();
      final fin = FinanceiroApiDataSource(apiCarla, status);
      expect(await fin.lancamentos.all(), isEmpty);
      expect(status.erro, isNull);
      await expectLater(
        apiCarla.get('financeiro/lancamentos'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
      final sessoes = await SessaoApiRepository(novo).listar();
      expect(sessoes.map((s) => s.usuarioId), contains(corretor.id));
      await AuthRepositoryApi(apiCarla, sessaoCarla, StatusConexao()).sair();
      expect(sessaoCarla.logado, isFalse);
    });
  });
}
