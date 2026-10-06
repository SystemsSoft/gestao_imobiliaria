import 'locacao_enums.dart';

/// Proprietário (ou outro beneficiário) que recebe parte do aluguel.
class Beneficiario {
  const Beneficiario({required this.contatoId, required this.percentual});

  final String contatoId;
  final double percentual;
}

class ContratoLocacao {
  const ContratoLocacao({
    required this.id,
    required this.numero,
    required this.imovelId,
    required this.locatarioId,
    required this.beneficiarios,
    required this.dataInicio,
    required this.valorAluguel,
    this.fiadorId,
    this.finalidade = FinalidadeLocacao.residencial,
    this.garantia = GarantiaLocacao.fiador,
    this.valorGarantia,
    this.prazoMeses = 30,
    this.diaVencimento = 10,
    this.taxaAdministracao = 10,
    this.taxaIntermediacao = 0,
    this.indiceReajuste = IndiceReajuste.igpm,
    this.multaAtraso = 10,
    this.jurosMes = 1,
    this.descontoPontualidade = 0,
    this.status = StatusContrato.ativo,
    this.clausulasAdicionais = '',
    this.observacoes = '',
  });

  final String id;
  final String numero;
  final String imovelId;
  final String locatarioId;
  final String? fiadorId;
  final List<Beneficiario> beneficiarios;
  final FinalidadeLocacao finalidade;
  final GarantiaLocacao garantia;
  final double? valorGarantia;
  final DateTime dataInicio;
  final int prazoMeses;
  final int diaVencimento;
  final double valorAluguel;

  /// Percentual sobre o aluguel e encargos recebidos.
  final double taxaAdministracao;

  /// Percentual sobre o primeiro aluguel, descontado no primeiro repasse.
  final double taxaIntermediacao;
  final IndiceReajuste indiceReajuste;
  final double multaAtraso;
  final double jurosMes;

  /// Desconto em R$ para pagamento até o vencimento.
  final double descontoPontualidade;
  final StatusContrato status;
  final String clausulasAdicionais;
  final String observacoes;

  DateTime get dataFim => DateTime(
    dataInicio.year,
    dataInicio.month + prazoMeses,
    dataInicio.day,
  ).subtract(const Duration(days: 1));

  bool vigenteEm(DateTime competencia) {
    final c = competenciaDe(competencia);
    return status == StatusContrato.ativo &&
        !c.isBefore(competenciaDe(dataInicio)) &&
        !c.isAfter(competenciaDe(dataFim));
  }

  bool primeiraCompetencia(DateTime competencia) =>
      competenciaDe(competencia) == competenciaDe(dataInicio);

  ContratoLocacao copyWith({String? numero}) => ContratoLocacao(
    id: id,
    numero: numero ?? this.numero,
    imovelId: imovelId,
    locatarioId: locatarioId,
    beneficiarios: beneficiarios,
    dataInicio: dataInicio,
    valorAluguel: valorAluguel,
    fiadorId: fiadorId,
    finalidade: finalidade,
    garantia: garantia,
    valorGarantia: valorGarantia,
    prazoMeses: prazoMeses,
    diaVencimento: diaVencimento,
    taxaAdministracao: taxaAdministracao,
    taxaIntermediacao: taxaIntermediacao,
    indiceReajuste: indiceReajuste,
    multaAtraso: multaAtraso,
    jurosMes: jurosMes,
    descontoPontualidade: descontoPontualidade,
    status: status,
    clausulasAdicionais: clausulasAdicionais,
    observacoes: observacoes,
  );
}
