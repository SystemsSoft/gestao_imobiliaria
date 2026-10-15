import '../entities/contrato_locacao.dart';

abstract interface class ContratoLocacaoRepository {
  Stream<List<ContratoLocacao>> observar();
  Future<List<ContratoLocacao>> listar();
  Future<ContratoLocacao?> obter(String id);

  /// Grava e devolve o contrato; contratos novos (número vazio) recebem o
  /// próximo número sequencial (ex.: LOC-0001) de quem grava.
  Future<ContratoLocacao> salvar(ContratoLocacao contrato);

  /// Remove o contrato (o servidor também apaga despesas e cobranças).
  Future<void> remover(String id);
}
