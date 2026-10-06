import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/parametro_modelo.dart';

/// Cria ou edita um parâmetro. [validar] devolve a mensagem de erro (ou
/// null); [chaveDoRotulo] sugere a chave a partir do nome do campo.
Future<ParametroModelo?> mostrarParametroDialog(
  BuildContext context, {
  ParametroModelo? parametro,
  String chaveInicial = '',
  required String Function(String rotulo) chaveDoRotulo,
  required String? Function(ParametroModelo) validar,
}) => showDialog(
  context: context,
  builder: (_) => _ParametroDialog(
    parametro: parametro,
    chaveInicial: chaveInicial,
    chaveDoRotulo: chaveDoRotulo,
    validar: validar,
  ),
);

class _ParametroDialog extends StatefulWidget {
  const _ParametroDialog({
    required this.parametro,
    required this.chaveInicial,
    required this.chaveDoRotulo,
    required this.validar,
  });

  final ParametroModelo? parametro;
  final String chaveInicial;
  final String Function(String) chaveDoRotulo;
  final String? Function(ParametroModelo) validar;

  @override
  State<_ParametroDialog> createState() => _ParametroDialogState();
}

class _ParametroDialogState extends State<_ParametroDialog> {
  ParametroModelo? get _p => widget.parametro;
  late final _rotulo = TextEditingController(
    text: _p?.rotulo ?? widget.chaveInicial.replaceAll('_', ' '),
  );
  late final _chave = TextEditingController(
    text: _p?.chave ?? widget.chaveInicial,
  );
  late final _valor = TextEditingController(text: _p?.valorPadrao);
  late final _descricao = TextEditingController(text: _p?.descricao);
  late TipoParametro _tipo = _p?.tipo ?? TipoParametro.texto;
  late bool _chaveManual = _p != null || widget.chaveInicial.isNotEmpty;
  String? _erro;

  @override
  void dispose() {
    for (final c in [_rotulo, _chave, _valor, _descricao]) {
      c.dispose();
    }
    super.dispose();
  }

  ParametroModelo _montar() => ParametroModelo(
    chave: _chave.text.trim(),
    rotulo: _rotulo.text.trim(),
    tipo: _tipo,
    valorPadrao: _valor.text.trim(),
    descricao: _descricao.text.trim(),
  );

  void _salvar() {
    final p = _montar();
    final erro = widget.validar(p);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(_p == null ? 'Novo parâmetro' : 'Editar parâmetro'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              AppTextField(
                label: 'Nome do campo *',
                hint: 'Ex.: Cidade do foro',
                controller: _rotulo,
                onChanged: (v) {
                  if (!_chaveManual) {
                    setState(() => _chave.text = widget.chaveDoRotulo(v));
                  }
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Chave no texto *',
                hint: 'foro_cidade',
                controller: _chave,
                onChanged: (_) => setState(() {
                  _chaveManual = true;
                  _erro = null;
                }),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Uso no texto: {{${_chave.text.isEmpty ? 'chave' : _chave.text}}}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppDropdown<TipoParametro>(
                    label: 'Tipo',
                    value: _tipo,
                    items: TipoParametro.values,
                    labelOf: (e) => e.label,
                    onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                  ),
                  AppTextField(label: 'Valor padrão', controller: _valor),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Descrição (opcional)',
                controller: _descricao,
                maxLines: 2,
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _erro!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navyDark,
          ),
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
