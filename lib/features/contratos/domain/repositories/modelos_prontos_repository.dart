import '../entities/modelo_pronto.dart';

abstract interface class ModelosProntosRepository {
  Future<List<ModeloPronto>> listar();
  Future<ModeloPronto?> obter(String id);
}
