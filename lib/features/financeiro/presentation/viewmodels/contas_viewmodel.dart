import '../../../../core/domain/encargos.dart';
import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/indice_mensal.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/services/atualizacao_monetaria.dart';
import '../../domain/usecases/financeiro_usecases.dart';
import '../../domain/usecases/lancamento_usecases.dart';

enum FiltroConta {
  todas('Todas'),
  abertas('Em aberto'),
  vencidas('Vencidas'),
  baixadas('Baixadas');

  const FiltroConta(this.label);
  final String label;
}

/// Contas a pagar e a receber.
class ContasViewModel extends ViewModel {
  ContasViewModel(
    ObservarLancamentos observarLancamentos,
    ObservarContatos observarContatos,
    ObservarContasBancarias observarContas,
    ObservarIndices observarIndices,
    this._calc,
    this._baixar,
    this._estornar,
    this._cancelar,
    this._remover, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    mes = DateTime(_agora().year, _agora().month);
    observar(observarLancamentos(), (l) {
      _lancamentos = l;
      carregado = true;
    });
    observar(observarContatos(), (l) => _contatos = l);
    observar(observarContas(), (l) => contas = l);
    observar(observarIndices(), (l) => _indices = l);
  }

  final CalcularEncargosLancamento _calc;
  final BaixarLancamento _baixar;
  final EstornarBaixa _estornar;
  final CancelarLancamento _cancelar;
  final RemoverLancamento _remover;
  final DateTime Function() _agora;

  List<Lancamento> _lancamentos = const [];
  List<Contato> _contatos = const [];
  List<IndiceMensal> _indices = const [];
  List<ContaBancaria> contas = const [];
  bool carregado = false;

  TipoLancamento tipo = TipoLancamento.receber;
  late DateTime mes;
  bool todosMeses = false;
  FiltroConta filtro = FiltroConta.todas;
  String query = '';

  DateTime get hoje => _agora();

  List<Lancamento> get _doTipo =>
      _lancamentos.where((l) => l.tipo == tipo).toList();

  /// Contas do período (mês de vencimento, ou de baixa quando já baixadas).
  List<Lancamento> get _doPeriodo => _doTipo
      .where(
        (l) =>
            todosMeses ||
            (l.vencimento.year == mes.year && l.vencimento.month == mes.month),
      )
      .toList();

  List<Lancamento> get filtradas {
    final q = query.trim().toLowerCase();
    final h = hoje;
    return _doPeriodo.where((l) {
      final ok = switch (filtro) {
        FiltroConta.todas => true,
        FiltroConta.abertas => l.emAberto,
        FiltroConta.vencidas => l.vencido(h),
        FiltroConta.baixadas => l.baixado,
      };
      if (!ok) return false;
      if (q.isEmpty) return true;
      return [
        l.descricao,
        l.categoria,
        l.documento,
        nomeContato(l.contatoId) ?? '',
      ].any((t) => t.toLowerCase().contains(q));
    }).toList()..sort((a, b) => a.vencimento.compareTo(b.vencimento));
  }

  double get total => _doPeriodo
      .where((l) => l.status != StatusLancamento.cancelado)
      .fold(0, (s, l) => s + l.valor);
  double get emAberto =>
      _doPeriodo.where((l) => l.emAberto).fold(0, (s, l) => s + l.valor);
  double get baixado => _doPeriodo
      .where((l) => l.baixado)
      .fold(0, (s, l) => s + (l.valorBaixa ?? 0));

  /// Total vencido e não baixado, em qualquer mês.
  double get totalVencido =>
      _doTipo.where((l) => l.vencido(hoje)).fold(0, (s, l) => s + l.valor);

  bool get semCadastro => _lancamentos.isEmpty;

  String? nomeContato(String? id) =>
      id == null ? null : _contatos.where((c) => c.id == id).firstOrNull?.nome;

  void mudarTipo(TipoLancamento t) {
    tipo = t;
    notificar();
  }

  void mudarMes(DateTime m) {
    mes = DateTime(m.year, m.month);
    notificar();
  }

  void alternarTodosMeses(bool v) {
    todosMeses = v;
    notificar();
  }

  void filtrar(FiltroConta f) {
    filtro = f;
    notificar();
  }

  void buscar(String t) {
    query = t;
    notificar();
  }

  ({Encargos encargos, VariacaoAcumulada variacao}) simular(
    Lancamento l,
    DateTime data,
  ) => _calc(l, data, _indices);

  Future<bool> baixar(
    Lancamento l,
    DateTime data,
    double valor,
    MeioPagamento meio,
    String? contaId,
  ) => executar(() async {
    await _baixar(l, data, valorBaixa: valor, meio: meio, contaId: contaId);
  });

  Future<bool> estornar(Lancamento l) => executar(() => _estornar(l));
  Future<bool> cancelar(Lancamento l) => executar(() => _cancelar(l));
  Future<bool> remover(Lancamento l) => executar(() => _remover(l));
}
