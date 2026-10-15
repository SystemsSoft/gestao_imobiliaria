import '../entities/reserva.dart';

abstract interface class ReservaRepository {
  Stream<List<Reserva>> observar();
  Future<List<Reserva>> listar();
  Future<Reserva?> obter(String id);

  /// Grava e devolve a reserva; reservas novas (número vazio) recebem o
  /// próximo número sequencial (ex.: RES-0001) de quem grava.
  Future<Reserva> salvar(Reserva reserva);
  Future<void> remover(String id);
}
