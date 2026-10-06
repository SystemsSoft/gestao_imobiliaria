import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../pages/modelo_editor_page.dart';
import '../viewmodels/modelos_viewmodel.dart';
import 'modelos_prontos_tab.dart';
import 'previa_modelo_dialog.dart';

/// "Meus modelos": lista dos modelos do usuário. Com [tipo], mostra só os
/// modelos daquele tipo.
class ModelosTab extends StatefulWidget {
  const ModelosTab({super.key, this.tipo});

  final TipoModelo? tipo;

  @override
  State<ModelosTab> createState() => _ModelosTabState();
}

class _ModelosTabState extends State<ModelosTab> {
  late final _vm = sl<ModelosViewModel>(param1: widget.tipo);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _editar(ModeloContrato m) => Navigator.of(
    context,
  ).push(MaterialPageRoute<bool>(builder: (_) => ModeloEditorPage(modelo: m)));

  Future<void> _novo() async {
    var tipo = widget.tipo ?? TipoModelo.locacao;
    final escolhido =
        widget.tipo ??
        await showDialog<TipoModelo>(
          context: context,
          builder: (ctx) => SimpleDialog(
            backgroundColor: AppColors.navy,
            title: const Text('Novo modelo em branco: qual tipo?'),
            children: [
              for (final t in TipoModelo.values)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, t),
                  child: ListTile(
                    dense: true,
                    leading: Icon(iconeDoTipo(t), color: AppColors.gold),
                    title: Text(t.label),
                    subtitle: Text(t.descricao),
                  ),
                ),
            ],
          ),
        );
    if (escolhido == null || !mounted) return;
    tipo = escolhido;
    _editar(
      ModeloContrato(
        id: '',
        nome: 'Novo modelo',
        tipo: tipo,
        texto: textoInicial(tipo),
      ),
    );
  }

  Future<void> _acao(Future<bool> Function() f, [String? sucesso]) async {
    final ok = await f();
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível concluir.');
    } else if (sucesso != null) {
      mostrarMensagem(context, sucesso);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.post_add,
        label: 'Novo modelo',
        onPressed: _novo,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.filtrados;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              const Text(
                'Seus modelos, editáveis. Os campos {{assim}} são preenchidos automaticamente na impressão; '
                'os parâmetros que você criar usam o valor padrão.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: _vm.buscar,
                decoration: const InputDecoration(
                  hintText: 'Buscar nos meus modelos...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              if (widget.tipo == null)
                FiltroChips<TipoModelo>(
                  opcoes: TipoModelo.values,
                  selecionado: _vm.filtroTipo,
                  labelOf: (t) => t.label,
                  onChanged: _vm.filtrar,
                  padding: EdgeInsets.zero,
                ),
              if (_vm.carregado && lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EmptyState(
                    icon: Icons.article_outlined,
                    message:
                        'Nenhum modelo aqui.\nUse "Novo modelo" ou escolha um em "Modelos prontos".',
                  ),
                ),
              for (final m in lista) _card(m),
            ],
          );
        },
      ),
    );
  }

  Widget _card(ModeloContrato m) {
    final base = _vm.nomePronto(m.baseId);
    return CardPadrao(
      onTap: () => _editar(m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            foregroundColor: AppColors.gold,
            child: Icon(iconeDoTipo(m.tipo)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (m.descricao.isNotEmpty)
                  Text(
                    m.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    GoldChip(m.tipo.label),
                    if (base != null)
                      GoldChip('Baseado em: $base', color: AppColors.blueGlow),
                    if (m.parametros.isNotEmpty)
                      GoldChip(
                        '${m.parametros.length} parâmetros',
                        color: Colors.greenAccent,
                      ),
                    if (m.atualizadoEm != null)
                      GoldChip(
                        'Atualizado ${formatDate(m.atualizadoEm)}',
                        color: Colors.white54,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.navy,
            onSelected: (v) => switch (v) {
              'editar' => _editar(m),
              'ver' => mostrarPreviaDialog(
                context,
                titulo: m.nome,
                texto: _vm.previa(m),
              ),
              'pdf' => _acao(() => _vm.imprimirExemplo(m)),
              'duplicar' => _acao(() => _vm.duplicar(m), 'Modelo duplicado.'),
              'restaurar' => _acao(
                () => _vm.restaurar(m),
                'Texto original restaurado.',
              ),
              _ => () async {
                if (await confirmDelete(
                  context,
                  'Excluir o modelo "${m.nome}"?',
                )) {
                  await _acao(() => _vm.remover(m.id));
                }
              }(),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              const PopupMenuItem(value: 'ver', child: Text('Visualizar')),
              const PopupMenuItem(
                value: 'pdf',
                child: Text('Imprimir exemplo (PDF)'),
              ),
              const PopupMenuItem(value: 'duplicar', child: Text('Duplicar')),
              if (m.derivadoDePronto)
                const PopupMenuItem(
                  value: 'restaurar',
                  child: Text('Restaurar texto original'),
                ),
              const PopupMenuItem(value: 'del', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
