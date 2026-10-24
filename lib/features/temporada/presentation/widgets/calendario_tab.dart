import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/reserva.dart';
import '../pages/reserva_form_page.dart';
import '../viewmodels/calendario_viewmodel.dart';
import 'calendario_mes_view.dart';
import 'cores_reserva.dart';
import 'linha_do_tempo_view.dart';

/// Calendário de reservas montado automaticamente a partir das reservas.
class CalendarioTab extends StatefulWidget {
  const CalendarioTab({super.key});

  @override
  State<CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<CalendarioTab> {
  final _vm = sl<CalendarioViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrir({Reserva? reserva, String? imovelId, DateTime? checkIn}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReservaFormPage(
          reserva: reserva,
          imovelId: imovelId,
          checkIn: checkIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.event_available_outlined,
        label: 'Nova reserva',
        onPressed: () => _abrir(imovelId: _vm.imovelSelecionado?.id),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (!_vm.carregado) return const SizedBox.shrink();
          final imoveis = _vm.imoveis;
          if (imoveis.isEmpty) {
            return const EmptyState(
              icon: Icons.beach_access_outlined,
              message:
                  'Nenhum imóvel de temporada.\n'
                  'Em "Cadastros e CRM", cadastre um imóvel com a finalidade '
                  '"Temporada" e o valor da diária.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              _painel(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CompetenciaSelector(value: _vm.mes, onChanged: _vm.mudarMes),
                  SegmentedButton<VisaoCalendario>(
                    segments: [
                      for (final v in VisaoCalendario.values)
                        ButtonSegment(value: v, label: Text(v.label)),
                    ],
                    selected: {_vm.visao},
                    onSelectionChanged: (s) => _vm.mudarVisao(s.first),
                  ),
                  SizedBox(
                    width: 280,
                    child: AppDropdown<String?>(
                      label: _vm.visao == VisaoCalendario.mes
                          ? 'Imóvel'
                          : 'Filtrar imóvel',
                      value: _vm.visao == VisaoCalendario.mes
                          ? _vm.imovelSelecionado?.id
                          : _vm.imovelId,
                      items: [
                        if (_vm.visao == VisaoCalendario.linhaDoTempo) null,
                        ...imoveis.map((i) => i.id),
                      ],
                      labelOf: (id) => id == null
                          ? 'Todos os imóveis'
                          : imoveis.firstWhere((i) => i.id == id).codigo,
                      onChanged: _vm.filtrarImovel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const LegendaCalendario(),
              const SizedBox(height: 12),
              if (_vm.visao == VisaoCalendario.linhaDoTempo)
                LinhaDoTempoView(
                  ano: _vm.mes.year,
                  mes: _vm.mes.month,
                  imoveis: _vm.imoveisVisiveis,
                  reservasDe: _vm.reservasDoImovel,
                  hoje: _vm.hoje,
                  nomeHospede: _vm.nomeHospede,
                  onReserva: (r) => _abrir(reserva: r),
                  onDiaLivre: (id, dia) => _abrir(imovelId: id, checkIn: dia),
                )
              else
                _mesDoImovel(),
              const SizedBox(height: 16),
              _ocupacao(),
            ],
          );
        },
      ),
    );
  }

  Widget _mesDoImovel() {
    final i = _vm.imovelSelecionado!;
    return CalendarioMesView(
      ano: _vm.mes.year,
      mes: _vm.mes.month,
      dias: _vm.diasDoMes(i.id),
      hoje: _vm.hoje,
      nomeHospede: _vm.nomeHospede,
      onReserva: (r) => _abrir(reserva: r),
      onDiaLivre: (dia) => _abrir(imovelId: i.id, checkIn: dia),
    );
  }

  Widget _painel() {
    Widget item(
      IconData icon,
      Color cor,
      int n,
      String rotulo,
      List<Reserva> lista,
    ) => Expanded(
      child: InkWell(
        onTap: lista.isEmpty
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.navy,
                  title: Text(rotulo),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in lista)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${_vm.nomeImovel(r.imovelId) ?? ''} • ${_vm.nomeHospede(r)} '
                            '(${formatDate(r.checkIn)} a ${formatDate(r.checkOut)})',
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
              ),
        child: Column(
          children: [
            Icon(icon, color: cor),
            Text(
              '$n',
              style: TextStyle(
                color: cor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.blue.withValues(alpha: 0.5), AppColors.navy],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          item(
            Icons.login,
            AppColors.gold,
            _vm.chegadasHoje.length,
            'Chegadas hoje',
            _vm.chegadasHoje,
          ),
          item(
            Icons.logout,
            Colors.orangeAccent,
            _vm.saidasHoje.length,
            'Saídas hoje',
            _vm.saidasHoje,
          ),
          item(
            Icons.hotel,
            Colors.greenAccent,
            _vm.hospedadosAgora.length,
            'Hospedados agora',
            _vm.hospedadosAgora,
          ),
        ],
      ),
    );
  }

  Widget _ocupacao() {
    final imoveis = _vm.visao == VisaoCalendario.mes
        ? [if (_vm.imovelSelecionado != null) _vm.imovelSelecionado!]
        : _vm.imoveisVisiveis;
    return FormSection(
      title: 'Ocupação de ${nomeMes(_vm.mes.month)}/${_vm.mes.year}',
      icon: Icons.insights_outlined,
      children: [
        for (final i in imoveis)
          () {
            final o = _vm.ocupacao(i.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${i.codigo} • ${i.titulo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(o.taxa * 100).round()}%',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: o.taxa,
                    minHeight: 6,
                    color: AppColors.gold,
                    backgroundColor: Colors.white12,
                  ),
                ),
                Text(
                  '${o.noitesOcupadas} de ${o.diasNoMes} noites • ${o.reservas} reserva(s) • '
                  'receita ${formatMoney(o.receita)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            );
          }(),
      ],
    );
  }
}
