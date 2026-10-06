import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/parcela.dart';
import '../../domain/entities/venda.dart';

/// Armazenamento em memória das vendas, até existir um backend.
class VendasMemoryDataSource {
  final vendas = MemoryCollection<Venda>((e) => e.id);
  final parcelas = MemoryCollection<Parcela>((e) => e.id);
  int seqVenda = 0;
}
