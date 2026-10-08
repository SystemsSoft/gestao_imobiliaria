import '../../../../core/presentation/view_model.dart';
import '../../../equipe/domain/entities/usuario_sistema.dart';
import '../../../equipe/domain/usecases/usuario_usecases.dart';
import '../../domain/entities/dashboard.dart';
import '../../domain/usecases/obter_dashboard.dart';

class DashboardViewModel extends ViewModel {
  DashboardViewModel(
    this._obter,
    ObservarUsuarios observarUsuarios,
    ObservarUsuarioAtual observarAtual, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    observar(observarUsuarios(), (l) => _usuarios = l);
    observar(observarAtual(), (id) => _usuarioAtualId = id);
    _carregar();
  }

  final ObterDashboard _obter;
  final DateTime Function() _agora;
  List<UsuarioSistema> _usuarios = const [];
  String? _usuarioAtualId;

  DashboardResumo? resumo;
  PeriodoDesempenho periodo = PeriodoDesempenho.mes;

  DateTime get agora => _agora();

  /// Primeiro nome do usuário atual, para a saudação.
  String get primeiroNome {
    final nome =
        _usuarios.where((u) => u.id == _usuarioAtualId).firstOrNull?.nome ?? '';
    return nome.trim().isEmpty ? '' : nome.trim().split(RegExp(r'\s+')).first;
  }

  Future<void> _carregar() async {
    final r = await _obter(periodo);
    if (disposed) return;
    resumo = r;
    notificar();
  }

  void mudarPeriodo(PeriodoDesempenho p) {
    periodo = p;
    _carregar();
  }
}
