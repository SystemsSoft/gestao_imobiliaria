import '../../../../core/utils/formatters.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/evento.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/sugerir_negocios.dart';
import '../../../financeiro/domain/entities/financeiro_enums.dart';
import '../../../financeiro/domain/entities/lancamento.dart';
import '../../../locacao/domain/entities/cobranca.dart';
import '../../../locacao/domain/entities/contrato_locacao.dart';
import '../../../locacao/domain/entities/locacao_enums.dart';
import '../../../locacao/domain/repositories/repasse_repository.dart';
import '../../../temporada/domain/entities/reserva.dart';
import '../../../vendas/domain/entities/parcela.dart';
import '../../../vendas/domain/entities/venda.dart';
import '../../../vendas/domain/entities/venda_enums.dart';
import '../entities/dashboard.dart';

/// Dados de todos os módulos usados no painel.
class DadosDashboard {
  const DadosDashboard({
    this.imoveis = const [],
    this.contatos = const [],
    this.eventos = const [],
    this.vendas = const [],
    this.parcelas = const [],
    this.contratos = const [],
    this.cobrancas = const [],
    this.repasses = const {},
    this.reservas = const [],
    this.lancamentos = const [],
  });

  final List<Imovel> imoveis;
  final List<Contato> contatos;
  final List<Evento> eventos;
  final List<Venda> vendas;
  final List<Parcela> parcelas;
  final List<ContratoLocacao> contratos;
  final List<Cobranca> cobrancas;

  /// Repasses já feitos: chave "cobrancaId|contatoId" → data.
  final Map<String, DateTime> repasses;
  final List<Reserva> reservas;
  final List<Lancamento> lancamentos;
}

const _meses = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
]; // fmt: skip

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

bool _mesmoMes(DateTime? d, DateTime ref) =>
    d != null && d.year == ref.year && d.month == ref.month;

/// Variação % entre o valor atual e o anterior (100% quando partiu do zero).
double _variacao(num atual, num anterior) => anterior == 0
    ? (atual > 0 ? 100 : 0)
    : ((atual - anterior) / anterior * 100);

/// Monta o painel a partir dos dados reais dos módulos.
DashboardResumo montarDashboard(
  DadosDashboard d,
  PeriodoDesempenho periodo,
  DateTime agora,
) {
  final hoje = _dia(agora);
  final inicioMes = DateTime(hoje.year, hoje.month);
  final mesAnterior = DateTime(hoje.year, hoje.month - 1);
  final contatoPorId = {for (final c in d.contatos) c.id: c};
  final imovelPorId = {for (final i in d.imoveis) i.id: i};
  final vendasValidas = d.vendas.where(
    (v) => v.status != StatusVenda.distratada,
  );

  // ---------------------------------------------------------- Indicadores
  int criadosAntes<T>(Iterable<T> l, DateTime? Function(T) criado) =>
      l.where((e) => (criado(e) ?? hoje).isBefore(inicioMes)).length;

  final ativos = d.contatos.where((c) => c.etapa != EtapaFunil.perdido);
  final vendasMes = vendasValidas.where((v) => _mesmoMes(v.dataVenda, hoje));
  final vendasAnt = vendasValidas.where(
    (v) => _mesmoMes(v.dataVenda, mesAnterior),
  );
  final vigentes = d.contratos.where((c) => c.vigenteEm(hoje)).length;
  final vigentesAnt = d.contratos.where((c) => c.vigenteEm(mesAnterior)).length;

  Indicador indicador(int atual, int anterior) =>
      Indicador(valor: atual, variacaoPercentual: _variacao(atual, anterior));

  // --------------------------------------------------------- Desempenho
  bool reservaConta(Reserva r) => !r.bloqueio && r.ocupa;
  PontoDesempenho ponto(String rotulo, bool Function(DateTime) noPeriodo) =>
      PontoDesempenho(
        rotulo: rotulo,
        vendas: vendasValidas.where((v) => noPeriodo(v.dataVenda)).length,
        locacoes:
            d.contratos.where((c) => noPeriodo(c.dataInicio)).length +
            d.reservas
                .where((r) => reservaConta(r) && noPeriodo(r.checkIn))
                .length,
      );
  final desempenho = switch (periodo) {
    PeriodoDesempenho.ano => [
      for (var i = 11; i >= 0; i--)
        () {
          final m = DateTime(hoje.year, hoje.month - i);
          return ponto(_meses[m.month - 1], (x) => _mesmoMes(x, m));
        }(),
    ],
    _ => [
      for (
        var i = (periodo == PeriodoDesempenho.semana ? 7 : 30) - 1;
        i >= 0;
        i--
      )
        () {
          final dia = DateTime(hoje.year, hoje.month, hoje.day - i);
          final rotulo =
              '${dia.day.toString().padLeft(2, '0')}/'
              '${dia.month.toString().padLeft(2, '0')}';
          return ponto(rotulo, (x) => _dia(x) == dia);
        }(),
    ],
  };

  // -------------------------------------------------------------- Funil
  FunilConversao funil(Iterable<Contato> base) {
    final noFunil = base.toList();
    int aPartirDe(EtapaFunil e) => noFunil
        .where((c) => c.etapa != EtapaFunil.perdido && c.etapa.index >= e.index)
        .length;
    final fechados = noFunil.where((c) => c.etapa == EtapaFunil.fechado).length;
    return FunilConversao(
      taxa: noFunil.isEmpty ? 0 : fechados / noFunil.length * 100,
      variacao: 0,
      leads: noFunil.length,
      visitas: aPartirDe(EtapaFunil.visita),
      propostas: aPartirDe(EtapaFunil.proposta),
      negociacoes: aPartirDe(EtapaFunil.negociacao),
    );
  }

  final funilAtual = funil(d.contatos);
  final funilAnterior = funil(
    d.contatos.where((c) => c.criadoEm.isBefore(inicioMes)),
  );
  final conversao = FunilConversao(
    taxa: funilAtual.taxa,
    // Pontos percentuais em relação a quem já estava cadastrado no mês passado.
    variacao: funilAtual.taxa - funilAnterior.taxa,
    leads: funilAtual.leads,
    visitas: funilAtual.visitas,
    propostas: funilAtual.propostas,
    negociacoes: funilAtual.negociacoes,
  );

  // ------------------------------------------------------- Compromissos
  final proximos =
      d.eventos
          .where(
            (e) =>
                !e.concluido &&
                e.dataHora != null &&
                !e.dataHora!.isBefore(agora),
          )
          .toList()
        ..sort((a, b) => a.dataHora!.compareTo(b.dataHora!));
  final compromissos = [
    for (final e in proximos.take(4))
      Compromisso(
        quando: e.dataHora!,
        titulo: e.titulo,
        detalhe: switch ((
          contatoPorId[e.contatoId]?.nome,
          imovelPorId[e.imovelId]?.titulo,
        )) {
          (final String c, _) => 'Cliente: $c',
          (_, final String i) => 'Imóvel: $i',
          _ => e.tipo.label,
        },
        tipo: switch (e.tipo) {
          TipoEvento.visita => TipoCompromisso.visita,
          TipoEvento.reuniao || TipoEvento.ligacao => TipoCompromisso.reuniao,
          _ => TipoCompromisso.assinatura,
        },
      ),
  ];

  // --------------------------------------------------- Imóveis recentes
  String caracteristicas(Imovel i) => [
    if (i.quartos > 0) '${i.quartos} ${i.quartos == 1 ? 'quarto' : 'quartos'}',
    if (i.suites > 0) '${i.suites} ${i.suites == 1 ? 'suíte' : 'suítes'}',
    if (i.vagas > 0) '${i.vagas} ${i.vagas == 1 ? 'vaga' : 'vagas'}',
    if ((i.areaUtil ?? i.areaTotal) != null)
      '${decimalToText(i.areaUtil ?? i.areaTotal)} m²',
  ].take(3).join(' • ');

  String preco(Imovel i) {
    if (i.finalidades.contains(Finalidade.venda) && i.valorVenda != null) {
      return formatMoney(i.valorVenda);
    }
    if (i.valorLocacao != null) return '${formatMoney(i.valorLocacao)}/mês';
    if (i.valorTemporada != null) {
      return '${formatMoney(i.valorTemporada)}/diária';
    }
    return 'Sob consulta';
  }

  final recentes = [...d.imoveis]
    ..sort((a, b) => (b.criadoEm ?? hoje).compareTo(a.criadoEm ?? hoje));
  final imoveisRecentes = [
    for (final i in recentes.take(4))
      ImovelRecente(
        titulo: i.titulo,
        caracteristicas: caracteristicas(i),
        finalidade: i.finalidades.contains(Finalidade.venda)
            ? FinalidadeImovelRecente.venda
            : FinalidadeImovelRecente.locacao,
        preco: preco(i),
        cadastradoEm: i.criadoEm ?? agora,
        casa: const {
          TipoImovel.casa,
          TipoImovel.casaCondominio,
          TipoImovel.sitio,
          TipoImovel.fazenda,
        }.contains(i.tipo),
      ),
  ];

  // ---------------------------------------------------------- Financeiro
  // Recebido no mês: aluguéis pagos, parcelas de venda pagas e outras
  // contas a receber baixadas; despesas = contas a pagar baixadas.
  double aluguelEm(bool Function(DateTime) quando) => d.cobrancas
      .where(
        (c) =>
            c.status == StatusCobranca.paga &&
            c.dataPagamento != null &&
            quando(c.dataPagamento!),
      )
      .fold(0, (s, c) => s + (c.valorPago ?? c.total));
  double vendasEm(bool Function(DateTime) quando) => d.parcelas
      .where(
        (p) =>
            p.status == StatusParcela.paga &&
            p.dataPagamento != null &&
            quando(p.dataPagamento!),
      )
      .fold(0, (s, p) => s + (p.valorPago ?? p.valor));
  double lancamentosEm(TipoLancamento tipo, bool Function(DateTime) quando) => d
      .lancamentos
      .where(
        (l) =>
            l.tipo == tipo &&
            l.baixado &&
            l.dataBaixa != null &&
            quando(l.dataBaixa!),
      )
      .fold(0, (s, l) => s + (l.valorBaixa ?? l.valor));
  double receitasEm(bool Function(DateTime) quando) =>
      aluguelEm(quando) +
      vendasEm(quando) +
      lancamentosEm(TipoLancamento.receber, quando);

  bool noMes(DateTime x) => _mesmoMes(x, hoje) && !x.isAfter(agora);
  final aluguel = aluguelEm(noMes);
  final vendasRecebidas = vendasEm(noMes);
  final outras = lancamentosEm(TipoLancamento.receber, noMes);
  final despesas = lancamentosEm(TipoLancamento.pagar, noMes);
  final receitas = aluguel + vendasRecebidas + outras;
  final movimento = receitas + despesas;
  ItemFinanceiro item(String rotulo, double valor, {bool despesa = false}) =>
      ItemFinanceiro(
        rotulo: rotulo,
        valor: valor,
        percentual: movimento == 0 ? 0 : valor / movimento * 100,
        despesa: despesa,
      );
  // Receita acumulada dia a dia no mês (mínimo de dois pontos).
  final evolucao = <double>[
    0,
    for (var dia = 1; dia <= hoje.day; dia++)
      receitasEm(
        (x) =>
            _mesmoMes(x, hoje) &&
            _dia(x).isBefore(DateTime(hoje.year, hoje.month, dia + 1)),
      ),
  ];
  final financeiro = ResumoFinanceiroMes(
    receitas: receitas,
    variacaoPercentual: _variacao(
      receitas,
      receitasEm((x) => _mesmoMes(x, mesAnterior)),
    ),
    evolucao: evolucao,
    itens: [
      item('Vendas', vendasRecebidas),
      item('Aluguéis', aluguel),
      if (outras > 0) item('Outras receitas', outras),
      item('Despesas', despesas, despesa: true),
    ],
  );

  // --------------------------------------------------------- Atividades
  final contratoPorId = {for (final c in d.contratos) c.id: c};
  final vendaPorId = {for (final v in d.vendas) v.id: v};
  final atividades =
      <AtividadeRecente>[
          for (final c in d.contatos)
            AtividadeRecente(
              titulo: 'Novo cliente cadastrado',
              detalhe: 'Cliente: ${c.nome}',
              quando: c.criadoEm,
              tipo: TipoAtividadeRecente.cliente,
            ),
          for (final i in d.imoveis)
            if (i.criadoEm != null)
              AtividadeRecente(
                titulo: 'Imóvel cadastrado',
                detalhe: '${i.codigo} • ${i.titulo}',
                quando: i.criadoEm!,
                tipo: TipoAtividadeRecente.imovel,
              ),
          for (final c in d.contratos)
            AtividadeRecente(
              titulo: 'Contrato de locação ${c.numero}',
              detalhe: 'Imóvel: ${imovelPorId[c.imovelId]?.titulo ?? '—'}',
              quando: c.dataInicio,
              tipo: TipoAtividadeRecente.contrato,
            ),
          for (final v in vendasValidas)
            AtividadeRecente(
              titulo: 'Venda ${v.numero}',
              detalhe: 'Imóvel: ${imovelPorId[v.imovelId]?.titulo ?? '—'}',
              quando: v.dataVenda,
              tipo: TipoAtividadeRecente.proposta,
            ),
          for (final c in d.cobrancas)
            if (c.status == StatusCobranca.paga && c.dataPagamento != null)
              AtividadeRecente(
                titulo: 'Aluguel recebido',
                detalhe:
                    '${contratoPorId[c.contratoId]?.numero ?? ''} • '
                    '${formatMoney(c.valorPago ?? c.total)}',
                quando: c.dataPagamento!,
                tipo: TipoAtividadeRecente.pagamento,
              ),
          for (final p in d.parcelas)
            if (p.status == StatusParcela.paga && p.dataPagamento != null)
              AtividadeRecente(
                titulo: 'Parcela recebida',
                detalhe:
                    '${vendaPorId[p.vendaId]?.numero ?? ''} ${p.rotulo} • '
                    '${formatMoney(p.valorPago ?? p.valor)}',
                quando: p.dataPagamento!,
                tipo: TipoAtividadeRecente.pagamento,
              ),
          for (final l in d.lancamentos)
            if (l.baixado && l.dataBaixa != null)
              AtividadeRecente(
                titulo: '${l.tipo.baixadoLabel}: ${l.descricao}',
                detalhe: formatMoney(l.valorBaixa ?? l.valor),
                quando: l.dataBaixa!,
                tipo: TipoAtividadeRecente.pagamento,
              ),
        ].where((a) => !a.quando.isAfter(agora)).toList()
        ..sort((a, b) => b.quando.compareTo(a.quando));

  // ---------------------------------------------------------- Contadores
  final em60dias = hoje.add(const Duration(days: 60));
  final em7dias = hoje.add(const Duration(days: 7));
  final repassesPendentes = d.cobrancas.where((c) {
    if (c.status != StatusCobranca.paga) return false;
    final contrato = contratoPorId[c.contratoId];
    return contrato != null &&
        contrato.beneficiarios.any(
          (b) => !d.repasses.containsKey(chaveRepasse(c.id, b.contatoId)),
        );
  }).length;

  return DashboardResumo(
    imoveis: indicador(
      d.imoveis.length,
      criadosAntes(d.imoveis, (i) => i.criadoEm),
    ),
    clientes: indicador(ativos.length, criadosAntes(ativos, (c) => c.criadoEm)),
    vendasMes: indicador(vendasMes.length, vendasAnt.length),
    locacoesAtivas: indicador(vigentes, vigentesAnt),
    desempenho: desempenho,
    conversao: conversao,
    compromissos: compromissos,
    imoveisRecentes: imoveisRecentes,
    financeiro: financeiro,
    atividades: atividades.take(5).toList(),
    contadores: ContadoresPainel(
      contratosVencendo: d.contratos
          .where(
            (c) =>
                c.status == StatusContrato.ativo &&
                !c.dataFim.isBefore(hoje) &&
                !c.dataFim.isAfter(em60dias),
          )
          .length,
      boletosEmAtraso: d.cobrancas.where((c) => c.atrasada(hoje)).length,
      reservasProximas: d.reservas
          .where(
            (r) =>
                reservaConta(r) &&
                !r.checkIn.isBefore(hoje) &&
                !r.checkIn.isAfter(em7dias),
          )
          .length,
      repassesPendentes: repassesPendentes,
      novosLeads: d.contatos
          .where(
            (c) =>
                c.papeis.contains(PapelContato.lead) &&
                !c.criadoEm.isBefore(hoje.subtract(const Duration(days: 30))),
          )
          .length,
      visitasAgendadas: proximos
          .where((e) => e.tipo == TipoEvento.visita)
          .length,
      negociacoesAtivas: d.contatos
          .where(
            (c) =>
                c.etapa == EtapaFunil.proposta ||
                c.etapa == EtapaFunil.negociacao,
          )
          .length,
      oportunidades: const SugerirNegocios().total(d.contatos, d.imoveis),
    ),
  );
}
