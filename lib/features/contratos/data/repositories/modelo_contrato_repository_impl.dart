import '../../domain/entities/modelo_contrato.dart';
import '../../domain/repositories/modelo_contrato_repository.dart';
import '../datasources/modelos_memory_datasource.dart';

class ModeloContratoRepositoryImpl implements ModeloContratoRepository {
  const ModeloContratoRepositoryImpl(this._ds);
  final ModelosMemoryDataSource _ds;

  @override
  Stream<List<ModeloContrato>> observar() => _ds.modelos.watch();

  @override
  Future<List<ModeloContrato>> listar() async => _ds.modelos.all;

  @override
  Future<void> salvar(ModeloContrato modelo) async =>
      _ds.modelos.upsert(modelo);

  @override
  Future<void> remover(String id) async =>
      _ds.modelos.removeWhere((e) => e.id == id);
}
