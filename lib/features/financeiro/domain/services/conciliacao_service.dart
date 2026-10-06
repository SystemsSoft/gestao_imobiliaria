import '../entities/conta_bancaria.dart';
import '../entities/financeiro_enums.dart';
import '../entities/lancamento.dart';
import '../entities/linha_extrato.dart';

class SugestaoConciliacao {
  const SugestaoConciliacao({required this.linha, required this.lancamento});

  final LinhaExtrato linha;
  final Lancamento lancamento;
}

class SaldosConta {
  const SaldosConta({required this.contabil, required this.extrato});

  /// Saldo inicial + pagamentos e recebimentos baixados nesta conta.
  final double contabil;

  /// Saldo inicial + movimentos do extrato.
  final double extrato;

  double get diferenca => arredondar(extrato - contabil);
}

/// Regras de conciliação entre o extrato e as contas baixadas.
class ConciliacaoService {
  const ConciliacaoService({this.toleranciaDias = 3});

  /// Diferença máxima entre a data da baixa e a do extrato.
  final int toleranciaDias;

  /// Contas baixadas na conta bancária e ainda sem linha de extrato.
  List<Lancamento> candidatos(
    List<Lancamento> lancamentos,
    List<LinhaExtrato> linhas,
    String contaId,
  ) {
    final usados = {for (final l in linhas) ?l.lancamentoId};
    return lancamentos
        .where(
          (l) =>
              l.baixado &&
              l.contaBaixaId == contaId &&
              l.dataBaixa != null &&
              !usados.contains(l.id),
        )
        .toList()
      ..sort((a, b) => a.dataBaixa!.compareTo(b.dataBaixa!));
  }

  /// Casa linhas pendentes com baixas de mesmo valor e data próxima, sem
  /// usar o mesmo lançamento duas vezes.
  List<SugestaoConciliacao> sugerir(
    List<Lancamento> lancamentos,
    List<LinhaExtrato> linhas,
    String contaId,
  ) {
    final disponiveis = candidatos(lancamentos, linhas, contaId);
    final usados = <String>{};
    final sugestoes = <SugestaoConciliacao>[];
    final pendentes =
        linhas.where((l) => l.contaId == contaId && !l.conciliada).toList()
          ..sort((a, b) => a.data.compareTo(b.data));
    for (final linha in pendentes) {
      Lancamento? melhor;
      var menor = toleranciaDias + 1;
      for (final l in disponiveis) {
        if (usados.contains(l.id)) continue;
        if ((l.baixaComSinal - linha.valor).abs() > 0.005) continue;
        final dias = l.dataBaixa!.difference(linha.data).inDays.abs();
        if (dias < menor) {
          menor = dias;
          melhor = l;
        }
      }
      if (melhor != null) {
        usados.add(melhor.id);
        sugestoes.add(SugestaoConciliacao(linha: linha, lancamento: melhor));
      }
    }
    return sugestoes;
  }

  SaldosConta saldos(
    ContaBancaria conta,
    List<Lancamento> lancamentos,
    List<LinhaExtrato> linhas,
  ) {
    final contabil =
        conta.saldoInicial +
        lancamentos
            .where((l) => l.baixado && l.contaBaixaId == conta.id)
            .fold<double>(0, (s, l) => s + l.baixaComSinal);
    final extrato =
        conta.saldoInicial +
        linhas
            .where((l) => l.contaId == conta.id)
            .fold<double>(0, (s, l) => s + l.valor);
    return SaldosConta(
      contabil: arredondar(contabil),
      extrato: arredondar(extrato),
    );
  }
}
