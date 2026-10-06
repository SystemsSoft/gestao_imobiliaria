import '../entities/contrato_locacao.dart';

abstract interface class ContratoLocacaoRepository {
  Stream<List<ContratoLocacao>> observar();
  Future<List<ContratoLocacao>> listar();
  Future<ContratoLocacao?> obter(String id);
  Future<void> salvar(ContratoLocacao contrato);
  Future<void> remover(String id);

  /// Próximo número sequencial (ex.: LOC-0001).
  Future<String> proximoNumero();
}
