import '../entities/manutencao.dart';

abstract interface class ManutencaoRepository {
  Stream<List<Manutencao>> observar();
  Manutencao? porId(String id);
  Future<void> salvar(Manutencao m);
  Future<void> remover(String id);
}
