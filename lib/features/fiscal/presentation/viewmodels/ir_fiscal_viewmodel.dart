import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../locacao/domain/usecases/cobranca_usecases.dart';
import '../../../locacao/domain/usecases/contrato_usecases.dart';
import '../../../locacao/domain/usecases/despesa_usecases.dart';
import '../../domain/entities/ir_fiscal.dart';
import '../../domain/usecases/fiscal_usecases.dart';

/// Cálculo do Imposto de Renda sobre aluguéis, por beneficiário.
class IrFiscalViewModel extends ViewModel {
  IrFiscalViewModel(
    ObservarCobrancas observarCobrancas,
    ObservarContratos observarContratos,
    ObservarDespesas observarDespesas,
    ObservarContatos observarContatos,
    this._calcular,
    this._imprimir,
  ) {
    for (final s in <Stream<Object?>>[
      observarCobrancas(),
      observarContratos(),
      observarDespesas(),
      observarContatos(),
    ]) {
      observar(s, (_) => _recalcular());
    }
  }

  final CalcularIrConsolidado _calcular;
  final ImprimirInformeIr _imprimir;

  int ano = DateTime.now().year;
  List<IrBeneficiario> beneficiarios = const [];
  List<DarfCarneLeao> darfs = const [];
  bool carregado = false;
  String? aberto;
  int _versao = 0;

  Future<void> _recalcular() async {
    final versao = ++_versao;
    final r = await _calcular(ano);
    if (versao != _versao || disposed) return;
    beneficiarios = r.beneficiarios;
    darfs = r.darfs;
    carregado = true;
    notificar();
  }

  void mudarAno(int a) {
    ano = a;
    aberto = null;
    _recalcular();
  }

  void alternar(String id) {
    aberto = aberto == id ? null : id;
    notificar();
  }

  double get totalBruto => beneficiarios.fold(0, (s, b) => s + b.bruto);
  double get totalCarneLeao => beneficiarios.fold(0, (s, b) => s + b.carneLeao);
  double get totalIrrf => beneficiarios.fold(0, (s, b) => s + b.irrf);

  Future<bool> imprimirInforme(IrBeneficiario b) =>
      executar(() => _imprimir(b, ano));
}
