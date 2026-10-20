import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';
import 'package:marceloimob_gestao/core/utils/formatters.dart';
import 'package:marceloimob_gestao/features/auth/domain/entities/usuario.dart';
import 'package:marceloimob_gestao/features/auth/domain/repositories/auth_repository.dart';
import 'package:marceloimob_gestao/features/auth/domain/usecases/entrar.dart';

class _RepoFalso implements AuthRepository {
  String? usuario;
  String? senha;

  @override
  Future<Usuario> entrar({
    required String usuario,
    required String senha,
  }) async {
    this.usuario = usuario;
    this.senha = senha;
    return Usuario(login: usuario);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  // O que costuma vir junto ao copiar e colar usuário e senha.
  const sujeiras = {
    'espaço': ' ',
    'quebra de linha': '\n',
    'Windows (CRLF)': '\r\n',
    'tabulação': '\t',
    'espaço sem quebra': ' ',
    'espaço de largura zero': '​',
    'BOM': '﻿',
    'marca de direção': '‎',
  };

  for (final MapEntry(key: nome, value: x) in sujeiras.entries) {
    test('login ignora $nome nas pontas', () async {
      final repo = _RepoFalso();
      await Entrar(repo)(usuario: '$x${x}admin$x', senha: '${x}senha 123$x$x');
      expect(repo.usuario, 'admin');
      expect(repo.senha, 'senha 123', reason: 'espaço no meio continua');
    });
  }

  test('senha só com espaços colados é tratada como vazia', () {
    expect(
      () => Entrar(_RepoFalso())(usuario: 'admin', senha: ' ​\n'),
      throwsA(isA<DomainException>()),
    );
  });

  test('aparar mantém o texto quando não há sobra', () {
    expect(aparar('Admin'), 'Admin');
    expect(aparar(''), '');
  });
}
