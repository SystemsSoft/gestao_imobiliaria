import '../entities/comissao_equipe.dart';
import '../entities/equipe_enums.dart';

/// Totais de comissão por corretor em um mês de competência.
class ResumoComissoesService {
  const ResumoComissoesService();

  List<ResumoCorretor> calcular({
    required List<LancamentoComissao> lancamentos,
    required List<RegraComissao> regras,
    required DateTime competencia,
    required Iterable<String> usuarios,
  }) {
    final mes = DateTime(competencia.year, competencia.month);
    final lista = <ResumoCorretor>[];
    for (final u in usuarios) {
      double soma(StatusComissao s) => lancamentos
          .where(
            (l) => l.usuarioId == u && l.status == s && l.competencia == mes,
          )
          .fold(0, (a, l) => a + l.valor);
      final meta =
          regras.where((r) => r.usuarioId == u).firstOrNull?.metaMensal ?? 0;
      final r = ResumoCorretor(
        usuarioId: u,
        aprovar: arredondar(soma(StatusComissao.pendente)),
        pagar: arredondar(soma(StatusComissao.aprovada)),
        pago: arredondar(soma(StatusComissao.paga)),
        meta: meta,
      );
      if (r.total != 0 || meta > 0) lista.add(r);
    }
    return lista..sort((a, b) => b.total.compareTo(a.total));
  }
}
