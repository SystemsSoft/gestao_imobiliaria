import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/permissoes.dart';
import '../viewmodels/permissoes_viewmodel.dart';
import 'avatar_usuario.dart';

/// Permissões de acesso configuráveis por usuário.
class PermissoesTab extends StatefulWidget {
  const PermissoesTab({super.key});

  @override
  State<PermissoesTab> createState() => _PermissoesTabState();
}

class _PermissoesTabState extends State<PermissoesTab> {
  final _vm = sl<PermissoesViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final ok = await _vm.salvar();
    if (!mounted) return;
    mostrarMensagem(
      context,
      ok ? 'Permissões salvas.' : _vm.erro ?? 'Não foi possível salvar.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final u = _vm.selecionado;
        if (!_vm.carregado || u == null) {
          return const EmptyState(
            icon: Icons.lock_outline,
            message: 'Nenhum usuário cadastrado.',
          );
        }
        final p = _vm.permissoes;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                AvatarUsuario(nome: u.nome),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown<String>(
                    label: 'Usuário',
                    value: u.id,
                    items: _vm.usuarios.map((x) => x.id).toList(),
                    labelOf: (id) {
                      final x = _vm.usuarios.firstWhere((e) => e.id == id);
                      return '${x.nome}${x.ativo ? '' : ' (desativado)'}';
                    },
                    onChanged: _vm.selecionar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: AppDropdown<PerfilAcesso>(
                    label: 'Aplicar perfil padrão',
                    value: _vm.perfil,
                    items: PerfilAcesso.values,
                    labelOf: (x) => x.label,
                    onChanged: (v) {
                      if (v != null) _vm.aplicarPerfil(v);
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.navy,
                  tooltip: 'Copiar permissões de outro usuário',
                  onSelected: (id) =>
                      _vm.copiarDe(_vm.usuarios.firstWhere((x) => x.id == id)),
                  itemBuilder: (_) => [
                    for (final x in _vm.usuarios.where((x) => x.id != u.id))
                      PopupMenuItem(
                        value: x.id,
                        child: Text('Copiar de ${x.nome}'),
                      ),
                  ],
                  child: const Chip(
                    avatar: Icon(Icons.copy_all_outlined, size: 18),
                    label: Text('Copiar de outro usuário'),
                  ),
                ),
                Text(
                  '${p.totalAcoes} ação(ões) liberada(s) nos módulos',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            if (_vm.alterado)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Alterações ainda não salvas.')),
                    TextButton(
                      onPressed: _vm.descartar,
                      child: const Text('Descartar'),
                    ),
                    FilledButton(
                      onPressed: _vm.ocupado ? null : _salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                      ),
                      child: const Text('Salvar permissões'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FormSection(
              title: 'Acesso aos módulos',
              icon: Icons.apps_outlined,
              children: [_matriz(p)],
            ),
            FormSection(
              title: 'Permissões especiais',
              icon: Icons.verified_user_outlined,
              children: [
                for (final e in PermissaoEspecial.values)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(e.label),
                    subtitle: Text(
                      e.descricao,
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: p.temEspecial(e),
                    activeThumbColor: AppColors.gold,
                    onChanged: (v) => _vm.alternarEspecial(e, v),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _matriz(Permissoes p) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 22,
        headingTextStyle: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
        columns: [
          const DataColumn(label: Text('Módulo')),
          const DataColumn(label: Text('Tudo')),
          for (final a in AcaoPermissao.values)
            DataColumn(label: Text(a.label)),
        ],
        rows: [
          for (final m in ModuloSistema.values)
            DataRow(
              cells: [
                DataCell(Text(m.label)),
                DataCell(
                  Checkbox(
                    value: AcaoPermissao.values.every((a) => p.pode(m, a)),
                    activeColor: AppColors.gold,
                    checkColor: AppColors.navyDark,
                    onChanged: (v) => _vm.alternarModulo(m, v ?? false),
                  ),
                ),
                for (final a in AcaoPermissao.values)
                  DataCell(
                    Checkbox(
                      value: p.pode(m, a),
                      activeColor: AppColors.gold,
                      checkColor: AppColors.navyDark,
                      onChanged: (v) => _vm.alternarAcao(m, a, v ?? false),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
