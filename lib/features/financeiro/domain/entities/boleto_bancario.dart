import 'financeiro_enums.dart';

/// Boleto emitido para uma conta a receber.
class BoletoBancario {
  BoletoBancario({
    required this.id,
    required this.lancamentoId,
    required this.contaId,
    required this.nossoNumero,
    required this.valor,
    required DateTime vencimento,
    required DateTime emissao,
    this.status = StatusBoleto.emitido,
    this.dataPagamento,
    this.valorPago,
  }) : vencimento = soData(vencimento),
       emissao = soData(emissao);

  final String id;
  final String lancamentoId;
  final String contaId;
  final String nossoNumero;
  final double valor;
  final DateTime vencimento;
  final DateTime emissao;
  final StatusBoleto status;
  final DateTime? dataPagamento;
  final double? valorPago;

  bool vencido(DateTime hoje) =>
      status == StatusBoleto.emitido && soData(hoje).isAfter(vencimento);

  BoletoBancario comNossoNumero(String numero) => BoletoBancario(
    id: id,
    lancamentoId: lancamentoId,
    contaId: contaId,
    nossoNumero: numero,
    valor: valor,
    vencimento: vencimento,
    emissao: emissao,
    status: status,
    dataPagamento: dataPagamento,
    valorPago: valorPago,
  );

  BoletoBancario copyWith({
    StatusBoleto? status,
    DateTime? dataPagamento,
    double? valorPago,
  }) => BoletoBancario(
    id: id,
    lancamentoId: lancamentoId,
    contaId: contaId,
    nossoNumero: nossoNumero,
    valor: valor,
    vencimento: vencimento,
    emissao: emissao,
    status: status ?? this.status,
    dataPagamento: dataPagamento ?? this.dataPagamento,
    valorPago: valorPago ?? this.valorPago,
  );
}

/// Linha do arquivo de retorno bancário: um pagamento identificado pelo
/// nosso número.
class RetornoItem {
  const RetornoItem({
    required this.nossoNumero,
    required this.valorPago,
    required this.dataPagamento,
  });

  final String nossoNumero;
  final double valorPago;
  final DateTime dataPagamento;
}

class ResultadoRetorno {
  const ResultadoRetorno({
    this.baixados = 0,
    this.naoEncontrados = const [],
    this.ignorados = const [],
    this.linhasInvalidas = const [],
  });

  final int baixados;

  /// Nossos números sem boleto correspondente.
  final List<String> naoEncontrados;

  /// Boletos já pagos ou cancelados.
  final List<String> ignorados;
  final List<String> linhasInvalidas;

  bool get semProblemas =>
      naoEncontrados.isEmpty && ignorados.isEmpty && linhasInvalidas.isEmpty;
}
