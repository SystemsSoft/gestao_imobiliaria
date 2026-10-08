/// Indicador principal com a variação em relação ao mês anterior.
class Indicador {
  const Indicador({required this.valor, required this.variacaoPercentual});

  final int valor;
  final double variacaoPercentual;
}

enum PeriodoDesempenho {
  semana('Últimos 7 dias'),
  mes('Últimos 30 dias'),
  ano('Últimos 12 meses');

  const PeriodoDesempenho(this.label);
  final String label;
}

class PontoDesempenho {
  const PontoDesempenho({
    required this.rotulo,
    required this.vendas,
    required this.locacoes,
  });

  final String rotulo;
  final int vendas;
  final int locacoes;

  int get total => vendas + locacoes;
}

class FunilConversao {
  const FunilConversao({
    required this.taxa,
    required this.variacao,
    required this.leads,
    required this.visitas,
    required this.propostas,
    required this.negociacoes,
  });

  /// Percentual de leads que viraram negócio.
  final double taxa;

  /// Variação em pontos percentuais.
  final double variacao;
  final int leads;
  final int visitas;
  final int propostas;
  final int negociacoes;
}

enum TipoCompromisso { visita, reuniao, assinatura }

class Compromisso {
  const Compromisso({
    required this.quando,
    required this.titulo,
    required this.detalhe,
    required this.tipo,
  });

  final DateTime quando;
  final String titulo;
  final String detalhe;
  final TipoCompromisso tipo;
}

enum FinalidadeImovelRecente { venda, locacao }

class ImovelRecente {
  const ImovelRecente({
    required this.titulo,
    required this.caracteristicas,
    required this.finalidade,
    required this.preco,
    required this.cadastradoEm,
    required this.casa,
  });

  final String titulo;
  final String caracteristicas;
  final FinalidadeImovelRecente finalidade;

  /// Preço já formatado (ex.: "R$ 5.200/mês").
  final String preco;
  final DateTime cadastradoEm;

  /// Casa (verdadeiro) ou apartamento/sala, para a ilustração.
  final bool casa;
}

class ItemFinanceiro {
  const ItemFinanceiro({
    required this.rotulo,
    required this.valor,
    required this.percentual,
    required this.despesa,
  });

  final String rotulo;
  final double valor;
  final double percentual;
  final bool despesa;
}

class ResumoFinanceiroMes {
  const ResumoFinanceiroMes({
    required this.receitas,
    required this.variacaoPercentual,
    required this.evolucao,
    required this.itens,
  });

  final double receitas;
  final double variacaoPercentual;

  /// Receita acumulada ao longo do mês, para o gráfico.
  final List<double> evolucao;
  final List<ItemFinanceiro> itens;
}

enum TipoAtividadeRecente { cliente, imovel, contrato, pagamento, proposta }

class AtividadeRecente {
  const AtividadeRecente({
    required this.titulo,
    required this.detalhe,
    required this.quando,
    required this.tipo,
  });

  final String titulo;
  final String detalhe;
  final DateTime quando;
  final TipoAtividadeRecente tipo;
}

/// Contadores dos painéis "Operação" e "CRM".
class ContadoresPainel {
  const ContadoresPainel({
    required this.contratosVencendo,
    required this.boletosEmAtraso,
    required this.reservasProximas,
    required this.repassesPendentes,
    required this.novosLeads,
    required this.visitasAgendadas,
    required this.negociacoesAtivas,
    required this.oportunidades,
  });

  final int contratosVencendo;
  final int boletosEmAtraso;
  final int reservasProximas;
  final int repassesPendentes;
  final int novosLeads;
  final int visitasAgendadas;
  final int negociacoesAtivas;
  final int oportunidades;
}

class DashboardResumo {
  const DashboardResumo({
    required this.imoveis,
    required this.clientes,
    required this.vendasMes,
    required this.locacoesAtivas,
    required this.desempenho,
    required this.conversao,
    required this.compromissos,
    required this.imoveisRecentes,
    required this.financeiro,
    required this.atividades,
    required this.contadores,
  });

  final Indicador imoveis;
  final Indicador clientes;
  final Indicador vendasMes;
  final Indicador locacoesAtivas;
  final List<PontoDesempenho> desempenho;
  final FunilConversao conversao;
  final List<Compromisso> compromissos;
  final List<ImovelRecente> imoveisRecentes;
  final ResumoFinanceiroMes financeiro;
  final List<AtividadeRecente> atividades;
  final ContadoresPainel contadores;
}
