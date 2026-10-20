class ContaBancaria {
  const ContaBancaria({
    required this.id,
    required this.nome,
    this.banco = '',
    this.agencia = '',
    this.conta = '',
    this.saldoInicial = 0,
    this.convenio = '',
    this.carteira = '',
    this.linkInternetBanking = '',
  });

  final String id;

  /// Apelido exibido nas telas (ex.: "Itaú Empresa").
  final String nome;
  final String banco;
  final String agencia;
  final String conta;
  final double saldoInicial;

  /// Dados da cobrança bancária, usados na emissão de boletos.
  final String convenio;
  final String carteira;

  /// Link do internet banking, aberto pelo botão "Abrir banco" do Financeiro.
  final String linkInternetBanking;

  String get descricao => [
    nome,
    if (banco.isNotEmpty) banco,
    if (agencia.isNotEmpty || conta.isNotEmpty)
      'Ag. $agencia C/C $conta'.trim(),
  ].join(' • ');
}
