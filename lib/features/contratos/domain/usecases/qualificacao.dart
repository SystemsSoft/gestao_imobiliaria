import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', //
  'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

String dataPorExtenso(DateTime d) =>
    '${d.day} de ${_meses[d.month - 1]} de ${d.year}';

/// "Niterói, 5 de janeiro de 2026."
String cidadeData(String cidade, DateTime d) =>
    '${cidade.isEmpty ? '' : '$cidade, '}${dataPorExtenso(d)}.';

/// Qualificação da parte para contratos: nome, estado civil, profissão,
/// documento e endereço.
String qualificacaoContato(Contato c) {
  final digitos = c.documento.replaceAll(RegExp(r'\D'), '');
  final doc = c.documento.isEmpty
      ? ''
      : ', ${digitos.length > 11 ? 'CNPJ' : 'CPF'} ${c.documento}';
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

String enderecoCompleto(Imovel i) => [
  [i.logradouro, i.numero].where((e) => e.isNotEmpty).join(', '),
  i.complemento,
  i.bairro,
  [i.cidade, i.uf].where((e) => e.isNotEmpty).join('/'),
  if (i.cep.isNotEmpty) 'CEP ${i.cep}',
].where((e) => e.isNotEmpty).join(', ');
