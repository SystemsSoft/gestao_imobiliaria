import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../domain/entities/boleto_bancario.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/usecases/boleto_usecases.dart';
import '../../domain/usecases/financeiro_usecases.dart';
import '../../domain/usecases/lancamento_usecases.dart';

/// Boletos emitidos e baixa automática pelo retorno bancário.
class BoletosViewModel extends ViewModel {
  BoletosViewModel(
    ObservarBoletos observarBoletos,
    ObservarLancamentos observarLancamentos,
    ObservarContasBancarias observarContas,
    ObservarContatos observarContatos,
    this._emitir,
    this._cancelar,
    this._retorno,
    this._imprimir, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    observar(observarBoletos(), (l) {
      _boletos = l;
      carregado = true;
    });
    observar(observarLancamentos(), (l) => _lancamentos = l);
    observar(observarContas(), (l) => contas = l);
    observar(observarContatos(), (l) => _contatos = l);
  }

  final EmitirBoleto _emitir;
  final CancelarBoleto _cancelar;
  final ProcessarRetornoBancario _retorno;
  final ImprimirBoletoBancario _imprimir;
  final DateTime Function() _agora;

  List<BoletoBancario> _boletos = const [];
  List<Lancamento> _lancamentos = const [];
  List<Contato> _contatos = const [];
  List<ContaBancaria> contas = const [];
  bool carregado = false;
  StatusBoleto? status;
  ResultadoRetorno? ultimoRetorno;

  DateTime get hoje => _agora();

  List<BoletoBancario> get filtrados =>
      _boletos.where((b) => status == null || b.status == status).toList()
        ..sort((a, b) => b.emissao.compareTo(a.emissao));

  /// Contas a receber em aberto que ainda não têm boleto emitido.
  List<Lancamento> get semBoleto {
    final comBoleto = {
      for (final b in _boletos)
        if (b.status == StatusBoleto.emitido) b.lancamentoId,
    };
    return _lancamentos
        .where(
          (l) =>
              l.tipo == TipoLancamento.receber &&
              l.emAberto &&
              !comBoleto.contains(l.id),
        )
        .toList()
      ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
  }

  double get totalEmitido => _boletos
      .where((b) => b.status == StatusBoleto.emitido)
      .fold(0, (s, b) => s + b.valor);
  double get totalPago => _boletos
      .where((b) => b.status == StatusBoleto.pago)
      .fold(0, (s, b) => s + (b.valorPago ?? 0));

  Lancamento? lancamento(String id) =>
      _lancamentos.where((l) => l.id == id).firstOrNull;

  String pagador(BoletoBancario b) {
    final id = lancamento(b.lancamentoId)?.contatoId;
    return _contatos.where((c) => c.id == id).firstOrNull?.nome ?? '—';
  }

  String nomeConta(String id) =>
      contas.where((c) => c.id == id).firstOrNull?.nome ?? '—';

  String? nomeContato(String? id) =>
      id == null ? null : _contatos.where((c) => c.id == id).firstOrNull?.nome;

  void filtrar(StatusBoleto? s) {
    status = s;
    notificar();
  }

  Future<bool> emitir(Lancamento l, String contaId) => executar(() async {
    await _emitir(l, contaId);
  });

  Future<bool> cancelar(BoletoBancario b) => executar(() => _cancelar(b));
  Future<bool> imprimir(BoletoBancario b) => executar(() => _imprimir(b));

  Future<bool> processarRetorno(String texto) => executar(() async {
    ultimoRetorno = await _retorno(texto);
  });
}
