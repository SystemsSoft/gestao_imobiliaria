import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/entities/fluxo_caixa.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/usecases/financeiro_usecases.dart';
import '../../domain/usecases/lancamento_usecases.dart';

/// Fluxo de caixa mensal com saldo acumulado.
class FluxoCaixaViewModel extends ViewModel {
  FluxoCaixaViewModel(
    ObservarLancamentos observarLancamentos,
    ObservarContasBancarias observarContas,
    this._calcular,
  ) {
    observar(observarLancamentos(), (l) {
      _lancamentos = l;
      carregado = true;
    });
    observar(observarContas(), (l) => _contas = l);
  }

  final CalcularFluxoCaixa _calcular;

  List<Lancamento> _lancamentos = const [];
  List<ContaBancaria> _contas = const [];
  bool carregado = false;
  int ano = DateTime.now().year;
  RegimeFluxo regime = RegimeFluxo.projetado;
  int? mesSelecionado;

  FluxoAno get fluxo => _calcular(
    lancamentos: _lancamentos,
    contas: _contas,
    ano: ano,
    regime: regime,
  );

  /// Maior valor entre entradas e saídas, para dimensionar o gráfico.
  double get maiorValor {
    final v = fluxo.meses
        .expand((m) => [m.entradas, m.saidas])
        .fold<double>(0, (a, b) => a > b ? a : b);
    return v == 0 ? 1 : v;
  }

  /// Movimentos do mês selecionado (baixas pela data de pagamento e, no
  /// regime projetado, contas em aberto pelo vencimento).
  List<({Lancamento lancamento, DateTime data, bool previsto})> get movimentos {
    final m = mesSelecionado;
    if (m == null) return const [];
    final lista = <({Lancamento lancamento, DateTime data, bool previsto})>[];
    for (final l in _lancamentos) {
      if (l.baixado && l.dataBaixa != null) {
        if (l.dataBaixa!.year == ano && l.dataBaixa!.month == m) {
          lista.add((lancamento: l, data: l.dataBaixa!, previsto: false));
        }
      } else if (regime == RegimeFluxo.projetado && l.emAberto) {
        if (l.vencimento.year == ano && l.vencimento.month == m) {
          lista.add((lancamento: l, data: l.vencimento, previsto: true));
        }
      }
    }
    return lista..sort((a, b) => a.data.compareTo(b.data));
  }

  void mudarAno(int a) {
    ano = a;
    mesSelecionado = null;
    notificar();
  }

  void mudarRegime(RegimeFluxo r) {
    regime = r;
    notificar();
  }

  void selecionarMes(int? m) {
    mesSelecionado = mesSelecionado == m ? null : m;
    notificar();
  }

  /// Saldo atual das contas bancárias (movimento já baixado).
  double get saldoAtual =>
      _contas.fold<double>(0, (s, c) => s + c.saldoInicial) +
      _lancamentos
          .where((l) => l.baixado)
          .fold<double>(0, (s, l) => s + l.baixaComSinal);
}
