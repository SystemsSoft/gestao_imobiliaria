import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/declarante_dimob.dart';

/// Configuração fiscal em memória, até existir um backend.
class FiscalMemoryDataSource {
  final declarante = MemoryCollection<DeclaranteDimob>((_) => 'declarante');
}
