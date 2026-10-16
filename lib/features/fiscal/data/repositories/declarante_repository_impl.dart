import '../../domain/entities/declarante_dimob.dart';
import '../../domain/repositories/declarante_repository.dart';
import '../datasources/fiscal_memory_datasource.dart';

class DeclaranteRepositoryImpl implements DeclaranteRepository {
  const DeclaranteRepositoryImpl(this._ds);
  final FiscalMemoryDataSource _ds;

  @override
  Stream<DeclaranteDimob> observar() =>
      _ds.declarante.watch().map((l) => l.firstOrNull ?? DeclaranteDimob());

  @override
  Future<DeclaranteDimob> obter() async =>
      _ds.declarante.all.firstOrNull ?? DeclaranteDimob();

  @override
  Future<void> salvar(DeclaranteDimob declarante) async =>
      _ds.declarante.upsert(declarante);
}
