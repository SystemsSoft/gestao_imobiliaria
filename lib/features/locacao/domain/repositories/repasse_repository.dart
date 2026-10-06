/// Controle dos repasses já pagos aos beneficiários.
abstract interface class RepasseRepository {
  /// Chave "cobrancaId|contatoId" → data do repasse.
  Stream<Map<String, DateTime>> observarRealizados();
  Future<void> marcar(String cobrancaId, String contatoId, DateTime? data);
}

String chaveRepasse(String cobrancaId, String contatoId) =>
    '$cobrancaId|$contatoId';
