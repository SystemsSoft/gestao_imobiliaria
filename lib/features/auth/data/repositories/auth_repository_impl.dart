import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';

/// Autenticação provisória: aceita qualquer credencial válida no formato.
/// TODO: integrar com o backend de autenticação.
class AuthRepositoryLocal implements AuthRepository {
  @override
  Future<Usuario> entrar({required String email, required String senha}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return Usuario(email: email);
  }
}
