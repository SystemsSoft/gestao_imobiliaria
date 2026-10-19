import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/auditoria.dart';
import '../viewmodels/auditoria_viewmodels.dart';

/// Prazos das pendências automáticas e modelos de checklist.
class ConfiguracaoAuditoriaTab extends StatefulWidget {
  const ConfiguracaoAuditoriaTab({super.key});

  @override
  State<ConfiguracaoAuditoriaTab> createState() =>
      _ConfiguracaoAuditoriaTabState();
}

typedef _Prazo = (
  String rotulo,
  String sufixo,
  int Function(ConfiguracaoAuditoria),
);

class _ConfiguracaoAuditoriaTabState extends State<ConfiguracaoAuditoriaTab> {
  final _vm = sl<ConfiguracaoAuditoriaViewModel>();
  final _campos = <TextEditingController>[];
  ConfiguracaoAuditoria? _carregada;

  static final List<_Prazo> _prazos = [
    (
      'Tolerância para repasse ao proprietário',
      'dias após o pagamento',
      (c) => c.prazoRepasseDias,
    ),
    ('Aluguel em atraso vira crítico após', 'dias', (c) => c.atrasoCriticoDias),
    ('Chamado sem resposta após', 'horas', (c) => c.chamadoSemRespostaHoras),
    ('Manutenção parada após', 'dias', (c) => c.manutencaoParadaDias),
    ('Auditar cada imóvel a cada', 'meses', (c) => c.mesesSemAuditoria),
    (
      'Avisar vencimento do contrato com',
      'dias de antecedência',
      (c) => c.avisoVencimentoContratoDias,
    ),
  ]; // fmt: skip

  @override
  void initState() {
    super.initState();
    _vm.addListener(_preencher);
  }

  void _preencher() {
    final c = _vm.configuracao;
    if (c == null || identical(c, _carregada)) return;
    _carregada = c;
    if (_campos.isEmpty) {
      _campos.addAll([for (final _ in _prazos) TextEditingController()]);
    }
    for (var i = 0; i < _prazos.length; i++) {
      _campos[i].text = '${_prazos[i].$3(c)}';
    }
  }

  @override
  void dispose() {
    _vm
      ..removeListener(_preencher)
      ..dispose();
    for (final c in _campos) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvarPrazos() async {
    int v(int i) => int.tryParse(_campos[i].text) ?? _prazos[i].$3(_carregada!);
    final c = ConfiguracaoAuditoria(
      prazoRepasseDias: v(0),
      atrasoCriticoDias: v(1),
      chamadoSemRespostaHoras: v(2),
      manutencaoParadaDias: v(3),
      mesesSemAuditoria: v(4),
      avisoVencimentoContratoDias: v(5),
    );
    final ok = await _vm.salvarConfiguracao(c);
    if (mounted) {
      mostrarMensagem(context, ok ? 'Prazos salvos.' : (_vm.erro ?? 'Erro.'));
    }
  }

  Future<void> _editarModelo([ModeloChecklist? m]) async {
    final novo = await showDialog<ModeloChecklist>(
      context: context,
      builder: (_) => _ModeloDialog(modelo: m),
    );
    if (novo == null) return;
    final ok = await _vm.salvarModelo(novo);
    if (mounted) {
      mostrarMensagem(context, ok ? 'Modelo salvo.' : (_vm.erro ?? 'Erro.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_vm.configuracao == null) {
          return _vm.erro != null
              ? Center(child: Text(_vm.erro!))
              : const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 64),
              children: [
                FormSection(
                  title: 'Pendências automáticas',
                  icon: Icons.notification_important_outlined,
                  children: [
                    const Text(
                      'A aba Pendências confere todos os contratos ativos com '
                      'estes prazos (nada precisa ser cadastrado à mão).',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _prazos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: AppTextField(
                          label: _prazos[i].$1,
                          suffixText: _prazos[i].$2,
                          controller: _campos[i],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _vm.ocupado ? null : _salvarPrazos,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar prazos'),
                      ),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Modelos de checklist',
                  icon: Icons.checklist,
                  children: [
                    const Text(
                      'O modelo padrão é usado nas novas auditorias. Os itens '
                      'podem ser ajustados em cada auditoria.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    for (final m in _vm.modelos)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          m.padrao ? Icons.star : Icons.list_alt,
                          color: AppColors.gold,
                        ),
                        title: Text(m.nome),
                        subtitle: Text(
                          '${m.itens.length} itens em '
                          '${m.itens.map((i) => i.area).toSet().length} áreas'
                          '${m.padrao ? ' • padrão' : ''}',
                        ),
                        onTap: () => _editarModelo(m),
                        trailing: IconButton(
                          tooltip: 'Excluir',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (await confirmDelete(
                              context,
                              'Excluir o modelo "${m.nome}"?',
                            )) {
                              await _vm.removerModelo(m);
                            }
                          },
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _editarModelo(),
                        icon: const Icon(Icons.add),
                        label: const Text('Novo modelo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Edita o modelo: uma linha por item, no formato "Área: item".
class _ModeloDialog extends StatefulWidget {
  const _ModeloDialog({this.modelo});

  final ModeloChecklist? modelo;

  @override
  State<_ModeloDialog> createState() => _ModeloDialogState();
}

class _ModeloDialogState extends State<_ModeloDialog> {
  late final _nome = TextEditingController(text: widget.modelo?.nome);
  late final _itens = TextEditingController(
    text: [
      for (final i in widget.modelo?.itens ?? const <ItemModelo>[])
        '${i.area}: ${i.item}',
    ].join('\n'),
  );
  late bool _padrao = widget.modelo?.padrao ?? false;
  String? _erro;

  void _salvar() {
    final itens = <ItemModelo>[];
    for (final linha in _itens.text.split('\n')) {
      if (linha.trim().isEmpty) continue;
      final p = linha.indexOf(':');
      if (p <= 0 || linha.substring(p + 1).trim().isEmpty) {
        setState(() => _erro = 'Use "Área: item" em cada linha ($linha).');
        return;
      }
      itens.add((
        area: linha.substring(0, p).trim(),
        item: linha.substring(p + 1).trim(),
      ));
    }
    if (_nome.text.trim().isEmpty || itens.isEmpty) {
      setState(() => _erro = 'Informe o nome e ao menos um item.');
      return;
    }
    Navigator.pop(
      context,
      ModeloChecklist(
        id: widget.modelo?.id ?? gerarId(),
        nome: _nome.text.trim(),
        itens: itens,
        padrao: _padrao,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(widget.modelo == null ? 'Novo modelo' : 'Editar modelo'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Nome', controller: _nome),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Itens (um por linha: "Área: item")',
                hint: 'Cozinha: Torneiras e sifão',
                controller: _itens,
                maxLines: 14,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _padrao,
                activeThumbColor: AppColors.gold,
                title: const Text('Modelo padrão das novas auditorias'),
                onChanged: (v) => setState(() => _padrao = v),
              ),
              if (_erro != null)
                Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
