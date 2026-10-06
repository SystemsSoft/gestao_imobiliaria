import '../entities/cobranca.dart';

abstract interface class CobrancaRepository {
  Stream<List<Cobranca>> observar();
  Future<List<Cobranca>> listar();
  Future<void> salvar(Cobranca cobranca);
  Future<void> remover(String id);
  Future<void> removerDoContrato(String contratoId);
}
