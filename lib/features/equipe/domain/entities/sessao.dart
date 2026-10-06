/// Conexão de um usuário ao sistema.
class SessaoUsuario {
  const SessaoUsuario({
    required this.id,
    required this.usuarioId,
    required this.inicio,
    required this.ultimaAtividade,
    this.dispositivo = '',
  });

  final String id;
  final String usuarioId;
  final DateTime inicio;
  final DateTime ultimaAtividade;
  final String dispositivo;

  SessaoUsuario copyWith({DateTime? ultimaAtividade}) => SessaoUsuario(
    id: id,
    usuarioId: usuarioId,
    inicio: inicio,
    ultimaAtividade: ultimaAtividade ?? this.ultimaAtividade,
    dispositivo: dispositivo,
  );
}

class ConfiguracaoSeguranca {
  const ConfiguracaoSeguranca({
    this.limiteSessoes = 5,
    this.inatividadeMinutos = 30,
  });

  /// Usuários que podem estar conectados ao mesmo tempo (licenças).
  final int limiteSessoes;

  /// Sessões sem atividade por este tempo deixam de contar como conectadas.
  final int inatividadeMinutos;
}
