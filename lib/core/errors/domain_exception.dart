/// Erro de regra de negócio, com mensagem pronta para o usuário.
class DomainException implements Exception {
  const DomainException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
