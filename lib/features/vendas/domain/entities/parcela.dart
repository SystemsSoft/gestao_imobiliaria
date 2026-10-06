import 'venda_enums.dart';

/// Parcela do financiamento próprio (ou a entrada).
class Parcela {
  const Parcela({
    required this.id,
    required this.vendaId,
    required this.numero,
    required this.totalParcelas,
    required this.tipo,
    required this.vencimento,
    required this.valor,
    required this.amortizacao,
    required this.juros,
    required this.saldoDevedor,
    this.status = StatusParcela.aberta,
    this.dataPagamento,
    this.valorPago,
    this.multa = 0,
    this.jurosMora = 0,
    this.desconto = 0,
  });

  final String id;
  final String vendaId;
  final int numero;
  final int totalParcelas;
  final TipoParcela tipo;
  final DateTime vencimento;
  final double valor;

  /// Parte do valor que abate o saldo devedor.
  final double amortizacao;

  /// Juros do financiamento embutidos na parcela.
  final double juros;

  /// Saldo devedor após esta parcela.
  final double saldoDevedor;
  final StatusParcela status;
  final DateTime? dataPagamento;
  final double? valorPago;
  final double multa;
  final double jurosMora;
  final double desconto;

  String get rotulo =>
      tipo == TipoParcela.entrada ? 'Entrada' : '$numero/$totalParcelas';

  bool atrasada(DateTime hoje) =>
      status == StatusParcela.aberta &&
      DateTime(hoje.year, hoje.month, hoje.day).isAfter(vencimento);

  Parcela pagar({
    required DateTime data,
    required double valorPago,
    required double multa,
    required double jurosMora,
    required double desconto,
  }) => _copy(
    status: StatusParcela.paga,
    dataPagamento: data,
    valorPago: valorPago,
    multa: multa,
    jurosMora: jurosMora,
    desconto: desconto,
  );

  Parcela estornar() => _copy(status: StatusParcela.aberta);

  Parcela _copy({
    required StatusParcela status,
    DateTime? dataPagamento,
    double? valorPago,
    double multa = 0,
    double jurosMora = 0,
    double desconto = 0,
  }) => Parcela(
    id: id,
    vendaId: vendaId,
    numero: numero,
    totalParcelas: totalParcelas,
    tipo: tipo,
    vencimento: vencimento,
    valor: valor,
    amortizacao: amortizacao,
    juros: juros,
    saldoDevedor: saldoDevedor,
    status: status,
    dataPagamento: dataPagamento,
    valorPago: valorPago,
    multa: multa,
    jurosMora: jurosMora,
    desconto: desconto,
  );
}
