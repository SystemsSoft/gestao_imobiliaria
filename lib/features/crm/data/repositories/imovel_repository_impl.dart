import '../../domain/entities/imovel.dart';
import '../../domain/repositories/imovel_repository.dart';
import '../datasources/crm_memory_datasource.dart';

class ImovelRepositoryImpl implements ImovelRepository {
  const ImovelRepositoryImpl(this._ds);
  final CrmMemoryDataSource _ds;

  @override
  Stream<List<Imovel>> observar() => _ds.imoveis.watch();

  @override
  Future<List<Imovel>> listar() async => _ds.imoveis.all;

  @override
  Future<Imovel?> obter(String id) async => _ds.imoveis.byId(id);

  @override
  Future<Imovel> salvar(Imovel imovel) async {
    final salvo = imovel.codigo.isEmpty
        ? imovel.copyWith(
            codigo: 'IM-${(++_ds.seqCodigoImovel).toString().padLeft(4, '0')}',
            criadoEm: imovel.criadoEm ?? DateTime.now(),
          )
        : imovel;
    _ds.imoveis.upsert(salvo);
    return salvo;
  }

  @override
  Future<void> remover(String id) async =>
      _ds.imoveis.removeWhere((e) => e.id == id);
}
