import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/reserva.dart';

/// Reservas em memória, até existir um backend.
class TemporadaMemoryDataSource {
  final reservas = MemoryCollection<Reserva>((e) => e.id);
  int seqReserva = 0;
}
