import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/manutencao.dart';
import '../../domain/repositories/manutencao_repository.dart';

class ManutencaoMemoryRepository implements ManutencaoRepository {
  final _itens = MemoryCollection<Manutencao>((m) => m.id);

  @override
  Stream<List<Manutencao>> observar() => _itens.watch();

  @override
  Manutencao? porId(String id) => _itens.byId(id);

  @override
  Future<void> salvar(Manutencao m) async => _itens.upsert(m);

  @override
  Future<void> remover(String id) async =>
      _itens.removeWhere((m) => m.id == id);
}
