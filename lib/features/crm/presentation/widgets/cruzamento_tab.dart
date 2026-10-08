import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/evento.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/usecases/sugerir_negocios.dart';
import '../viewmodels/cruzamento_viewmodel.dart';
import 'evento_dialog.dart';

/// Relaciona o perfil de interesse dos contatos com os imóveis disponíveis.
class CruzamentoTab extends StatefulWidget {
  const CruzamentoTab({super.key});

  @override
  State<CruzamentoTab> createState() => _CruzamentoTabState();
}

class _CruzamentoTabState extends State<CruzamentoTab> {
  final _vm = sl<CruzamentoViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            const Text(
              'O sistema compara o perfil de interesse de cada contato com os '
              'imóveis disponíveis e sugere negócios com compatibilidade de '
              '$scoreMinimo% ou mais.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.person_search_outlined),
                  label: Text('Por contato'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.home_work_outlined),
                  label: Text('Por imóvel'),
                ),
              ],
              selected: {_vm.porContato},
              onSelectionChanged: (s) => _vm.alternarVisao(s.first),
            ),
            const SizedBox(height: 12),
            if (_vm.porContato) ..._porContatoView() else ..._porImovelView(),
          ],
        );
      },
    );
  }

  List<Widget> _porContatoView() {
    final grupos = _vm.porContatos;
    if (grupos.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.manage_search,
          message:
              'Nenhum contato com perfil de interesse.\nAtive o perfil no cadastro do contato.',
        ),
      ];
    }
    return [
      for (final (:contato, :matches) in grupos)
        _GrupoMatches(
          icone: Icons.person_outline,
          titulo: contato.nome,
          subtitulo: _resumoPerfil(contato.perfil!),
          matches: matches,
          rotuloItem: (m) => '${m.imovel.codigo} • ${m.imovel.titulo}',
          detalheItem: (m) => [
            m.imovel.enderecoResumo,
            formatMoney(m.imovel.valorPara(contato.perfil!.finalidade)),
          ].where((e) => e.isNotEmpty).join('  •  '),
        ),
    ];
  }

  List<Widget> _porImovelView() {
    final grupos = _vm.porImoveis;
    if (grupos.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.apartment,
          message: 'Nenhum imóvel disponível cadastrado.',
        ),
      ];
    }
    return [
      for (final (imovel: i, :matches) in grupos)
        _GrupoMatches(
          icone: Icons.apartment,
          titulo: '${i.codigo} • ${i.titulo}',
          subtitulo: i.enderecoResumo,
          matches: matches,
          rotuloItem: (m) => m.contato.nome,
          detalheItem: (m) => [
            m.contato.celular.isNotEmpty
                ? m.contato.celular
                : m.contato.telefone,
            m.contato.email,
          ].where((e) => e.isNotEmpty).join('  •  '),
        ),
    ];
  }

  String _resumoPerfil(PerfilInteresse p) => [
    p.finalidade.perfilLabel,
    if (p.tipos.isNotEmpty) p.tipos.map((e) => e.label).join('/'),
    if (p.cidade.isNotEmpty) p.cidade,
    if (p.valorMin != null || p.valorMax != null)
      '${formatMoney(p.valorMin)} a ${formatMoney(p.valorMax)}',
    if (p.quartosMin > 0) '${p.quartosMin}+ qtos',
  ].join(' • ');
}

class _GrupoMatches extends StatelessWidget {
  const _GrupoMatches({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.matches,
    required this.rotuloItem,
    required this.detalheItem,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final List<MatchResult> matches;
  final String Function(MatchResult) rotuloItem;
  final String Function(MatchResult) detalheItem;

  Color _cor(int score) => score >= 80
      ? Colors.greenAccent
      : score >= 65
      ? AppColors.gold
      : Colors.orangeAccent;

  void _agendar(BuildContext context, MatchResult m) {
    showEventoDialog(
      context,
      modelo: Evento(
        id: '',
        criadoEm: DateTime.now(),
        tipo: TipoEvento.lembrete,
        titulo: 'Apresentar ${m.imovel.codigo} a ${m.contato.nome}',
        descricao: 'Compatibilidade de ${m.score}% com o perfil de interesse.',
        dataHora: DateTime.now().add(const Duration(days: 1)),
        contatoId: m.contato.id,
        imovelId: m.imovel.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icone, color: AppColors.gold),
          iconColor: AppColors.gold,
          collapsedIconColor: AppColors.gold,
          title: Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${matches.length} sugestão(ões)'
            '${subtitulo.isEmpty ? '' : '  •  $subtitulo'}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          initiallyExpanded: matches.isNotEmpty,
          children: [
            if (matches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Nenhuma correspondência encontrada por enquanto.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            for (final m in matches)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rotuloItem(m),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${m.score}%',
                          style: TextStyle(
                            color: _cor(m.score),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: m.score / 100,
                        minHeight: 6,
                        color: _cor(m.score),
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detalheItem(m),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final a in m.atende)
                          GoldChip(a, color: Colors.greenAccent),
                        for (final n in m.naoAtende)
                          GoldChip(n, color: Colors.orangeAccent),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _agendar(context, m),
                        icon: const Icon(Icons.alarm_add, size: 18),
                        label: const Text('Agendar retorno'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.goldLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
