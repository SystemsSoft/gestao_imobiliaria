import '../entities/usuario.dart';

abstract interface class AuthRepository {
  /// Lança [DomainException] quando as credenciais são inválidas.
  Future<Usuario> entrar({required String email, required String senha});
}
