import 'equipe_enums.dart';
import 'permissoes.dart';

/// Usuário que acessa o sistema (distinto do cadastro de contatos do CRM).
class UsuarioSistema {
  const UsuarioSistema({
    required this.id,
    required this.nome,
    required this.login,
    this.email = '',
    required this.perfil,
    required this.permissoes,
    required this.criadoEm,
    this.ativo = true,
    this.telefone = '',
    this.creci = '',
    this.atendeNaFila = false,
  });

  final String id;
  final String nome;

  /// Nome de usuário para entrar (ex.: "Marcelo").
  final String login;

  /// Contato (opcional).
  final String email;
  final PerfilAcesso perfil;
  final Permissoes permissoes;
  final DateTime criadoEm;
  final bool ativo;
  final String telefone;
  final String creci;

  /// Participa da fila de atendimento dos corretores.
  final bool atendeNaFila;

  bool get administrador =>
      permissoes.temEspecial(PermissaoEspecial.gerenciarUsuarios);

  String get iniciais {
    final p = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (p.isEmpty) return '?';
    return (p.first[0] + (p.length > 1 ? p.last[0] : '')).toUpperCase();
  }

  UsuarioSistema copyWith({
    String? nome,
    String? login,
    String? email,
    PerfilAcesso? perfil,
    Permissoes? permissoes,
    bool? ativo,
    String? telefone,
    String? creci,
    bool? atendeNaFila,
  }) => UsuarioSistema(
    id: id,
    nome: nome ?? this.nome,
    login: login ?? this.login,
    email: email ?? this.email,
    perfil: perfil ?? this.perfil,
    permissoes: permissoes ?? this.permissoes,
    criadoEm: criadoEm,
    ativo: ativo ?? this.ativo,
    telefone: telefone ?? this.telefone,
    creci: creci ?? this.creci,
    atendeNaFila: atendeNaFila ?? this.atendeNaFila,
  );
}
