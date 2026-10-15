import '../entities/parcela.dart';

abstract interface class ParcelaRepository {
  Stream<List<Parcela>> observar();
  Future<List<Parcela>> listar();
  Future<List<Parcela>> daVenda(String vendaId);
  Future<void> salvar(Parcela parcela);
  Future<void> salvarTodas(List<Parcela> parcelas);
  Future<void> removerDaVenda(String vendaId);
}
