import '../../../../core/errors/domain_exception.dart';
import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

class Entrar {
  const Entrar(this._repository);

  final AuthRepository _repository;

  Future<Usuario> call({required String email, required String senha}) {
    final e = email.trim();
    if (e.isEmpty || !e.contains('@') || !e.contains('.')) {
      throw const DomainException('E-mail inválido');
    }
    if (senha.isEmpty) throw const DomainException('Informe sua senha');
    return _repository.entrar(email: e, senha: senha);
  }
}
