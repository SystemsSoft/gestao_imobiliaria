/// Contrato já preenchido, pronto para impressão.
class ContratoDocumento {
  const ContratoDocumento({
    required this.titulo,
    required this.texto,
    required this.assinaturas,
  });

  final String titulo;
  final String texto;

  /// Rótulos das linhas de assinatura (ex.: "LOCADOR: Fulano").
  final List<String> assinaturas;
}
