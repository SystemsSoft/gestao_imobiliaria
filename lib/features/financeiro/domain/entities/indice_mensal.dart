import 'financeiro_enums.dart';

/// Variação mensal de um índice de correção (ex.: IGP-M de 03/2026).
class IndiceMensal {
  const IndiceMensal({
    required this.indice,
    required this.ano,
    required this.mes,
    required this.percentual,
  });

  final IndiceMonetario indice;
  final int ano;
  final int mes;

  /// Variação do mês em % (pode ser negativa).
  final double percentual;

  String get id => '${indice.name}-$ano-$mes';
}

class ConfiguracaoFinanceira {
  const ConfiguracaoFinanceira({
    this.multaPercentual = 2,
    this.jurosMesPercentual = 1,
    this.indicePadrao = IndiceMonetario.nenhum,
    this.linkBanco = '',
  });

  /// Valores sugeridos ao criar contas a receber.
  final double multaPercentual;
  final double jurosMesPercentual;
  final IndiceMonetario indicePadrao;

  /// Link do internet banking aberto pelo botão "Abrir banco" do Financeiro.
  final String linkBanco;
}
