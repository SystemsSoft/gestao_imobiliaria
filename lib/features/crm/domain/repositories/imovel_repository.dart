import '../entities/imovel.dart';

abstract interface class ImovelRepository {
  Stream<List<Imovel>> observar();
  Future<List<Imovel>> listar();
  Future<Imovel?> obter(String id);
  Future<void> salvar(Imovel imovel);
  Future<void> remover(String id);

  /// Próximo código sequencial de exibição (ex.: IM-0001).
  Future<String> proximoCodigo();
}
