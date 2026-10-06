import '../../../../core/domain/encargos.dart';
import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../domain/entities/parcela.dart';
import '../../domain/entities/venda.dart';
import '../../domain/entities/venda_enums.dart';
import '../../domain/usecases/parcela_usecases.dart';
import '../../domain/usecases/venda_usecases.dart';

enum FiltroParcela {
  todas('Todas'),
  abertas('Em aberto'),
  atrasadas('Atrasadas'),
  pagas('Pagas');

  const FiltroParcela(this.label);
  final String label;
}

/// Parcelas a receber de todas as vendas, por mês de vencimento.
class RecebimentosViewModel extends ViewModel {
  RecebimentosViewModel(
    ObservarParcelas observarParcelas,
    ObservarVendas observarVendas,
    ObservarContatos observarContatos,
    this._encargos,
    this._pagar,
    this._estornar, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    mes = DateTime(_agora().year, _agora().month);
    observar(observarParcelas(), (l) {
      _parcelas = l;
      carregado = true;
    });
    observar(observarVendas(), (l) => _vendas = l);
    observar(observarContatos(), (l) => _contatos = l);
  }

  final CalcularEncargosParcela _encargos;
  final RegistrarPagamentoParcela _pagar;
  final EstornarPagamentoParcela _estornar;
  final DateTime Function() _agora;

  List<Parcela> _parcelas = const [];
  List<Venda> _vendas = const [];
  List<Contato> _contatos = const [];
  bool carregado = false;
  late DateTime mes;
  FiltroParcela filtro = FiltroParcela.todas;

  DateTime get hoje => _agora();

  void mudarMes(DateTime m) {
    mes = DateTime(m.year, m.month);
    notificar();
  }

  void filtrar(FiltroParcela f) {
    filtro = f;
    notificar();
  }

  Venda? venda(String id) => _vendas.where((v) => v.id == id).firstOrNull;

  String compradores(Parcela p) => (venda(p.vendaId)?.compradores ?? const [])
      .map((id) => _contatos.where((c) => c.id == id).firstOrNull?.nome ?? '—')
      .join(', ');

  List<Parcela> get _doMes => _parcelas
      .where(
        (p) =>
            p.vencimento.year == mes.year &&
            p.vencimento.month == mes.month &&
            p.status != StatusParcela.cancelada,
      )
      .toList();

  List<Parcela> get filtradas =>
      _doMes
          .where(
            (p) => switch (filtro) {
              FiltroParcela.todas => true,
              FiltroParcela.abertas => p.status == StatusParcela.aberta,
              FiltroParcela.atrasadas => p.atrasada(hoje),
              FiltroParcela.pagas => p.status == StatusParcela.paga,
            },
          )
          .toList()
        ..sort((a, b) => a.vencimento.compareTo(b.vencimento));

  double get previsto => _doMes.fold(0, (s, p) => s + p.valor);
  double get recebido => _doMes
      .where((p) => p.status == StatusParcela.paga)
      .fold(0, (s, p) => s + (p.valorPago ?? 0));
  double get emAberto => _doMes
      .where((p) => p.status == StatusParcela.aberta)
      .fold(0, (s, p) => s + p.valor);

  /// Total em atraso em todas as vendas (não só no mês).
  double get totalAtrasado =>
      _parcelas.where((p) => p.atrasada(hoje)).fold(0, (s, p) => s + p.valor);

  Encargos? simular(Parcela p, DateTime data) {
    final v = venda(p.vendaId);
    return v == null ? null : _encargos(v, p, data);
  }

  Future<bool> pagar(Parcela p, DateTime data, double valor) =>
      executar(() => _pagar(p, data, valorPago: valor));
  Future<bool> estornar(Parcela p) => executar(() => _estornar(p));
}
