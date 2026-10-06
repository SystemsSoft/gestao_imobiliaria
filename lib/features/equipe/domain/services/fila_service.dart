import '../entities/equipe_enums.dart';
import '../entities/fila.dart';

/// Regras da fila de atendimento: quem é o próximo, e como a fila anda.
class FilaService {
  const FilaService();

  /// Primeiro corretor disponível, na ordem da fila.
  ItemFila? proximo(List<ItemFila> fila) =>
      fila.where((i) => i.status == StatusFila.disponivel).firstOrNull;

  List<ItemFila> entrar(List<ItemFila> fila, String usuarioId, DateTime agora) {
    if (fila.any((i) => i.usuarioId == usuarioId)) return fila;
    return [
      ...fila,
      ItemFila(
        usuarioId: usuarioId,
        status: StatusFila.disponivel,
        desde: agora,
      ),
    ];
  }

  List<ItemFila> sair(List<ItemFila> fila, String usuarioId) =>
      fila.where((i) => i.usuarioId != usuarioId).toList();

  /// Muda o status. Ao voltar de ausente, vai para o fim da fila.
  List<ItemFila> mudarStatus(
    List<ItemFila> fila,
    String usuarioId,
    StatusFila status,
    DateTime agora,
  ) {
    final i = fila.indexWhere((x) => x.usuarioId == usuarioId);
    if (i < 0) return fila;
    final item = fila[i].comStatus(status, agora);
    final voltando =
        fila[i].status == StatusFila.ausente && status == StatusFila.disponivel;
    final nova = [...fila]..removeAt(i);
    voltando ? nova.add(item) : nova.insert(i, item);
    return nova;
  }

  /// Passa a vez: vai para o fim da fila, sem atender.
  List<ItemFila> pular(List<ItemFila> fila, String usuarioId, DateTime agora) {
    final i = fila.indexWhere((x) => x.usuarioId == usuarioId);
    if (i < 0) return fila;
    final nova = [...fila]..removeAt(i);
    return [...nova, fila[i].comStatus(fila[i].status, agora)];
  }

  /// Sobe ([delta] = -1) ou desce ([delta] = 1) um corretor na fila.
  List<ItemFila> mover(List<ItemFila> fila, String usuarioId, int delta) {
    final i = fila.indexWhere((x) => x.usuarioId == usuarioId);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= fila.length) return fila;
    final nova = [...fila];
    final item = nova.removeAt(i);
    nova.insert(j, item);
    return nova;
  }

  /// Chama o próximo: fica em atendimento e vai para o fim da fila.
  ({List<ItemFila> fila, ItemFila? chamado}) chamarProximo(
    List<ItemFila> fila,
    DateTime agora,
  ) {
    final p = proximo(fila);
    if (p == null) return (fila: fila, chamado: null);
    final nova = fila.where((i) => i.usuarioId != p.usuarioId).toList();
    final chamado = p.comStatus(StatusFila.emAtendimento, agora);
    return (fila: [...nova, chamado], chamado: chamado);
  }
}
