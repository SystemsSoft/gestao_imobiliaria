import '../../domain/entities/evento.dart';
import '../../domain/repositories/evento_repository.dart';
import '../datasources/crm_memory_datasource.dart';

class EventoRepositoryImpl implements EventoRepository {
  const EventoRepositoryImpl(this._ds);
  final CrmMemoryDataSource _ds;

  @override
  Stream<List<Evento>> observar() => _ds.eventos.watch();

  @override
  Future<List<Evento>> listar() async => _ds.eventos.all;

  @override
  Future<void> salvar(Evento evento) async => _ds.eventos.upsert(evento);

  @override
  Future<void> remover(String id) async =>
      _ds.eventos.removeWhere((e) => e.id == id);
}
