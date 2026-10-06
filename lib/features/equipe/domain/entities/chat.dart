/// Id da conversa com todos os usuários.
const conversaGeral = 'geral';

/// Id da conversa direta entre dois usuários (independe da ordem).
String conversaDireta(String a, String b) {
  final ids = [a, b]..sort();
  return 'dm:${ids[0]}:${ids[1]}';
}

class Mensagem {
  const Mensagem({
    required this.id,
    required this.conversaId,
    required this.remetenteId,
    required this.texto,
    required this.enviadaEm,
    this.lidaPor = const {},
  });

  final String id;
  final String conversaId;
  final String remetenteId;
  final String texto;
  final DateTime enviadaEm;

  /// Usuários que já leram (o remetente conta como leitor).
  final Set<String> lidaPor;

  bool lidaPorUsuario(String id) => remetenteId == id || lidaPor.contains(id);

  Mensagem comLeitor(String id) => Mensagem(
    id: this.id,
    conversaId: conversaId,
    remetenteId: remetenteId,
    texto: texto,
    enviadaEm: enviadaEm,
    lidaPor: {...lidaPor, id},
  );
}
