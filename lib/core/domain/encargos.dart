/// Acréscimos ou desconto aplicados conforme a data do pagamento.
class Encargos {
  const Encargos({
    this.multa = 0,
    this.juros = 0,
    this.desconto = 0,
    this.diasAtraso = 0,
  });

  final double multa;
  final double juros;
  final double desconto;
  final int diasAtraso;

  double devido(double total) => total + multa + juros - desconto;
}

double _arredondar(double v) => (v * 100).roundToDouble() / 100;

/// Até o vencimento aplica [descontoPontualidade]; depois, multa sobre o
/// valor e juros de mora pro rata die (mês de 30 dias).
Encargos calcularEncargos({
  required double valor,
  required DateTime vencimento,
  required DateTime pagamento,
  required double multaPercentual,
  required double jurosMesPercentual,
  double descontoPontualidade = 0,
}) {
  final pg = DateTime(pagamento.year, pagamento.month, pagamento.day);
  if (!pg.isAfter(vencimento)) {
    return Encargos(
      desconto: descontoPontualidade > valor ? valor : descontoPontualidade,
    );
  }
  final dias = pg.difference(vencimento).inDays;
  return Encargos(
    multa: _arredondar(valor * multaPercentual / 100),
    juros: _arredondar(valor * jurosMesPercentual / 100 / 30 * dias),
    diasAtraso: dias,
  );
}
