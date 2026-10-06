import 'equipe_enums.dart';

/// Posição de um corretor na fila de atendimento (a ordem é a da lista).
class ItemFila {
  const ItemFila({
    required this.usuarioId,
    required this.status,
    required this.desde,
  });

  final String usuarioId;
  final StatusFila status;

  /// Quando entrou no status atual.
  final DateTime desde;

  ItemFila comStatus(StatusFila s, DateTime agora) =>
      ItemFila(usuarioId: usuarioId, status: s, desde: agora);
}

/// Atendimento a um cliente, distribuído pela fila.
class Atendimento {
  const Atendimento({
    required this.id,
    required this.corretorId,
    required this.clienteNome,
    required this.origem,
    required this.iniciadoEm,
    this.contatoId,
    this.observacao = '',
    this.finalizadoEm,
  });

  final String id;
  final String corretorId;
  final String clienteNome;
  final OrigemAtendimento origem;
  final DateTime iniciadoEm;

  /// Contato do CRM, quando o cliente já é cadastrado.
  final String? contatoId;
  final String observacao;
  final DateTime? finalizadoEm;

  bool get emAndamento => finalizadoEm == null;

  Duration? get duracao => finalizadoEm?.difference(iniciadoEm);

  Atendimento finalizar(DateTime quando, String obs) => Atendimento(
    id: id,
    corretorId: corretorId,
    clienteNome: clienteNome,
    origem: origem,
    iniciadoEm: iniciadoEm,
    contatoId: contatoId,
    observacao: obs.isEmpty ? observacao : obs,
    finalizadoEm: quando,
  );
}
