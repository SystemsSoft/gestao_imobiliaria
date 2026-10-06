import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../pages/modelo_form_page.dart';
import '../viewmodels/modelos_viewmodel.dart';

/// Modelos de contrato personalizáveis usados na impressão.
class ModelosTab extends StatefulWidget {
  const ModelosTab({super.key});

  @override
  State<ModelosTab> createState() => _ModelosTabState();
}

class _ModelosTabState extends State<ModelosTab> {
  final _vm = sl<ModelosViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrir([ModeloContrato? m]) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ModeloFormPage(modelo: m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.post_add,
        label: 'Novo modelo',
        onPressed: _abrir,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          children: [
            const Text(
              'Personalize o texto dos contratos. Use campos como '
              '{{locatario_nome}} e {{valor_aluguel}}: eles são preenchidos '
              'automaticamente ao imprimir o contrato.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            for (final m in _vm.modelos)
              CardPadrao(
                onTap: () => _abrir(m),
                child: Row(
                  children: [
                    const Icon(Icons.article_outlined, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.nome,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            m.texto.trim().split('\n').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Duplicar',
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () => _abrir(
                        ModeloContrato(
                          id: '',
                          nome: '${m.nome} (cópia)',
                          texto: m.texto,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await confirmDelete(
                              context,
                              'Excluir o modelo "${m.nome}"?',
                            ) &&
                            !await _vm.remover(m.id) &&
                            context.mounted) {
                          mostrarMensagem(context, _vm.erro!);
                        }
                      },
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
