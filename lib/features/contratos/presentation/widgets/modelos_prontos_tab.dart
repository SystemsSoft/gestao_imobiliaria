import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../../domain/entities/modelo_pronto.dart';
import '../pages/modelo_editor_page.dart';
import '../viewmodels/modelos_prontos_viewmodel.dart';
import 'previa_modelo_dialog.dart';

IconData iconeDoTipo(TipoModelo t) => switch (t) {
  TipoModelo.locacao => Icons.key_outlined,
  TipoModelo.temporada => Icons.beach_access_outlined,
  TipoModelo.venda => Icons.sell_outlined,
  TipoModelo.administracao => Icons.home_work_outlined,
  TipoModelo.autorizacao => Icons.assignment_turned_in_outlined,
  TipoModelo.outros => Icons.description_outlined,
};

/// Galeria de modelos prontos: visualize e use como base para o seu.
class ModelosProntosTab extends StatefulWidget {
  const ModelosProntosTab({super.key});

  @override
  State<ModelosProntosTab> createState() => _ModelosProntosTabState();
}

class _ModelosProntosTabState extends State<ModelosProntosTab> {
  final _vm = sl<ModelosProntosViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _usar(ModeloPronto p) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => ModeloEditorPage(modelo: p.comoRascunho()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final lista = _vm.filtrados;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text(
              'Modelos prontos para uso. Escolha um, personalize no editor e ele será salvo em '
              '"Meus modelos". As minutas são gerais: revise com um advogado antes de usar com clientes.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: _vm.buscar,
              decoration: const InputDecoration(
                hintText: 'Buscar modelo...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final t in <TipoModelo?>[null, ...TipoModelo.values])
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                        top: 8,
                        bottom: 8,
                      ),
                      child: ChoiceChip(
                        label: Text(
                          '${t?.label ?? 'Todos'} (${_vm.quantidade(t)})',
                        ),
                        selected: _vm.filtroTipo == t,
                        selectedColor: AppColors.gold,
                        labelStyle: TextStyle(
                          color: _vm.filtroTipo == t
                              ? AppColors.navyDark
                              : Colors.white,
                        ),
                        onSelected: (_) => _vm.filtrar(t),
                      ),
                    ),
                ],
              ),
            ),
            if (_vm.carregado && lista.isEmpty)
              const EmptyState(
                icon: Icons.search_off,
                message: 'Nenhum modelo encontrado.',
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final p in lista) _card(p)],
            ),
          ],
        );
      },
    );
  }

  Widget _card(ModeloPronto p) {
    return SizedBox(
      width: 360,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                  foregroundColor: AppColors.gold,
                  child: Icon(iconeDoTipo(p.tipo)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p.descricao,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                GoldChip(p.tipo.label),
                GoldChip(
                  '${_vm.camposUsados(p)} campos',
                  color: AppColors.blueGlow,
                ),
                if (p.parametros.isNotEmpty)
                  GoldChip(
                    '${p.parametros.length} parâmetros',
                    color: Colors.greenAccent,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => mostrarPreviaDialog(
                    context,
                    titulo: p.nome,
                    texto: _vm.previa(p),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Visualizar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _usar(p),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                  ),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Usar este modelo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
