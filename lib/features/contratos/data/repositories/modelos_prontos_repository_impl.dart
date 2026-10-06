import '../../domain/entities/modelo_pronto.dart';
import '../../domain/repositories/modelos_prontos_repository.dart';
import '../datasources/catalogo_modelos_prontos.dart';

class ModelosProntosRepositoryImpl implements ModelosProntosRepository {
  const ModelosProntosRepositoryImpl();

  @override
  Future<List<ModeloPronto>> listar() async => catalogoModelosProntos;

  @override
  Future<ModeloPronto?> obter(String id) async =>
      catalogoModelosProntos.where((m) => m.id == id).firstOrNull;
}
