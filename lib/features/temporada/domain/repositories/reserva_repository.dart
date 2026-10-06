import '../entities/reserva.dart';

abstract interface class ReservaRepository {
  Stream<List<Reserva>> observar();
  Future<List<Reserva>> listar();
  Future<Reserva?> obter(String id);
  Future<void> salvar(Reserva reserva);
  Future<void> remover(String id);

  /// Próximo número sequencial (ex.: RES-0001).
  Future<String> proximoNumero();
}
