import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/entities/linha_extrato.dart';
import '../../domain/services/conciliacao_service.dart';
import '../../domain/usecases/financeiro_usecases.dart';
import '../../domain/usecases/lancamento_usecases.dart';

/// Conciliação bancária: extrato × contas baixadas.
class ConciliacaoViewModel extends ViewModel {
  ConciliacaoViewModel(
    ObservarContasBancarias observarContas,
    ObservarExtrato observarExtrato,
    ObservarLancamentos observarLancamentos,
    this._salvarConta,
    this._removerConta,
    this._salvarLinha,
    this._removerLinha,
    this._conciliar,
    this._desfazer,
    this._conciliarAuto,
    this._service,
  ) {
    observar(observarContas(), (l) {
      contas = l;
      carregado = true;
    });
    observar(observarExtrato(), (l) => _extrato = l);
    observar(observarLancamentos(), (l) => _lancamentos = l);
  }

  final SalvarContaBancaria _salvarConta;
  final RemoverContaBancaria _removerConta;
  final SalvarLinhaExtrato _salvarLinha;
  final RemoverLinhaExtrato _removerLinha;
  final ConciliarLinha _conciliar;
  final DesfazerConciliacao _desfazer;
  final ConciliarAutomaticamente _conciliarAuto;
  final ConciliacaoService _service;

  List<ContaBancaria> contas = const [];
  List<LinhaExtrato> _extrato = const [];
  List<Lancamento> _lancamentos = const [];
  bool carregado = false;
  String? _contaId;

  /// Mensagem do último "conciliar automaticamente".
  String? resultadoAuto;

  ContaBancaria? get conta =>
      contas.where((c) => c.id == _contaId).firstOrNull ?? contas.firstOrNull;

  void selecionarConta(String? id) {
    _contaId = id;
    notificar();
  }

  List<LinhaExtrato> get linhas =>
      _extrato.where((l) => l.contaId == conta?.id).toList()
        ..sort((a, b) => b.data.compareTo(a.data));

  int get pendentes => linhas.where((l) => !l.conciliada).length;

  /// Baixas da conta sem linha de extrato.
  List<Lancamento> get candidatos => conta == null
      ? const []
      : _service.candidatos(_lancamentos, _extrato, conta!.id);

  /// Para cada linha pendente, a baixa sugerida.
  Map<String, Lancamento> get sugestoes => {
    for (final s
        in conta == null
            ? const <SugestaoConciliacao>[]
            : _service.sugerir(_lancamentos, _extrato, conta!.id))
      s.linha.id: s.lancamento,
  };

  SaldosConta? get saldos =>
      conta == null ? null : _service.saldos(conta!, _lancamentos, _extrato);

  Lancamento? lancamento(String? id) =>
      _lancamentos.where((l) => l.id == id).firstOrNull;

  Future<bool> salvarConta(ContaBancaria c) => executar(() => _salvarConta(c));
  Future<bool> removerConta(String id) => executar(() => _removerConta(id));
  Future<bool> salvarLinha(LinhaExtrato l) => executar(() => _salvarLinha(l));
  Future<bool> removerLinha(String id) => executar(() => _removerLinha(id));
  Future<bool> conciliar(LinhaExtrato l, Lancamento x) =>
      executar(() => _conciliar(l, x));
  Future<bool> desfazer(LinhaExtrato l) => executar(() => _desfazer(l));

  Future<bool> conciliarAutomaticamente() => executar(() async {
    final n = await _conciliarAuto(_lancamentos, conta!.id);
    resultadoAuto = n == 0
        ? 'Nenhuma correspondência encontrada.'
        : '$n linha(s) conciliada(s).';
  });
}
