import '../../../../core/config/empresa_info.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/extenso.dart';
import '../../../../core/utils/formatters.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../entities/contrato_locacao.dart';
import '../entities/documentos.dart';
import '../entities/modelo_contrato.dart';
import '../repositories/modelo_contrato_repository.dart';

class ObservarModelos {
  const ObservarModelos(this._repo);
  final ModeloContratoRepository _repo;

  Stream<List<ModeloContrato>> call() => _repo.observar();
}

class SalvarModelo {
  const SalvarModelo(this._repo);
  final ModeloContratoRepository _repo;

  Future<void> call(ModeloContrato m) {
    if (m.nome.trim().isEmpty) throw const DomainException('Informe o nome.');
    if (m.texto.trim().isEmpty) throw const DomainException('Informe o texto.');
    final invalidos = RegExp(r'\{\{(\w+)\}\}')
        .allMatches(m.texto)
        .map((x) => x.group(1)!)
        .where((c) => !camposModeloContrato.containsKey(c))
        .toSet();
    if (invalidos.isNotEmpty) {
      throw DomainException('Campos desconhecidos: ${invalidos.join(', ')}.');
    }
    return _repo.salvar(m);
  }
}

class RemoverModelo {
  const RemoverModelo(this._repo);
  final ModeloContratoRepository _repo;

  Future<void> call(String id) async {
    if ((await _repo.listar()).length <= 1) {
      throw const DomainException('Mantenha ao menos um modelo de contrato.');
    }
    await _repo.remover(id);
  }
}

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', //
  'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

/// Substitui os campos {{campo}} do modelo pelos dados do contrato.
class PreencherModeloContrato {
  const PreencherModeloContrato();

  ContratoDocumento call({
    required ModeloContrato modelo,
    required ContratoLocacao contrato,
    required Contato? Function(String id) contato,
    required Imovel? imovel,
    DateTime? data,
  }) {
    final hoje = data ?? DateTime.now();
    final locadores = [
      for (final b in contrato.beneficiarios) ?contato(b.contatoId),
    ];
    final locatario = contato(contrato.locatarioId);
    final fiador = contrato.fiadorId == null
        ? null
        : contato(contrato.fiadorId!);
    final cidade = imovel?.cidade ?? '';

    final valores = <String, String>{
      'numero_contrato': contrato.numero,
      'locador_nome': locadores.map((c) => c.nome).join(', '),
      'locador_qualificacao': locadores.map(_qualificacao).join('; '),
      'locatario_nome': locatario?.nome ?? '',
      'locatario_qualificacao': locatario == null
          ? ''
          : _qualificacao(locatario),
      'fiador_qualificacao': fiador == null ? 'Não há.' : _qualificacao(fiador),
      'imovel_tipo': imovel?.tipo.label ?? '',
      'imovel_endereco': imovel == null ? '' : _enderecoImovel(imovel),
      'finalidade': contrato.finalidade.label.toLowerCase(),
      'valor_aluguel': moneyToText(contrato.valorAluguel),
      'valor_aluguel_extenso': valorPorExtenso(contrato.valorAluguel),
      'dia_vencimento': '${contrato.diaVencimento}',
      'data_inicio': formatDate(contrato.dataInicio),
      'data_fim': formatDate(contrato.dataFim),
      'prazo_meses': '${contrato.prazoMeses}',
      'indice_reajuste': contrato.indiceReajuste.label,
      'garantia': contrato.garantia.label,
      'valor_garantia': contrato.valorGarantia == null
          ? ''
          : 'no valor de ${formatMoney(contrato.valorGarantia)} '
                '(${valorPorExtenso(contrato.valorGarantia!)})',
      'multa_atraso': _num(contrato.multaAtraso),
      'juros_mes': _num(contrato.jurosMes),
      'taxa_administracao': _num(contrato.taxaAdministracao),
      'clausulas_adicionais': contrato.clausulasAdicionais.isEmpty
          ? 'Não há.'
          : contrato.clausulasAdicionais,
      'empresa_nome': EmpresaInfo.nome,
      'empresa_creci': EmpresaInfo.creci,
      'cidade_data':
          '${cidade.isEmpty ? '' : '$cidade, '}'
          '${hoje.day} de ${_meses[hoje.month - 1]} de ${hoje.year}.',
    };

    final texto = modelo.texto
        .replaceAllMapped(
          RegExp(r'\{\{(\w+)\}\}'),
          (m) => valores[m.group(1)] ?? m.group(0)!,
        )
        .trim();
    final linhas = texto.split('\n');
    return ContratoDocumento(
      titulo: linhas.first.trim(),
      texto: linhas.skip(1).join('\n').trim(),
      assinaturas: [
        for (final l in locadores) 'LOCADOR: ${l.nome}',
        if (locatario != null) 'LOCATÁRIO: ${locatario.nome}',
        if (fiador != null) 'FIADOR: ${fiador.nome}',
        'ADMINISTRADORA: ${EmpresaInfo.nome}',
        'TESTEMUNHA 1',
        'TESTEMUNHA 2',
      ],
    );
  }

  String _num(double v) => decimalToText(v);

  String _qualificacao(Contato c) {
    final doc = c.documento.isEmpty
        ? ''
        : ', ${c.documento.replaceAll(RegExp(r'\D'), '').length > 11 ? 'CNPJ' : 'CPF'} ${c.documento}';
    final rg = c.rg.isEmpty ? '' : ', RG ${c.rg}';
    final civil = [
      if (c.nacionalidade.isNotEmpty) c.nacionalidade.toLowerCase(),
      ?c.estadoCivil?.toLowerCase(),
      if (c.profissao.isNotEmpty) c.profissao.toLowerCase(),
    ].join(', ');
    final end = [
      [c.logradouro, c.numero].where((e) => e.isNotEmpty).join(', '),
      c.complemento,
      c.bairro,
      [c.cidade, c.uf].where((e) => e.isNotEmpty).join('/'),
      if (c.cep.isNotEmpty) 'CEP ${c.cep}',
    ].where((e) => e.isNotEmpty).join(', ');
    return [
      '${c.nome}${civil.isEmpty ? '' : ', $civil'}$doc$rg',
      if (end.isNotEmpty) 'residente/sediado em $end',
    ].join(', ');
  }

  String _enderecoImovel(Imovel i) => [
    [i.logradouro, i.numero].where((e) => e.isNotEmpty).join(', '),
    i.complemento,
    i.bairro,
    [i.cidade, i.uf].where((e) => e.isNotEmpty).join('/'),
    if (i.cep.isNotEmpty) 'CEP ${i.cep}',
  ].where((e) => e.isNotEmpty).join(', ');
}
