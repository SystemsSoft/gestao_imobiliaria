import '../entities/modelo_contrato.dart';

abstract interface class ModeloContratoRepository {
  Stream<List<ModeloContrato>> observar();
  Future<List<ModeloContrato>> listar();
  Future<void> salvar(ModeloContrato modelo);
  Future<void> remover(String id);
}
