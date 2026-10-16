import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';

/// Autenticação local (sem servidor, usada nos testes): aceita qualquer
/// usuário e senha preenchidos.
class AuthRepositoryLocal implements AuthRepository {
  @override
  Future<Usuario> entrar({
    required String usuario,
    required String senha,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return Usuario(login: usuario);
  }

  @override
  Future<void> sair() async {}

  @override
  Future<void> alterarSenha({
    required String atual,
    required String nova,
  }) async {}
}
