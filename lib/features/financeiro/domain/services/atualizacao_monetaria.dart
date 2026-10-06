import '../../../../core/domain/encargos.dart';
import '../entities/financeiro_enums.dart';
import '../entities/indice_mensal.dart';
import '../entities/lancamento.dart';

class VariacaoAcumulada {
  const VariacaoAcumulada({
    required this.percentual,
    required this.mesesSemIndice,
  });

  /// Variação composta do período, em %.
  final double percentual;

  /// Meses do período sem índice cadastrado (contam como 0%).
  final List<DateTime> mesesSemIndice;
}

/// Atualização monetária por índice, juros e multa de contas em atraso.
class AtualizacaoMonetaria {
  const AtualizacaoMonetaria();

  /// Variação composta do índice entre o mês do vencimento e o mês anterior
  /// ao do pagamento (os índices são divulgados depois do fim do mês).
  VariacaoAcumulada acumulado(
    List<IndiceMensal> indices,
    IndiceMonetario indice,
    DateTime vencimento,
    DateTime pagamento,
  ) {
    if (indice == IndiceMonetario.nenhum) {
      return const VariacaoAcumulada(percentual: 0, mesesSemIndice: []);
    }
    var fator = 1.0;
    final faltando = <DateTime>[];
    var m = DateTime(vencimento.year, vencimento.month);
    final limite = DateTime(pagamento.year, pagamento.month);
    while (m.isBefore(limite)) {
      final i = indices
          .where(
            (x) => x.indice == indice && x.ano == m.year && x.mes == m.month,
          )
          .firstOrNull;
      if (i == null) {
        faltando.add(m);
      } else {
        fator *= 1 + i.percentual / 100;
      }
      m = DateTime(m.year, m.month + 1);
    }
    return VariacaoAcumulada(
      percentual: (fator - 1) * 100,
      mesesSemIndice: faltando,
    );
  }

  /// Multa e juros incidem sobre o valor já atualizado.
  ({Encargos encargos, VariacaoAcumulada variacao}) calcular(
    Lancamento l,
    DateTime pagamento,
    List<IndiceMensal> indices,
  ) {
    final pg = soData(pagamento);
    if (!pg.isAfter(l.vencimento)) {
      return (
        encargos: const Encargos(),
        variacao: const VariacaoAcumulada(percentual: 0, mesesSemIndice: []),
      );
    }
    final variacao = acumulado(indices, l.indice, l.vencimento, pg);
    final correcao = arredondar(l.valor * variacao.percentual / 100);
    final e = calcularEncargos(
      valor: l.valor + correcao,
      vencimento: l.vencimento,
      pagamento: pg,
      multaPercentual: l.multaPercentual,
      jurosMesPercentual: l.jurosMesPercentual,
    );
    return (
      encargos: Encargos(
        multa: e.multa,
        juros: e.juros,
        correcao: correcao,
        diasAtraso: e.diasAtraso,
      ),
      variacao: variacao,
    );
  }
}
