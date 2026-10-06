import '../entities/conta_bancaria.dart';
import '../entities/financeiro_enums.dart';
import '../entities/fluxo_caixa.dart';
import '../entities/lancamento.dart';

/// Fluxo de caixa mensal do ano a partir das contas pagas e a pagar.
class FluxoCaixaService {
  const FluxoCaixaService();

  FluxoAno calcular({
    required List<Lancamento> lancamentos,
    required List<ContaBancaria> contas,
    required int ano,
    required RegimeFluxo regime,
  }) {
    // Saldo de abertura: saldo inicial das contas + tudo que foi movimentado
    // antes do ano.
    final abertura =
        contas.fold<double>(0, (s, c) => s + c.saldoInicial) +
        lancamentos
            .where(
              (l) =>
                  l.baixado && l.dataBaixa != null && l.dataBaixa!.year < ano,
            )
            .fold<double>(0, (s, l) => s + l.baixaComSinal);

    final entradas = List<double>.filled(13, 0);
    final saidas = List<double>.filled(13, 0);

    void somar(Lancamento l, DateTime data, double valor) {
      if (data.year != ano) return;
      (l.tipo == TipoLancamento.receber ? entradas : saidas)[data.month] +=
          valor;
    }

    for (final l in lancamentos) {
      if (l.baixado && l.dataBaixa != null) {
        somar(l, l.dataBaixa!, l.valorBaixa ?? l.valor);
      } else if (regime == RegimeFluxo.projetado && l.emAberto) {
        somar(l, l.vencimento, l.valor);
      }
    }

    var acumulado = abertura;
    final meses = <MesFluxo>[];
    for (var m = 1; m <= 12; m++) {
      acumulado += entradas[m] - saidas[m];
      meses.add(
        MesFluxo(
          mes: m,
          entradas: arredondar(entradas[m]),
          saidas: arredondar(saidas[m]),
          saldoAcumulado: arredondar(acumulado),
        ),
      );
    }
    return FluxoAno(saldoInicial: arredondar(abertura), meses: meses);
  }
}
