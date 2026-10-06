import '../../../../core/errors/domain_exception.dart';
import '../../../../core/presentation/view_model.dart';
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

  String? validarEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Informe seu e-mail';
    if (!value.contains('@') || !value.contains('.')) return 'E-mail inválido';
    return null;
  }

  String? validarSenha(String? v) =>
      (v == null || v.isEmpty) ? 'Informe sua senha' : null;

  /// Retorna true quando o login foi aceito.
  Future<bool> entrar(String email, String senha) async {
    carregando = true;
    erro = null;
    notificar();
    try {
      await _entrar(email: email, senha: senha);
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
