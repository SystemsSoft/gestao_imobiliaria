import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/evento.dart';
import '../viewmodels/evento_form_viewmodel.dart';

/// Abre o formulário de evento. Use [evento] para editar ou [modelo] para
/// criar um novo já preenchido (o id do modelo é ignorado).
Future<void> showEventoDialog(
  BuildContext context, {
  Evento? evento,
  Evento? modelo,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EventoDialog(evento: evento, modelo: modelo),
  );
}

class _EventoDialog extends StatefulWidget {
  const _EventoDialog({this.evento, this.modelo});

  final Evento? evento;
  final Evento? modelo;

  @override
  State<_EventoDialog> createState() => _EventoDialogState();
}

class _EventoDialogState extends State<_EventoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vm = sl<EventoFormViewModel>();

  late final Evento? _base = widget.evento ?? widget.modelo;
  late TipoEvento _tipo = _base?.tipo ?? TipoEvento.lembrete;
  late final _titulo = TextEditingController(text: _base?.titulo);
  late final _descricao = TextEditingController(text: _base?.descricao);
  late DateTime? _dataHora = _base?.dataHora;
  late Prioridade _prioridade = _base?.prioridade ?? Prioridade.normal;
  late String? _contatoId = _base?.contatoId;
  late String? _imovelId = _base?.imovelId;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _vm.salvar(
      Evento(
        id: widget.evento?.id ?? gerarId(),
        criadoEm: widget.evento?.criadoEm ?? DateTime.now(),
        concluido: widget.evento?.concluido ?? false,
        tipo: _tipo,
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        dataHora: _dataHora,
        prioridade: _prioridade,
        contatoId: _contatoId,
        imovelId: _imovelId,
      ),
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_vm.erro ?? 'Não foi possível salvar.')),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => _buildDialog(context),
    );
  }

  Widget _buildDialog(BuildContext context) {
    final contatos = _vm.contatos;
    final imoveis = _vm.imoveis;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(
        widget.evento == null ? 'Novo item da agenda' : 'Editar item',
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                AppDropdown<TipoEvento>(
                  label: 'Tipo',
                  value: _tipo,
                  items: TipoEvento.values,
                  labelOf: (e) => e.label,
                  onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Título *',
                  controller: _titulo,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o título'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Detalhes',
                  controller: _descricao,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                DateField(
                  label: _tipo == TipoEvento.anotacao
                      ? 'Data e hora (opcional)'
                      : 'Data e hora *',
                  value: _dataHora,
                  withTime: true,
                  onChanged: (d) => setState(() => _dataHora = d),
                ),
                const SizedBox(height: 12),
                AppDropdown<Prioridade>(
                  label: 'Prioridade',
                  value: _prioridade,
                  items: Prioridade.values,
                  labelOf: (e) => e.label,
                  onChanged: (v) =>
                      setState(() => _prioridade = v ?? _prioridade),
                ),
                const SizedBox(height: 12),
                AppDropdown<String?>(
                  label: 'Contato',
                  value: contatos.any((c) => c.id == _contatoId)
                      ? _contatoId
                      : null,
                  items: [null, ...contatos.map((c) => c.id)],
                  labelOf: (id) => id == null
                      ? 'Nenhum'
                      : contatos.firstWhere((c) => c.id == id).nome,
                  onChanged: (v) => setState(() => _contatoId = v),
                ),
                const SizedBox(height: 12),
                AppDropdown<String?>(
                  label: 'Imóvel',
                  value: imoveis.any((i) => i.id == _imovelId)
                      ? _imovelId
                      : null,
                  items: [null, ...imoveis.map((i) => i.id)],
                  labelOf: (id) {
                    if (id == null) return 'Nenhum';
                    final i = imoveis.firstWhere((i) => i.id == id);
                    return '${i.codigo} - ${i.titulo}';
                  },
                  onChanged: (v) => setState(() => _imovelId = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvar,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navyDark,
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
