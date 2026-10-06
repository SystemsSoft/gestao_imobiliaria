import '../entities/contato.dart';

abstract interface class ContatoRepository {
  Stream<List<Contato>> observar();
  Future<List<Contato>> listar();
  Future<Contato?> obter(String id);
  Future<void> salvar(Contato contato);
  Future<void> remover(String id);
}
