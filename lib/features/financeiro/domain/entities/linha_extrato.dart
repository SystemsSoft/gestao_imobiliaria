import 'financeiro_enums.dart';

/// Lançamento do extrato bancário. [valor] é positivo para crédito e
/// negativo para débito.
class LinhaExtrato {
  LinhaExtrato({
    required this.id,
    required this.contaId,
    required DateTime data,
    required this.descricao,
    required this.valor,
    this.documento = '',
    this.lancamentoId,
  }) : data = soData(data);

  final String id;
  final String contaId;
  final DateTime data;
  final String descricao;
  final double valor;
  final String documento;

  /// Lançamento financeiro conciliado com esta linha.
  final String? lancamentoId;

  bool get conciliada => lancamentoId != null;

  LinhaExtrato comLancamento(String? lancamentoId) => LinhaExtrato(
    id: id,
    contaId: contaId,
    data: data,
    descricao: descricao,
    valor: valor,
    documento: documento,
    lancamentoId: lancamentoId,
  );
}
