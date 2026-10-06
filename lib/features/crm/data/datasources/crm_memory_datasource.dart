import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/evento.dart';
import '../../domain/entities/imovel.dart';

/// Armazenamento em memória do CRM. Os dados se perdem ao recarregar o app;
/// será substituído por uma fonte remota quando houver backend.
class CrmMemoryDataSource {
  final imoveis = MemoryCollection<Imovel>((e) => e.id);
  final contatos = MemoryCollection<Contato>((e) => e.id);
  final eventos = MemoryCollection<Evento>((e) => e.id);
  int seqCodigoImovel = 0;
}
