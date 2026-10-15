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

class Sair {
  const Sair(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.sair();
}

class AlterarSenha {
  const AlterarSenha(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    required String atual,
    required String nova,
    required String confirmacao,
  }) {
    if (atual.isEmpty) throw const DomainException('Informe a senha atual.');
    if (nova.length < 8) {
      throw const DomainException(
        'A nova senha precisa de ao menos 8 caracteres.',
      );
    }
    if (nova != confirmacao) {
      throw const DomainException(
        'A confirmação não confere com a nova senha.',
      );
    }
    return _repository.alterarSenha(atual: atual, nova: nova);
  }
}
