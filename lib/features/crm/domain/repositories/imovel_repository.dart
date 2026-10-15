import '../entities/imovel.dart';

abstract interface class ImovelRepository {
  Stream<List<Imovel>> observar();
  Future<List<Imovel>> listar();
  Future<Imovel?> obter(String id);

  /// Grava e devolve o imóvel salvo; imóveis novos (código vazio) recebem
  /// o próximo código sequencial (ex.: IM-0001) de quem grava.
  Future<Imovel> salvar(Imovel imovel);
  Future<void> remover(String id);
}
