import 'locacao_enums.dart';

class ItemCobranca {
  const ItemCobranca({
    required this.descricao,
    required this.valor,
    this.tipo = TipoItemCobranca.outro,
  });

  final String descricao;
  final double valor;
  final TipoItemCobranca tipo;
}

/// Cobrança mensal do locatário (base do boleto e do recibo).
class Cobranca {
  const Cobranca({
    required this.id,
    required this.contratoId,
    required this.competencia,
    required this.vencimento,
    required this.itens,
    this.status = StatusCobranca.aberta,
    this.dataPagamento,
    this.valorPago,
    this.multa = 0,
    this.juros = 0,
    this.desconto = 0,
  });

  final String id;
  final String contratoId;
  final DateTime competencia;
  final DateTime vencimento;
  final List<ItemCobranca> itens;
  final StatusCobranca status;
  final DateTime? dataPagamento;
  final double? valorPago;
  final double multa;
  final double juros;
  final double desconto;

  double get total => arredondar(itens.fold(0, (s, i) => s + i.valor));

  double get valorAluguel => itens
      .where((i) => i.tipo == TipoItemCobranca.aluguel)
      .fold(0, (s, i) => s + i.valor);

  bool atrasada(DateTime hoje) =>
      status == StatusCobranca.aberta &&
      DateTime(hoje.year, hoje.month, hoje.day).isAfter(vencimento);

  Cobranca copyWith({
    List<ItemCobranca>? itens,
    StatusCobranca? status,
    DateTime? dataPagamento,
    double? valorPago,
    double? multa,
    double? juros,
    double? desconto,
    bool limparPagamento = false,
  }) => Cobranca(
    id: id,
    contratoId: contratoId,
    competencia: competencia,
    vencimento: vencimento,
    itens: itens ?? this.itens,
    status: status ?? this.status,
    dataPagamento: limparPagamento
        ? null
        : (dataPagamento ?? this.dataPagamento),
    valorPago: limparPagamento ? null : (valorPago ?? this.valorPago),
    multa: limparPagamento ? 0 : (multa ?? this.multa),
    juros: limparPagamento ? 0 : (juros ?? this.juros),
    desconto: limparPagamento ? 0 : (desconto ?? this.desconto),
  );
}
