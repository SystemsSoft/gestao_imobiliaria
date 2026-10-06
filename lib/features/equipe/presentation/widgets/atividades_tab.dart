import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/atividade.dart';
import '../../domain/entities/equipe_enums.dart';
import '../viewmodels/atividades_viewmodel.dart';
import 'avatar_usuario.dart';

IconData _icone(TipoAtividade t) => switch (t) {
  TipoAtividade.login => Icons.login,
  TipoAtividade.logout => Icons.logout,
  TipoAtividade.criacao => Icons.add_circle_outline,
  TipoAtividade.edicao => Icons.edit_outlined,
  TipoAtividade.exclusao => Icons.delete_outline,
  TipoAtividade.permissao => Icons.lock_person_outlined,
  TipoAtividade.atendimento => Icons.support_agent,
  TipoAtividade.comissao => Icons.percent,
  TipoAtividade.chat => Icons.chat_bubble_outline,
};

Color _cor(TipoAtividade t) => switch (t) {
  TipoAtividade.exclusao => Colors.redAccent,
  TipoAtividade.permissao => Colors.orangeAccent,
  TipoAtividade.login => Colors.greenAccent,
  TipoAtividade.logout => Colors.white54,
  _ => AppColors.gold,
};

/// Histórico de atividades de cada usuário.
class AtividadesTab extends StatefulWidget {
  const AtividadesTab({super.key});

  @override
  State<AtividadesTab> createState() => _AtividadesTabState();
}

class _AtividadesTabState extends State<AtividadesTab> {
  final _vm = sl<AtividadesViewModel>();

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
        final lista = _vm.filtradas;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextField(
              onChanged: _vm.buscar,
              decoration: const InputDecoration(
                hintText: 'Buscar no histórico...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: AppDropdown<String?>(
                    label: 'Usuário',
                    value: _vm.usuarioId,
                    items: [null, ..._vm.usuarios.map((u) => u.id)],
                    labelOf: (id) => id == null ? 'Todos' : _vm.nome(id),
                    onChanged: _vm.filtrarUsuario,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: AppDropdown<TipoAtividade?>(
                    label: 'Tipo de ação',
                    value: _vm.tipo,
                    items: [null, ...TipoAtividade.values],
                    labelOf: (t) => t?.label ?? 'Todas',
                    onChanged: _vm.filtrarTipo,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: AppDropdown<ModuloSistema?>(
                    label: 'Módulo',
                    value: _vm.modulo,
                    items: [null, ...ModuloSistema.values],
                    labelOf: (m) => m?.label ?? 'Todos',
                    onChanged: _vm.filtrarModulo,
                  ),
                ),
                FilterChip(
                  label: const Text('Todo o período'),
                  selected: _vm.mes == null,
                  showCheckmark: false,
                  selectedColor: AppColors.gold,
                  labelStyle: TextStyle(
                    color: _vm.mes == null ? AppColors.navyDark : Colors.white,
                  ),
                  onSelected: (v) => _vm.filtrarMes(v ? null : DateTime.now()),
                ),
                if (_vm.mes != null)
                  CompetenciaSelector(
                    value: _vm.mes!,
                    onChanged: _vm.filtrarMes,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${lista.length} registro(s)',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: lista.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: _vm.csv()),
                          );
                          if (context.mounted) {
                            mostrarMensagem(
                              context,
                              'Histórico copiado (CSV).',
                            );
                          }
                        },
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  label: const Text('Copiar (CSV)'),
                ),
              ],
            ),
            if (_vm.porUsuario.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final e in _vm.porUsuario.entries)
                    GoldChip(
                      '${_vm.nome(e.key)}: ${e.value}',
                      color: AppColors.blueGlow,
                    ),
                ],
              ),
            const SizedBox(height: 8),
            if (_vm.carregado && lista.isEmpty)
              const EmptyState(
                icon: Icons.history,
                message: 'Nenhuma atividade neste filtro.',
              ),
            ..._linhas(lista),
          ],
        );
      },
    );
  }

  /// Registros agrupados por dia.
  List<Widget> _linhas(List<Atividade> lista) {
    final widgets = <Widget>[];
    DateTime? dia;
    for (final a in lista) {
      final d = DateTime(a.quando.year, a.quando.month, a.quando.day);
      if (dia != d) {
        dia = d;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              formatDate(d),
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      widgets.add(_item(a));
    }
    return widgets;
  }

  Widget _item(Atividade a) {
    final hora =
        '${a.quando.hour.toString().padLeft(2, '0')}:${a.quando.minute.toString().padLeft(2, '0')}';
    return CardPadrao(
      borda: _cor(a.tipo),
      child: Row(
        children: [
          Icon(_icone(a.tipo), color: _cor(a.tipo)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.descricao,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    AvatarUsuario(nome: _vm.nome(a.usuarioId), raio: 9),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${_vm.nome(a.usuarioId)} • ${a.tipo.label}${a.modulo == null ? '' : ' • ${a.modulo!.label}'}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            hora,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
