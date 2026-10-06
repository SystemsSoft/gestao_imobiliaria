import 'venda_enums.dart';

/// Participação percentual de uma pessoa. Para a comissão, [contatoId]
/// nulo representa a própria imobiliária.
class Participacao {
  const Participacao({this.contatoId, required this.percentual, this.pagaEm});

  final String? contatoId;
  final double percentual;

  /// Data em que a comissão desta participação foi paga.
  final DateTime? pagaEm;

  Participacao marcarPaga(DateTime? data) =>
      Participacao(contatoId: contatoId, percentual: percentual, pagaEm: data);
}

class PlanoFinanciamento {
  const PlanoFinanciamento({
    required this.numeroParcelas,
    required this.taxaJurosMes,
    required this.sistema,
    required this.primeiroVencimento,
  });

  final int numeroParcelas;

  /// Percentual ao mês (ex.: 1 = 1% a.m.).
  final double taxaJurosMes;
  final SistemaAmortizacao sistema;
  final DateTime primeiroVencimento;

  bool mesmoQue(PlanoFinanciamento? o) =>
      o != null &&
      o.numeroParcelas == numeroParcelas &&
      o.taxaJurosMes == taxaJurosMes &&
      o.sistema == sistema &&
      o.primeiroVencimento == primeiroVencimento;
}

class Venda {
  const Venda({
    required this.id,
    required this.numero,
    required this.imovelId,
    required this.compradores,
    required this.vendedores,
    required this.dataVenda,
    required this.valorVenda,
    this.valorEntrada = 0,
    this.vencimentoEntrada,
    this.formaPagamento = FormaPagamento.aVista,
    this.plano,
    this.credor = CredorParcelas.vendedor,
    this.multaAtraso = 2,
    this.jurosMes = 1,
    this.comissaoPercentual = 6,
    this.corretores = const [Participacao(percentual: 100)],
    this.status = StatusVenda.ativa,
    this.clausulasAdicionais = '',
    this.observacoes = '',
  });

  final String id;
  final String numero;
  final String imovelId;
  final List<String> compradores;
  final List<Participacao> vendedores;
  final DateTime dataVenda;
  final double valorVenda;
  final double valorEntrada;
  final DateTime? vencimentoEntrada;
  final FormaPagamento formaPagamento;

  /// Obrigatório no financiamento próprio.
  final PlanoFinanciamento? plano;
  final CredorParcelas credor;
  final double multaAtraso;
  final double jurosMes;

  /// Percentual de corretagem sobre o valor da venda.
  final double comissaoPercentual;

  /// Divisão da comissão (soma 100%).
  final List<Participacao> corretores;
  final StatusVenda status;
  final String clausulasAdicionais;
  final String observacoes;

  double get valorFinanciado => arredondar(valorVenda - valorEntrada);
  double get valorComissao => arredondar(valorVenda * comissaoPercentual / 100);
  bool get financiamentoProprio =>
      formaPagamento == FormaPagamento.financiamentoProprio;

  Venda copyWith({
    String? numero,
    StatusVenda? status,
    List<Participacao>? corretores,
  }) => Venda(
    id: id,
    numero: numero ?? this.numero,
    imovelId: imovelId,
    compradores: compradores,
    vendedores: vendedores,
    dataVenda: dataVenda,
    valorVenda: valorVenda,
    valorEntrada: valorEntrada,
    vencimentoEntrada: vencimentoEntrada,
    formaPagamento: formaPagamento,
    plano: plano,
    credor: credor,
    multaAtraso: multaAtraso,
    jurosMes: jurosMes,
    comissaoPercentual: comissaoPercentual,
    corretores: corretores ?? this.corretores,
    status: status ?? this.status,
    clausulasAdicionais: clausulasAdicionais,
    observacoes: observacoes,
  );
}
