/// Resumo mensal do Imposto de Renda sobre aluguéis de um beneficiário
/// (regime de caixa: mês do recebimento).
class IrMensal {
  const IrMensal({
    required this.mes,
    this.rendimentoBruto = 0,
    this.deducoes = 0,
    this.baseCarneLeao = 0,
    this.impostoCarneLeao = 0,
    this.baseIrrf = 0,
    this.irrfRetido = 0,
  });

  final int mes;
  final double rendimentoBruto;
  final double deducoes;

  /// Aluguéis recebidos de pessoa física: o beneficiário recolhe pelo
  /// carnê-leão.
  final double baseCarneLeao;
  final double impostoCarneLeao;

  /// Aluguéis recebidos de pessoa jurídica, com retenção na fonte.
  final double baseIrrf;
  final double irrfRetido;
}
