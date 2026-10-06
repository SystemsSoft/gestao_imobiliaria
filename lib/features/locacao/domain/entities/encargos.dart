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
