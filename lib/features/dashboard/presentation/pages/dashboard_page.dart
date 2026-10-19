import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/skyline.dart';
import '../../../crm/presentation/pages/contato_form_page.dart';
import '../../../crm/presentation/pages/imovel_form_page.dart';
import '../../../locacao/presentation/pages/contrato_form_page.dart';
import '../../../vendas/presentation/pages/venda_form_page.dart';
import '../../domain/entities/dashboard.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/dash_card.dart';
import '../widgets/graficos.dart';

/// Telas para onde os atalhos do dashboard levam.
enum DestinoDashboard {
  imoveis,
  clientes,
  vendas,
  locacoes,
  agenda,
  oportunidades,
  financeiro,
  boletos,
  cobrancas,
  repasses,
  temporada,
  atividades,
}

const _azulLink = Color(0xFF8CB8FF);
const _meses = [
  'JAN',
  'FEV',
  'MAR',
  'ABR',
  'MAI',
  'JUN',
  'JUL',
  'AGO',
  'SET',
  'OUT',
  'NOV',
  'DEZ',
];

String _hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Painel inicial com o resumo da imobiliária.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onNavegar});

  final ValueChanged<DestinoDashboard> onNavegar;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _vm = sl<DashboardViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _ir(DestinoDashboard d) => widget.onNavegar(d);

  void _abrir(Widget pagina) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => pagina));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final r = _vm.resumo;
        if (r == null) return const Center(child: CircularProgressIndicator());
        return LayoutBuilder(
          builder: (context, c) {
            final largo = c.maxWidth >= 1250;
            final medio = c.maxWidth >= 760;
            final pad = medio ? 20.0 : 12.0;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(nome: _vm.primeiroNome, compacto: !medio),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
                    child: largo ? _layoutLargo(r) : _layoutColuna(r, medio),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _layoutLargo(DashboardResumo r) {
    const g = SizedBox(width: 16, height: 16);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, k) in _kpis(r).indexed) ...[
                      if (i > 0) g,
                      Expanded(child: k),
                    ],
                  ],
                ),
              ),
              g,
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 13, child: _desempenho(r)),
                    g,
                    Expanded(flex: 8, child: _conversao(r.conversao)),
                  ],
                ),
              ),
              g,
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 13, child: _imoveis(r.imoveisRecentes)),
                    g,
                    Expanded(flex: 10, child: _financeiro(r.financeiro)),
                  ],
                ),
              ),
              g,
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _operacao(r.contadores)),
                    g,
                    Expanded(child: _crm(r.contadores)),
                  ],
                ),
              ),
            ],
          ),
        ),
        g,
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _acoesRapidas(),
              g,
              _compromissos(r.compromissos),
              g,
              _atividades(r.atividades),
            ],
          ),
        ),
      ],
    );
  }

  Widget _layoutColuna(DashboardResumo r, bool medio) {
    const g = SizedBox(height: 16);
    final kpis = _kpis(r);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final colunas = c.maxWidth >= 640 ? 2 : 1;
            final largura = (c.maxWidth - 16 * (colunas - 1)) / colunas;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final k in kpis) SizedBox(width: largura, child: k),
              ],
            );
          },
        ),
        g,
        _acoesRapidas(),
        g,
        _desempenho(r),
        g,
        _conversao(r.conversao),
        g,
        _compromissos(r.compromissos),
        g,
        _imoveis(r.imoveisRecentes),
        g,
        _financeiro(r.financeiro),
        g,
        _atividades(r.atividades),
        g,
        _operacao(r.contadores),
        g,
        _crm(r.contadores),
      ],
    );
  }

  // ---------------------------------------------------------------- KPIs

  List<Widget> _kpis(DashboardResumo r) => [
    _kpi(
      'Imóveis Cadastrados',
      Icons.home_outlined,
      r.imoveis,
      'Ver imóveis',
      DestinoDashboard.imoveis,
    ),
    _kpi(
      'Clientes Ativos',
      Icons.people_outline,
      r.clientes,
      'Ver clientes',
      DestinoDashboard.clientes,
    ),
    _kpi(
      'Vendas no Mês',
      Icons.handshake_outlined,
      r.vendasMes,
      'Ver vendas',
      DestinoDashboard.vendas,
    ),
    _kpi(
      'Locações Ativas',
      Icons.key_outlined,
      r.locacoesAtivas,
      'Ver locações',
      DestinoDashboard.locacoes,
    ),
  ];

  Widget _kpi(
    String titulo,
    IconData icone,
    Indicador ind,
    String link,
    DestinoDashboard destino,
  ) {
    return DashCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconeCirculo(icone),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${ind.valor}',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Variacao(ind.variacaoPercentual),
              const Spacer(),
              const Text(
                'vs. mês anterior',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: LinkAcao(
              texto: link,
              cor: _azulLink,
              onTap: () => _ir(destino),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- Desempenho

  Widget _desempenho(DashboardResumo r) {
    Widget legenda(Color cor, String texto) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(texto, style: const TextStyle(fontSize: 13)),
      ],
    );
    return DashCard(
      titulo: 'Desempenho Geral',
      icone: Icons.bar_chart,
      trailing: PopupMenuButton<PeriodoDesempenho>(
        color: AppColors.navy,
        onSelected: _vm.mudarPeriodo,
        itemBuilder: (_) => [
          for (final p in PeriodoDesempenho.values)
            PopupMenuItem(value: p, child: Text(p.label)),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            color: AppColors.navyDark.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_vm.periodo.label, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 10),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 28,
            children: [
              legenda(AppColors.gold, 'Vendas'),
              legenda(AppColors.blueGlow, 'Locações'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(height: 190, child: GraficoDesempenho(pontos: r.desempenho)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- Conversão

  Widget _conversao(FunilConversao f) {
    final taxa = f.taxa.toStringAsFixed(1).replaceAll('.', ',');
    Widget linha(IconData icone, String rotulo, int valor) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icone, size: 18, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(child: Text(rotulo, style: const TextStyle(fontSize: 14))),
          Text(
            '$valor',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              RoscaConversao(taxa: f.taxa, tamanho: 104),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Taxa de Conversão',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 14,
                      children: [
                        Text(
                          '$taxa%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Variacao(f.variacao, sufixo: '%', tamanho: 15),
                      ],
                    ),
                    // Quebra a linha em vez de estourar em telas estreitas.
                    const Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Leads',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_right_alt,
                          size: 18,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Negócios',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.12)),
          linha(Icons.groups_outlined, 'Leads', f.leads),
          linha(Icons.track_changes, 'Visitas', f.visitas),
          linha(Icons.description_outlined, 'Propostas', f.propostas),
          linha(Icons.handshake_outlined, 'Negociações', f.negociacoes),
        ],
      ),
    );
  }

  // ------------------------------------------------------- Ações rápidas

  Widget _acoesRapidas() {
    Widget botao(IconData icone, String texto, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.gold.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(icone, color: AppColors.gold, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(texto, style: const TextStyle(fontSize: 14)),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
    return DashCard(
      titulo: 'Ações Rápidas',
      icone: Icons.bolt,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          botao(
            Icons.home_outlined,
            'Novo Cadastro de Imóvel',
            () => _abrir(const ImovelFormPage()),
          ),
          botao(
            Icons.person_outline,
            'Novo Cliente',
            () => _abrir(const ContatoFormPage()),
          ),
          botao(
            Icons.sell_outlined,
            'Nova Venda',
            () => _abrir(const VendaFormPage()),
          ),
          botao(
            Icons.key_outlined,
            'Nova Locação',
            () => _abrir(const ContratoFormPage()),
          ),
          botao(
            Icons.receipt_long_outlined,
            'Emitir Boleto',
            () => _ir(DestinoDashboard.boletos),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------- Próximos compromissos

  Widget _compromissos(List<Compromisso> lista) {
    IconData icone(TipoCompromisso t) => switch (t) {
      TipoCompromisso.visita => Icons.home_work_outlined,
      TipoCompromisso.reuniao => Icons.groups_outlined,
      TipoCompromisso.assinatura => Icons.edit_document,
    };
    return DashCard(
      titulo: 'Próximos Compromissos',
      icone: Icons.calendar_month_outlined,
      acao: 'Ver todos',
      onAcao: () => _ir(DestinoDashboard.agenda),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        children: [
          if (lista.isEmpty) const _ListaVazia('Nenhum compromisso agendado.'),
          for (final (i, c) in lista.indexed) ...[
            if (i > 0)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            InkWell(
              onTap: () => _ir(DestinoDashboard.agenda),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Column(
                        children: [
                          Text(
                            '${c.quando.day}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _meses[c.quando.month - 1],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: Colors.white24,
                    ),
                    IconeCirculo(icone(c.tipo), tamanho: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_hora(c.quando)} - ${c.detalhe}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------- Imóveis recentes

  Widget _imoveis(List<ImovelRecente> lista) {
    final agora = _vm.agora;
    return DashCard(
      titulo: 'Últimos Imóveis Cadastrados',
      icone: Icons.home_outlined,
      acao: 'Ver todos',
      onAcao: () => _ir(DestinoDashboard.imoveis),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          if (lista.isEmpty) const _ListaVazia('Nenhum imóvel cadastrado.'),
          for (final (i, im) in lista.indexed) ...[
            if (i > 0)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            InkWell(
              onTap: () => _ir(DestinoDashboard.imoveis),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _Miniatura(casa: im.casa),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            im.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            im.caracteristicas,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ChipFinalidade(im.finalidade),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 118,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            im.preco,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            tempoRelativo(im.cadastradoEm, agora),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------- Financeiro

  Widget _financeiro(ResumoFinanceiroMes f) {
    Widget item(ItemFinanceiro i) {
      final cor = i.despesa ? Colors.redAccent : AppColors.gold;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cor.withValues(alpha: 0.9),
              ),
              child: Icon(
                i.despesa ? Icons.trending_down : Icons.attach_money,
                size: 16,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(i.rotulo, style: const TextStyle(fontSize: 14)),
            ),
            Text(
              formatMoney(i.valor),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              width: 64,
              child: Text(
                '${i.percentual.round()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DashCard(
      titulo: 'Financeiro',
      icone: Icons.monetization_on_outlined,
      acao: 'Ver detalhes',
      onAcao: () => _ir(DestinoDashboard.financeiro),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.blueGlow.withValues(alpha: 0.3),
              ),
              color: AppColors.navyDark.withValues(alpha: 0.4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receitas do Mês',
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatMoney(f.receitas),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Variacao(f.variacaoPercentual),
                    ],
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 66,
                  child: GraficoArea(valores: f.evolucao),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final i in f.itens) item(i),
        ],
      ),
    );
  }

  // ------------------------------------------------- Atividades recentes

  Widget _atividades(List<AtividadeRecente> lista) {
    final agora = _vm.agora;
    (IconData, Color) estilo(TipoAtividadeRecente t) => switch (t) {
      TipoAtividadeRecente.cliente => (Icons.person, AppColors.blueGlow),
      TipoAtividadeRecente.imovel => (Icons.home, AppColors.gold),
      TipoAtividadeRecente.contrato => (
        Icons.description,
        const Color(0xFF3DDC84),
      ),
      TipoAtividadeRecente.pagamento => (
        Icons.attach_money,
        const Color(0xFF2EB872),
      ),
      TipoAtividadeRecente.proposta => (Icons.send, AppColors.blueGlow),
    };
    String quando(DateTime d) {
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final dia = DateTime(d.year, d.month, d.day);
      final prefixo = dia == hoje
          ? 'Hoje'
          : (hoje.difference(dia).inDays == 1 ? 'Ontem' : formatDate(d));
      // Datas sem hora (ex.: data da venda) mostram só o dia.
      return d.hour == 0 && d.minute == 0 ? prefixo : '$prefixo, ${_hora(d)}';
    }

    return DashCard(
      titulo: 'Atividades Recentes',
      icone: Icons.schedule,
      acao: 'Ver todas',
      onAcao: () => _ir(DestinoDashboard.atividades),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        children: [
          if (lista.isEmpty) const _ListaVazia('Nenhuma atividade ainda.'),
          for (final (i, a) in lista.indexed) ...[
            if (i > 0)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: estilo(a.tipo).$2,
                    child: Icon(
                      estilo(a.tipo).$1,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          a.detalhe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _azulLink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    quando(a.quando),
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------- Operação e CRM

  Widget _painelContadores(
    String titulo,
    IconData icone,
    List<(IconData, Color, String, int, DestinoDashboard)> itens,
  ) {
    return DashCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                for (final (i, (ic, cor, rotulo, valor, destino))
                    in itens.indexed) ...[
                  if (i > 0)
                    VerticalDivider(
                      width: 18,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _ir(destino),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(ic, size: 18, color: cor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rotulo,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '$valor',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: cor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _operacao(ContadoresPainel c) =>
      _painelContadores('Operação', Icons.engineering_outlined, [
        (
          Icons.event_busy_outlined,
          const Color(0xFFFF6B5B),
          'Contratos vencendo',
          c.contratosVencendo,
          DestinoDashboard.locacoes,
        ),
        (
          Icons.error_outline,
          const Color(0xFFFF6B5B),
          'Boletos em atraso',
          c.boletosEmAtraso,
          DestinoDashboard.cobrancas,
        ),
        (
          Icons.event_available_outlined,
          _azulLink,
          'Reservas próximas',
          c.reservasProximas,
          DestinoDashboard.temporada,
        ),
        (
          Icons.swap_horiz,
          Colors.white,
          'Repasse pendente',
          c.repassesPendentes,
          DestinoDashboard.repasses,
        ),
      ]);

  Widget _crm(ContadoresPainel c) =>
      _painelContadores('CRM', Icons.groups_outlined, [
        (
          Icons.person_add_alt,
          const Color(0xFF3DDC84),
          'Novos leads',
          c.novosLeads,
          DestinoDashboard.clientes,
        ),
        (
          Icons.check_circle_outline,
          AppColors.blueGlow,
          'Visitas agendadas',
          c.visitasAgendadas,
          DestinoDashboard.agenda,
        ),
        (
          Icons.handshake_outlined,
          AppColors.gold,
          'Negociações ativas',
          c.negociacoesAtivas,
          DestinoDashboard.clientes,
        ),
        (
          Icons.auto_awesome_outlined,
          const Color(0xFFC77DFF),
          'Oportunidades (perfil)',
          c.oportunidades,
          DestinoDashboard.oportunidades,
        ),
      ]);
}

/// Faixa de boas-vindas com a ilustração da orla.
class _Hero extends StatelessWidget {
  const _Hero({required this.nome, required this.compacto});

  final String nome;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compacto ? 96 : 118,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.blueGlow.withValues(alpha: 0.25)),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: compacto ? 1 : 0.62,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Colors.transparent, Colors.black, Colors.black],
                    stops: [0, 0.35, 1],
                  ).createShader(r),
                  child: const Opacity(
                    opacity: 0.9,
                    child: Skyline(semente: 11),
                  ),
                ),
              ),
            ),
          ),
          if (compacto)
            Container(color: AppColors.navyDark.withValues(alpha: 0.45)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compacto ? 16 : 36),
            child: Row(
              children: [
                Icon(
                  Icons.waving_hand,
                  color: AppColors.gold,
                  size: compacto ? 32 : 44,
                ),
                SizedBox(width: compacto ? 12 : 22),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome.isEmpty ? 'Olá!' : 'Olá, $nome!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compacto ? 22 : 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Aqui está o resumo da sua imobiliária hoje.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compacto ? 13 : 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compacto)
                  Container(
                    width: 250,
                    height: double.infinity,
                    alignment: Alignment.center,
                    color: AppColors.navyDark.withValues(alpha: 0.82),
                    child: Transform.rotate(
                      angle: -0.07,
                      child: Text(
                        'Grandes negócios\ncomeçam com\nboa gestão.',
                        textAlign: TextAlign.center,
                        style: estiloManuscrito(tamanho: 23),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Miniatura ilustrada do imóvel (até haver fotos reais).
class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.casa});

  final bool casa;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: casa
              ? const [Color(0xFF6FB7E9), Color(0xFF2F7A5C)]
              : const [Color(0xFF9CC7EE), Color(0xFF4B6D93)],
        ),
      ),
      child: Icon(
        casa ? Icons.house_siding : Icons.apartment,
        color: Colors.white.withValues(alpha: 0.9),
        size: 30,
      ),
    );
  }
}

class _ChipFinalidade extends StatelessWidget {
  const _ChipFinalidade(this.finalidade);

  final FinalidadeImovelRecente finalidade;

  @override
  Widget build(BuildContext context) {
    final venda = finalidade == FinalidadeImovelRecente.venda;
    final cor = venda ? AppColors.gold : _azulLink;
    return Container(
      width: 76,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: (venda ? AppColors.gold : AppColors.blueGlow).withValues(
          alpha: 0.16,
        ),
        border: Border.all(color: cor.withValues(alpha: 0.6)),
      ),
      child: Text(
        venda ? 'Venda' : 'Locação',
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Center(
      child: Text(texto, style: const TextStyle(color: Colors.white60)),
    ),
  );
}
