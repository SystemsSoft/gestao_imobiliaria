import '../../../../core/errors/domain_exception.dart';
import '../../../../core/presentation/view_model.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/usecases/entrar.dart';

class LoginViewModel extends ViewModel {
  LoginViewModel(this._entrar);

  final Entrar _entrar;

  bool carregando = false;
  bool senhaOculta = true;

  void alternarSenha() {
    senhaOculta = !senhaOculta;
    notificar();
  }

  String? validarUsuario(String? v) =>
      aparar(v ?? '').isEmpty ? 'Informe seu usuário' : null;

  String? validarSenha(String? v) =>
      aparar(v ?? '').isEmpty ? 'Informe sua senha' : null;

  /// Retorna true quando o login foi aceito.
  Future<bool> entrar(String usuario, String senha) async {
    carregando = true;
    erro = null;
    notificar();
    try {
      await _entrar(usuario: usuario, senha: senha);
      return true;
    } on DomainException catch (e) {
      erro = e.mensagem;
      return false;
    } finally {
      carregando = false;
      notificar();
    }
  }
}
