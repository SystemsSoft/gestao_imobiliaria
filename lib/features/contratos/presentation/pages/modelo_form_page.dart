import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../viewmodels/modelos_viewmodel.dart';

/// Editor de modelo de contrato. Um [modelo] com id vazio cria um novo
/// a partir do texto informado (usado em "Duplicar").
class ModeloFormPage extends StatefulWidget {
  const ModeloFormPage({super.key, required this.tipo, this.modelo});

  final TipoModelo tipo;
  final ModeloContrato? modelo;

  @override
  State<ModeloFormPage> createState() => _ModeloFormPageState();
}

class _ModeloFormPageState extends State<ModeloFormPage> {
  late final _vm = sl<ModelosViewModel>(param1: widget.tipo);
  late final _nome = TextEditingController(text: widget.modelo?.nome);
  late final _texto = TextEditingController(text: widget.modelo?.texto.trim());

  @override
  void dispose() {
    _nome.dispose();
    _texto.dispose();
    _vm.dispose();
    super.dispose();
  }

  /// Insere o campo na posição do cursor.
  void _inserir(String campo) {
    final tag = '{{$campo}}';
    final sel = _texto.selection;
    final texto = _texto.text;
    final inicio = sel.isValid ? sel.start : texto.length;
    final fim = sel.isValid ? sel.end : texto.length;
    _texto.value = TextEditingValue(
      text: texto.replaceRange(inicio, fim, tag),
      selection: TextSelection.collapsed(offset: inicio + tag.length),
    );
  }

  Future<void> _salvar() async {
    final id = widget.modelo?.id ?? '';
    final ok = await _vm.salvar(
      ModeloContrato(
        id: id.isEmpty ? gerarId() : id,
        nome: _nome.text.trim(),
        tipo: widget.tipo,
        texto: _texto.text,
      ),
    );
    if (!mounted) return;
    if (!ok) {
      return mostrarMensagem(context, _vm.erro ?? 'Não foi possível salvar.');
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Modelo salvo.')));
  }

  @override
  Widget build(BuildContext context) {
    final campos = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in _vm.campos.entries)
          Tooltip(
            message: e.value,
            child: ActionChip(
              label: Text('{{${e.key}}}', style: const TextStyle(fontSize: 12)),
              onPressed: () => _inserir(e.key),
            ),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text(
          widget.modelo?.id.isNotEmpty ?? false
              ? 'Editar modelo'
              : 'Novo modelo',
        ),
        actions: [
          TextButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: const Text('SALVAR'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(label: 'Nome do modelo', controller: _nome),
            const SizedBox(height: 12),
            const Text(
              'A primeira linha é o título do contrato. Toque em um campo para '
              'inseri-lo na posição do cursor.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(child: campos),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _texto,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(height: 1.5),
                decoration: const InputDecoration(
                  labelText: 'Texto do contrato',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
