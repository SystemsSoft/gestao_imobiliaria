/// Soma [meses] a [d] mantendo o dia, ajustado para o último dia do mês
/// quando ele não existe (ex.: 31/01 + 1 mês = 28/02).
DateTime somarMeses(DateTime d, int meses) {
  final ultimoDia = DateTime(d.year, d.month + meses + 1, 0).day;
  return DateTime(
    d.year,
    d.month + meses,
    d.day > ultimoDia ? ultimoDia : d.day,
  );
}

/// Primeiro dia do mês.
DateTime inicioDoMes(DateTime d) => DateTime(d.year, d.month);
