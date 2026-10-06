import '../../domain/entities/reserva.dart';
import '../../domain/repositories/reserva_repository.dart';
import '../datasources/temporada_memory_datasource.dart';

class ReservaRepositoryImpl implements ReservaRepository {
  const ReservaRepositoryImpl(this._ds);
  final TemporadaMemoryDataSource _ds;

  @override
  Stream<List<Reserva>> observar() => _ds.reservas.watch();

  @override
  Future<List<Reserva>> listar() async => _ds.reservas.all;

  @override
  Future<Reserva?> obter(String id) async => _ds.reservas.byId(id);

  @override
  Future<void> salvar(Reserva reserva) async => _ds.reservas.upsert(reserva);

  @override
  Future<void> remover(String id) async =>
      _ds.reservas.removeWhere((e) => e.id == id);

  @override
  Future<String> proximoNumero() async {
    _ds.seqReserva++;
    return 'RES-${_ds.seqReserva.toString().padLeft(4, '0')}';
  }
}
