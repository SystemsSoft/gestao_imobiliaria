import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/documento.dart';

enum _Filtro { todos, inquilinos, proprietarios }

/// Escolhe os inquilinos e proprietários que veem a pasta na área deles do
/// portal. Devolve os ids escolhidos, ou null ao cancelar.
Future<Set<String>?> mostrarCompartilharPastaDialog(
  BuildContext context, {
  required PastaDocumento pasta,
  required List<Destinatario> destinatarios,
}) => showDialog<Set<String>>(
  context: context,
  builder: (_) =>
      _CompartilharDialog(pasta: pasta, destinatarios: destinatarios),
);

class _CompartilharDialog extends StatefulWidget {
  const _CompartilharDialog({required this.pasta, required this.destinatarios});

  final PastaDocumento pasta;
  final List<Destinatario> destinatarios;

  @override
  State<_CompartilharDialog> createState() => _CompartilharDialogState();
}

class _CompartilharDialogState extends State<_CompartilharDialog> {
  late final _escolhidos = {...widget.pasta.compartilhadaCom};
  var _filtro = _Filtro.todos;
  var _busca = '';

  List<Destinatario> get _visiveis {
    final b = _busca.toLowerCase();
    final digitos = _busca.replaceAll(RegExp(r'\D'), '');
    return [
      for (final d in widget.destinatarios)
        if (switch (_filtro) {
              _Filtro.todos => true,
              _Filtro.inquilinos => d.inquilino,
              _Filtro.proprietarios => d.proprietario,
            } &&
            (b.isEmpty ||
                d.nome.toLowerCase().contains(b) ||
                (digitos.isNotEmpty &&
                    d.documento
                        .replaceAll(RegExp(r'\D'), '')
                        .contains(digitos))))
          d,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visiveis = _visiveis;
    final todosMarcados =
        visiveis.isNotEmpty &&
        visiveis.every((d) => _escolhidos.contains(d.id));
    final altura = (MediaQuery.sizeOf(context).height * 0.5).clamp(
      200.0,
      420.0,
    );
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text('Compartilhar "${widget.pasta.nome}"'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quem você marcar vê a pasta e os documentos dela na Área do '
              'inquilino ou do proprietário, no site.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _busca = v.trim()),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou CPF/CNPJ...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (f, rotulo) in const [
                  (_Filtro.todos, 'Todos'),
                  (_Filtro.inquilinos, 'Inquilinos'),
                  (_Filtro.proprietarios, 'Proprietários'),
                ])
                  ChoiceChip(
                    label: Text(rotulo),
                    selected: _filtro == f,
                    selectedColor: AppColors.gold,
                    labelStyle: TextStyle(
                      color: _filtro == f ? AppColors.navyDark : Colors.white,
                    ),
                    onSelected: (_) => setState(() => _filtro = f),
                  ),
              ],
            ),
            if (visiveis.isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.gold,
                checkColor: AppColors.navyDark,
                value: todosMarcados,
                title: Text(
                  'Marcar todos da lista (${visiveis.length})',
                  style: TextStyle(color: AppColors.goldLight),
                ),
                onChanged: (v) => setState(() {
                  final ids = visiveis.map((d) => d.id);
                  v == true
                      ? _escolhidos.addAll(ids)
                      : _escolhidos.removeAll(ids);
                }),
              ),
            const Divider(color: Colors.white12, height: 1),
            Flexible(
              child: SizedBox(
                height: altura,
                child: widget.destinatarios.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum inquilino ou proprietário cadastrado.\n'
                          'Marque o papel "Locatário" ou "Proprietário" no '
                          'cadastro do contato, em Cadastros e CRM.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : visiveis.isEmpty
                    ? const Center(
                        child: Text(
                          'Ninguém encontrado com essa busca.',
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : ListView(children: [for (final d in visiveis) _linha(d)]),
              ),
            ),
          ],
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
          onPressed: () => Navigator.pop(context, _escolhidos),
          child: Text(
            _escolhidos.isEmpty
                ? 'Salvar (só a equipe)'
                : 'Compartilhar com ${_escolhidos.length}',
          ),
        ),
      ],
    );
  }

  Widget _linha(Destinatario d) {
    final papeis = [
      if (d.inquilino) 'Inquilino',
      if (d.proprietario) 'Proprietário',
    ].join(' • ');
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.gold,
      checkColor: AppColors.navyDark,
      value: _escolhidos.contains(d.id),
      onChanged: (v) => setState(
        () => v == true ? _escolhidos.add(d.id) : _escolhidos.remove(d.id),
      ),
      title: Text(d.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [papeis, if (d.documento.isNotEmpty) d.documento].join(' • '),
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          if (!d.temAcesso)
            const Text(
              'Sem acesso liberado ao portal: só verá a pasta depois da liberação.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
