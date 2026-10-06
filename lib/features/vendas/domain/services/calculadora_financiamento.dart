import 'dart:math';

import '../entities/venda.dart';
import '../entities/venda_enums.dart';

class ParcelaPlano {
  const ParcelaPlano({
    required this.numero,
    required this.vencimento,
    required this.valor,
    required this.amortizacao,
    required this.juros,
    required this.saldoDevedor,
  });

  final int numero;
  final DateTime vencimento;
  final double valor;
  final double amortizacao;
  final double juros;
  final double saldoDevedor;
}

/// Tabela de amortização do financiamento próprio (Price, SAC ou sem juros).
class CalculadoraFinanciamento {
  const CalculadoraFinanciamento();

  /// Vencimento da parcela [indice] (0 = primeira), mantendo o dia do mês e
  /// ajustando para o último dia em meses mais curtos.
  DateTime vencimento(DateTime primeiro, int indice) {
    final ultimoDia = DateTime(
      primeiro.year,
      primeiro.month + indice + 1,
      0,
    ).day;
    return DateTime(
      primeiro.year,
      primeiro.month + indice,
      min(primeiro.day, ultimoDia),
    );
  }

  List<ParcelaPlano> calcular(double principal, PlanoFinanciamento plano) {
    final n = plano.numeroParcelas;
    if (n <= 0 || principal <= 0) return const [];
    final i = plano.sistema == SistemaAmortizacao.semJuros
        ? 0.0
        : plano.taxaJurosMes / 100;
    final prestacaoPrice = i == 0
        ? arredondar(principal / n)
        : arredondar(principal * i / (1 - pow(1 + i, -n)));
    final amortizacaoSac = arredondar(principal / n);

    var saldo = principal;
    return [
      for (var k = 1; k <= n; k++)
        () {
          final juros = arredondar(saldo * i);
          final ultima = k == n;
          final amort = ultima
              ? arredondar(saldo)
              : plano.sistema == SistemaAmortizacao.sac
              ? amortizacaoSac
              : arredondar(prestacaoPrice - juros);
          saldo = arredondar(saldo - amort);
          return ParcelaPlano(
            numero: k,
            vencimento: vencimento(plano.primeiroVencimento, k - 1),
            valor: arredondar(amort + juros),
            amortizacao: amort,
            juros: juros,
            saldoDevedor: saldo,
          );
        }(),
    ];
  }
}
