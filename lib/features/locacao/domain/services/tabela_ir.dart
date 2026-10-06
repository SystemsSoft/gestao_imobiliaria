import 'dart:math';

import '../entities/locacao_enums.dart';

class FaixaIR {
  const FaixaIR(this.limite, this.aliquota, this.deducao);

  final double limite;
  final double aliquota;
  final double deducao;
}

/// Tabela progressiva mensal do IRPF vigente desde maio/2025
/// (Lei nº 15.191/2025). Confirme os valores com o contador a cada ano.
const faixasIrMensal = [
  FaixaIR(2428.80, 0, 0),
  FaixaIR(2826.65, 0.075, 182.16),
  FaixaIR(3751.05, 0.15, 394.16),
  FaixaIR(4664.68, 0.225, 675.49),
  FaixaIR(double.infinity, 0.275, 908.73),
];

/// Cálculo do IRPF mensal sobre aluguéis (carnê-leão e retenção na fonte).
class TabelaIR {
  const TabelaIR();

  double impostoTabela(double base) {
    if (base <= 0) return 0;
    final faixa = faixasIrMensal.firstWhere((f) => base <= f.limite);
    return max(0, base * faixa.aliquota - faixa.deducao);
  }

  /// Redução mensal da Lei nº 15.270/2025, a partir de 2026: zera o imposto
  /// até R$ 5.000,00 e reduz parcialmente até R$ 7.350,00.
  double redutor(double base, double imposto) {
    if (base <= 5000) return imposto;
    if (base <= 7350) return min(imposto, max(0, 978.62 - 0.133145 * base));
    return 0;
  }

  double impostoMensal(double base, {required int ano}) {
    var imposto = impostoTabela(base);
    if (ano >= 2026) imposto -= redutor(base, imposto);
    return arredondar(max(0, imposto));
  }
}
