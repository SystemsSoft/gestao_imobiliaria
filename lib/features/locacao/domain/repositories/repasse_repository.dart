/// Controle dos repasses já pagos aos beneficiários.
abstract interface class RepasseRepository {
  /// Chave "cobrancaId|contatoId" → data do repasse.
  Stream<Map<String, DateTime>> observarRealizados();

  /// Leitura única dos repasses feitos (mesma chave de [observarRealizados]).
  Future<Map<String, DateTime>> realizados();
  Future<void> marcar(String cobrancaId, String contatoId, DateTime? data);
}

String chaveRepasse(String cobrancaId, String contatoId) =>
    '$cobrancaId|$contatoId';
