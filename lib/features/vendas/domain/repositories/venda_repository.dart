import '../entities/venda.dart';

abstract interface class VendaRepository {
  Stream<List<Venda>> observar();
  Future<List<Venda>> listar();
  Future<Venda?> obter(String id);
  Future<void> salvar(Venda venda);
  Future<void> remover(String id);

  /// Próximo número sequencial (ex.: VEN-0001).
  Future<String> proximoNumero();
}
