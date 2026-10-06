import '../../domain/entities/contato.dart';
import '../../domain/repositories/contato_repository.dart';
import '../datasources/crm_memory_datasource.dart';

class ContatoRepositoryImpl implements ContatoRepository {
  const ContatoRepositoryImpl(this._ds);
  final CrmMemoryDataSource _ds;

  @override
  Stream<List<Contato>> observar() => _ds.contatos.watch();

  @override
  Future<List<Contato>> listar() async => _ds.contatos.all;

  @override
  Future<Contato?> obter(String id) async => _ds.contatos.byId(id);

  @override
  Future<void> salvar(Contato contato) async => _ds.contatos.upsert(contato);

  @override
  Future<void> remover(String id) async =>
      _ds.contatos.removeWhere((e) => e.id == id);
}
