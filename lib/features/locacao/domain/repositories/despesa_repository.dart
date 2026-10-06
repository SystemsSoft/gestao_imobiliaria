import '../entities/despesa.dart';

abstract interface class DespesaRepository {
  Stream<List<Despesa>> observar();
  Future<List<Despesa>> listar();
  Future<void> salvar(Despesa despesa);
  Future<void> remover(String id);
  Future<void> removerDoContrato(String contratoId);
}
