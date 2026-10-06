import '../entities/evento.dart';

abstract interface class EventoRepository {
  Stream<List<Evento>> observar();
  Future<List<Evento>> listar();
  Future<void> salvar(Evento evento);
  Future<void> remover(String id);
}
