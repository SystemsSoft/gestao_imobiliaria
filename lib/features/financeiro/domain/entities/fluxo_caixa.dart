enum RegimeFluxo {
  realizado('Realizado', 'apenas o que já foi pago ou recebido'),
  projetado('Projetado', 'realizado + contas em aberto pelo vencimento');

  const RegimeFluxo(this.label, this.descricao);
  final String label;
  final String descricao;
}

class MesFluxo {
  const MesFluxo({
    required this.mes,
    required this.entradas,
    required this.saidas,
    required this.saldoAcumulado,
  });

  final int mes;
  final double entradas;
  final double saidas;
  final double saldoAcumulado;

  double get saldo => entradas - saidas;
}

class FluxoAno {
  const FluxoAno({required this.saldoInicial, required this.meses});

  final double saldoInicial;
  final List<MesFluxo> meses;

  double get totalEntradas => meses.fold(0, (s, m) => s + m.entradas);
  double get totalSaidas => meses.fold(0, (s, m) => s + m.saidas);
  double get saldoFinal =>
      meses.isEmpty ? saldoInicial : meses.last.saldoAcumulado;
}
