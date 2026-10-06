import 'financeiro_enums.dart';

/// Conta a pagar ou a receber.
class Lancamento {
  Lancamento({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required DateTime vencimento,
    this.categoria = '',
    this.contatoId,
    this.documento = '',
    this.observacoes = '',
    this.multaPercentual = 0,
    this.jurosMesPercentual = 0,
    this.indice = IndiceMonetario.nenhum,
    this.status = StatusLancamento.aberto,
    this.parcelaNumero = 1,
    this.parcelaTotal = 1,
    this.grupoId,
    this.dataBaixa,
    this.valorBaixa,
    this.multa = 0,
    this.juros = 0,
    this.correcao = 0,
    this.desconto = 0,
    this.meio,
    this.contaBaixaId,
  }) : vencimento = soData(vencimento);

  final String id;
  final TipoLancamento tipo;
  final String descricao;
  final String categoria;

  /// Cliente ou fornecedor.
  final String? contatoId;
  final String documento;
  final String observacoes;
  final double valor;
  final DateTime vencimento;

  final double multaPercentual;
  final double jurosMesPercentual;
  final IndiceMonetario indice;

  final StatusLancamento status;
  final int parcelaNumero;
  final int parcelaTotal;
  final String? grupoId;

  final DateTime? dataBaixa;
  final double? valorBaixa;
  final double multa;
  final double juros;
  final double correcao;
  final double desconto;
  final MeioPagamento? meio;
  final String? contaBaixaId;

  bool get baixado => status == StatusLancamento.baixado;
  bool get emAberto => status == StatusLancamento.aberto;

  /// Valor com sinal: positivo para receita, negativo para despesa.
  double get valorComSinal => tipo.sinal * valor;
  double get baixaComSinal => tipo.sinal * (valorBaixa ?? 0);

  bool vencido(DateTime hoje) => emAberto && soData(hoje).isAfter(vencimento);

  String get rotuloParcela =>
      parcelaTotal > 1 ? '$parcelaNumero/$parcelaTotal' : '';

  Lancamento copyWith({
    String? id,
    DateTime? vencimento,
    int? parcelaNumero,
    int? parcelaTotal,
    String? grupoId,
    StatusLancamento? status,
    DateTime? dataBaixa,
    double? valorBaixa,
    double? multa,
    double? juros,
    double? correcao,
    double? desconto,
    MeioPagamento? meio,
    String? contaBaixaId,
    bool limparBaixa = false,
  }) => Lancamento(
    id: id ?? this.id,
    tipo: tipo,
    descricao: descricao,
    valor: valor,
    vencimento: vencimento ?? this.vencimento,
    categoria: categoria,
    contatoId: contatoId,
    documento: documento,
    observacoes: observacoes,
    multaPercentual: multaPercentual,
    jurosMesPercentual: jurosMesPercentual,
    indice: indice,
    status: status ?? this.status,
    parcelaNumero: parcelaNumero ?? this.parcelaNumero,
    parcelaTotal: parcelaTotal ?? this.parcelaTotal,
    grupoId: grupoId ?? this.grupoId,
    dataBaixa: limparBaixa ? null : (dataBaixa ?? this.dataBaixa),
    valorBaixa: limparBaixa ? null : (valorBaixa ?? this.valorBaixa),
    multa: limparBaixa ? 0 : (multa ?? this.multa),
    juros: limparBaixa ? 0 : (juros ?? this.juros),
    correcao: limparBaixa ? 0 : (correcao ?? this.correcao),
    desconto: limparBaixa ? 0 : (desconto ?? this.desconto),
    meio: limparBaixa ? null : (meio ?? this.meio),
    contaBaixaId: limparBaixa ? null : (contaBaixaId ?? this.contaBaixaId),
  );
}
