import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../domain/entities/cobranca.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../../../core/domain/encargos.dart';
import '../../domain/entities/locacao_enums.dart';
import '../../domain/usecases/cobranca_usecases.dart';
import '../../domain/usecases/contrato_usecases.dart';
import '../../domain/usecases/imprimir_documentos.dart';

enum FiltroCobranca {
  todas('Todas'),
  abertas('Em aberto'),
  atrasadas('Atrasadas'),
  pagas('Pagas'),
  canceladas('Canceladas');

  const FiltroCobranca(this.label);
  final String label;
}

class CobrancasViewModel extends ViewModel {
  CobrancasViewModel(
    ObservarCobrancas observarCobrancas,
    ObservarContratos observarContratos,
    ObservarContatos observarContatos,
    this._gerar,
    this._encargos,
    this._pagar,
    this._estornar,
    this._cancelar,
    this._remover,
    this._boleto,
    this._recibo, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    competencia = competenciaDe(_agora());
    observar(observarCobrancas(), (l) {
      _cobrancas = l;
      carregado = true;
    });
    observar(observarContratos(), (l) => _contratos = l);
    observar(observarContatos(), (l) => _contatos = l);
  }

  final GerarCobrancasDoMes _gerar;
  final CalcularEncargos _encargos;
  final RegistrarPagamento _pagar;
  final EstornarPagamento _estornar;
  final CancelarCobranca _cancelar;
  final RemoverCobranca _remover;
  final ImprimirBoleto _boleto;
  final ImprimirRecibo _recibo;
  final DateTime Function() _agora;

  List<Cobranca> _cobrancas = const [];
  List<ContratoLocacao> _contratos = const [];
  List<Contato> _contatos = const [];
  bool carregado = false;
  late DateTime competencia;
  FiltroCobranca filtro = FiltroCobranca.todas;

  /// Mensagem do último "gerar cobranças".
  String? resultadoGeracao;

  DateTime get hoje => _agora();

  void mudarCompetencia(DateTime c) {
    competencia = competenciaDe(c);
    notificar();
  }

  void filtrar(FiltroCobranca f) {
    filtro = f;
    notificar();
  }

  ContratoLocacao? contrato(String id) =>
      _contratos.where((c) => c.id == id).firstOrNull;

  String locatario(Cobranca c) =>
      contatoPorId(_contatos, contrato(c.contratoId)?.locatarioId)?.nome ?? '—';

  List<Cobranca> get _doMes =>
      _cobrancas.where((c) => c.competencia == competencia).toList();

  List<Cobranca> get filtradas {
    final h = hoje;
    return _doMes
        .where(
          (c) => switch (filtro) {
            FiltroCobranca.todas => true,
            FiltroCobranca.abertas => c.status == StatusCobranca.aberta,
            FiltroCobranca.atrasadas => c.atrasada(h),
            FiltroCobranca.pagas => c.status == StatusCobranca.paga,
            FiltroCobranca.canceladas => c.status == StatusCobranca.cancelada,
          },
        )
        .toList()
      ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
  }

  double get totalPrevisto => _doMes
      .where((c) => c.status != StatusCobranca.cancelada)
      .fold(0, (s, c) => s + c.total);

  double get totalRecebido => _doMes
      .where((c) => c.status == StatusCobranca.paga)
      .fold(0, (s, c) => s + (c.valorPago ?? 0));

  double get totalEmAberto => _doMes
      .where((c) => c.status == StatusCobranca.aberta)
      .fold(0, (s, c) => s + c.total);

  Future<void> gerar() => executar(() async {
    final r = await _gerar(competencia);
    resultadoGeracao = r.criadas == 0 && r.atualizadas == 0
        ? 'Nenhum contrato vigente sem cobrança nesta competência.'
        : '${r.criadas} cobrança(s) criada(s), '
              '${r.atualizadas} atualizada(s).';
  });

  /// Simulação exibida no diálogo de pagamento.
  Encargos? simularEncargos(Cobranca c, DateTime data) {
    final k = contrato(c.contratoId);
    return k == null ? null : _encargos(k, c, data);
  }

  Future<bool> pagar(Cobranca c, DateTime data, double? valor) =>
      executar(() => _pagar(c, data, valorPago: valor));

  Future<bool> estornar(Cobranca c) => executar(() => _estornar(c));
  Future<bool> cancelar(Cobranca c) => executar(() => _cancelar(c));
  Future<bool> remover(Cobranca c) => executar(() => _remover(c.id));
  Future<bool> boleto(Cobranca c) => executar(() => _boleto(c));
  Future<bool> recibo(Cobranca c) => executar(() => _recibo(c));
}
