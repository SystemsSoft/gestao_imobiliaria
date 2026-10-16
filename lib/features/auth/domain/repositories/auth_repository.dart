import '../entities/usuario.dart';

abstract interface class AuthRepository {
  /// Lança [DomainException] quando as credenciais são inválidas.
  Future<Usuario> entrar({required String usuario, required String senha});

  /// Encerra a sessão atual.
  Future<void> sair();

  Future<void> alterarSenha({required String atual, required String nova});
}
