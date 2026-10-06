import '../../../../core/presentation/view_model.dart';
import '../../../../core/utils/documentos.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../../locacao/domain/usecases/cobranca_usecases.dart';
import '../../../locacao/domain/usecases/contrato_usecases.dart';
import '../../../locacao/domain/usecases/despesa_usecases.dart';
import '../../../vendas/domain/usecases/venda_usecases.dart';
import '../../domain/entities/declarante_dimob.dart';
import '../../domain/entities/dimob.dart';
import '../../domain/usecases/fiscal_usecases.dart';
import '../../domain/usecases/gerar_dimob.dart';

/// Geração da DIMOB: monta a declaração do ano a partir dos dados do sistema.
class DimobViewModel extends ViewModel {
  DimobViewModel(
    ObservarCobrancas observarCobrancas,
    ObservarContratos observarContratos,
    ObservarDespesas observarDespesas,
    ObservarVendas observarVendas,
    ObservarParcelas observarParcelas,
    ObservarContatos observarContatos,
    ObservarImoveis observarImoveis,
    ObservarDeclarante observarDeclarante,
    this._gerar,
    this._salvarDeclarante,
    this._imprimir,
    this._csv, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    // A DIMOB entregue em fevereiro refere-se ao ano anterior.
    final hoje = _agora();
    ano = hoje.month <= 3 ? hoje.year - 1 : hoje.year;
    for (final s in <Stream<Object?>>[
      observarCobrancas(),
      observarContratos(),
      observarDespesas(),
      observarVendas(),
      observarParcelas(),
      observarContatos(),
      observarImoveis(),
      observarDeclarante(),
    ]) {
      observar(s, (_) => _recalcular());
    }
  }

  final GerarDimob _gerar;
  final SalvarDeclarante _salvarDeclarante;
  final ImprimirConferenciaDimob _imprimir;
  final GerarCsvDimob _csv;
  final DateTime Function() _agora;

  late int ano;
  DeclaracaoDimob? declaracao;
  bool carregado = false;
  DateTime? geradaEm;
  int _versao = 0;

  /// Prazo de entrega: último dia útil de fevereiro do ano seguinte.
  DateTime get prazo => ultimoDiaUtil(ano + 1, 2);

  bool get atrasada => _agora().isAfter(prazo);

  Future<void> _recalcular() async {
    final versao = ++_versao;
    final d = await _gerar(ano);
    if (versao != _versao || disposed) return;
    declaracao = d;
    carregado = true;
    notificar();
  }

  void mudarAno(int a) {
    ano = a;
    geradaEm = null;
    _recalcular();
  }

  Future<bool> salvarDeclarante(DeclaranteDimob d) =>
      executar(() => _salvarDeclarante(d));

  /// Abre o PDF de conferência e registra a geração.
  Future<bool> gerarConferencia() => executar(() async {
    await _imprimir(declaracao!);
    geradaEm = _agora();
  });

  /// Dados em CSV para copiar.
  String get csv => _csv(declaracao!);
}
