import '../entities/venda.dart';

abstract interface class VendaRepository {
  Stream<List<Venda>> observar();
  Future<List<Venda>> listar();
  Future<Venda?> obter(String id);

  /// Grava e devolve a venda; vendas novas (número vazio) recebem o próximo
  /// número sequencial (ex.: VEN-0001) de quem grava.
  Future<Venda> salvar(Venda venda);
  Future<void> remover(String id);
}
