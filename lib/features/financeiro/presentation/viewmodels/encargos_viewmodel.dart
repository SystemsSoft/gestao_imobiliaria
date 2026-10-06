import '../../../../core/domain/encargos.dart';
import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/indice_mensal.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/services/atualizacao_monetaria.dart';
import '../../domain/usecases/financeiro_usecases.dart';
import '../../domain/usecases/lancamento_usecases.dart';

/// Juros, multa e atualização monetária: índices, padrões e simulador.
class EncargosViewModel extends ViewModel {
  EncargosViewModel(
    ObservarIndices observarIndices,
    ObservarConfiguracaoFinanceira observarConfig,
    this._salvarIndice,
    this._removerIndice,
    this._salvarConfig,
    this._calc,
  ) {
    observar(observarIndices(), (l) {
      indices = [...l]
        ..sort((a, b) {
          final c = b.ano.compareTo(a.ano);
          if (c != 0) return c;
          final m = b.mes.compareTo(a.mes);
          return m != 0 ? m : a.indice.index.compareTo(b.indice.index);
        });
      carregado = true;
    });
    observar(observarConfig(), (c) => config = c);
  }

  final SalvarIndice _salvarIndice;
  final RemoverIndice _removerIndice;
  final SalvarConfiguracaoFinanceira _salvarConfig;
  final CalcularEncargosLancamento _calc;

  List<IndiceMensal> indices = const [];
  ConfiguracaoFinanceira config = const ConfiguracaoFinanceira();
  bool carregado = false;
  IndiceMonetario? filtroIndice;

  List<IndiceMensal> get indicesFiltrados => indices
      .where((i) => filtroIndice == null || i.indice == filtroIndice)
      .toList();

  void filtrar(IndiceMonetario? i) {
    filtroIndice = i;
    notificar();
  }

  /// Simula o valor devido de uma conta paga em [pagamento].
  ({Encargos encargos, VariacaoAcumulada variacao, double devido}) simular({
    required double valor,
    required DateTime vencimento,
    required DateTime pagamento,
    required double multa,
    required double juros,
    required IndiceMonetario indice,
  }) {
    final l = Lancamento(
      id: 'simulacao',
      tipo: TipoLancamento.receber,
      descricao: 'Simulação',
      valor: valor,
      vencimento: vencimento,
      multaPercentual: multa,
      jurosMesPercentual: juros,
      indice: indice,
    );
    final r = _calc(l, pagamento, indices);
    return (
      encargos: r.encargos,
      variacao: r.variacao,
      devido: arredondar(r.encargos.devido(valor)),
    );
  }

  Future<bool> salvarIndice(IndiceMensal i) => executar(() => _salvarIndice(i));
  Future<bool> removerIndice(String id) => executar(() => _removerIndice(id));
  Future<bool> salvarConfig(ConfiguracaoFinanceira c) =>
      executar(() => _salvarConfig(c));
}
