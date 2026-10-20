import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/sicoob.dart';
import '../pages/integracao_sicoob_page.dart';
import '../viewmodels/integracao_sicoob_viewmodel.dart';

/// Cobranças Pix (API Pix Recebimentos) e Pix recebidos no período.
class PixSicoobTab extends StatefulWidget {
  const PixSicoobTab({super.key, required this.vm});

  final IntegracaoSicoobViewModel vm;

  @override
  State<PixSicoobTab> createState() => _PixSicoobTabState();
}

class _PixSicoobTabState extends State<PixSicoobTab> {
  DateTime _inicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fim = DateTime.now();

  IntegracaoSicoobViewModel get _vm => widget.vm;

  Future<void> _nova() async {
    final dados = await showDialog<NovoPixSicoob>(
      context: context,
      builder: (_) => _PixDialog(vm: _vm),
    );
    if (dados == null || !mounted) return;
    if (!await _vm.criarPix(dados)) {
      if (mounted) mostrarMensagem(context, _vm.erro ?? 'Erro.');
      return;
    }
    if (mounted) await _mostrarQr(_vm.pixCriado!);
  }

  Future<void> _mostrarQr(PixSicoob p) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text('Pix de ${formatMoney(p.valor)}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.qrCodePng.startsWith('data:'))
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  UriData.parse(p.qrCodePng).contentAsBytes(),
                  width: 240,
                  height: 240,
                ),
              ),
            const SizedBox(height: 12),
            SelectableText(
              p.copiaECola.isEmpty ? '(sem copia e cola)' : p.copiaECola,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
            ),
            const SizedBox(height: 8),
            Text(
              'txid ${p.txid} · ${p.status}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        if (p.copiaECola.isNotEmpty)
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: p.copiaECola));
              if (ctx.mounted) mostrarMensagem(ctx, 'Copia e cola copiado.');
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );

  Future<void> _consultar(PixSicoob p) async {
    if (!await _vm.consultarPix(p)) {
      if (mounted) mostrarMensagem(context, _vm.erro ?? 'Erro.');
      return;
    }
    if (mounted) await _mostrarQr(_vm.pixCriado!);
  }

  Future<void> _recebidos() async {
    if (!await _vm.buscarRecebidos(_inicio, _fim) && mounted) {
      mostrarMensagem(context, _vm.erro ?? 'Erro.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.qr_code_2,
        label: 'Nova cobrança Pix',
        onPressed: _nova,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final m = margemSicoob(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(m, 16, m, 96),
            children: [
              if (!_vm.pronto) avisoConfigurar(),
              FormSection(
                title: 'Cobranças Pix',
                icon: Icons.qr_code_2,
                children: [
                  const Text(
                    'Cobrança imediata (cob) com QR code e copia e cola, '
                    'usando a chave Pix da Configuração.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  if (_vm.pix.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Nenhuma cobrança Pix ainda.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  for (final p in _vm.pix)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.pix, color: AppColors.gold),
                      title: Text(
                        '${formatMoney(p.valor)}'
                        '${p.devedorNome.isNotEmpty ? ' · ${p.devedorNome}' : ''}',
                      ),
                      subtitle: Text(
                        [
                          formatDateTime(p.criadoEm),
                          if (p.descricao.isNotEmpty) p.descricao,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: GoldChip(
                        p.status,
                        color: p.status == 'CONCLUIDA'
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                      onTap: _vm.ocupado ? null : () => _consultar(p),
                    ),
                ],
              ),
              FormSection(
                title: 'Pix recebidos',
                icon: Icons.call_received,
                children: [
                  FieldRow(
                    children: [
                      DateField(
                        label: 'De',
                        value: _inicio,
                        onChanged: (d) =>
                            setState(() => _inicio = d ?? _inicio),
                      ),
                      DateField(
                        label: 'Até',
                        value: _fim,
                        onChanged: (d) => setState(() => _fim = d ?? _fim),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _vm.ocupado ? null : _recebidos,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar recebidos'),
                    ),
                  ),
                  for (final r in _vm.recebidos)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.call_received,
                        color: Colors.greenAccent,
                      ),
                      title: Text(
                        '${formatMoney(r.valor)}'
                        '${r.pagador.isNotEmpty ? ' · ${r.pagador}' : ''}',
                      ),
                      subtitle: Text(
                        [r.horario, if (r.info.isNotEmpty) r.info].join(' · '),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PixDialog extends StatefulWidget {
  const _PixDialog({required this.vm});

  final IntegracaoSicoobViewModel vm;

  @override
  State<_PixDialog> createState() => _PixDialogState();
}

class _PixDialogState extends State<_PixDialog> {
  final _valor = TextEditingController();
  final _nome = TextEditingController();
  final _documento = TextEditingController();
  final _descricao = TextEditingController();
  final _horas = TextEditingController(text: '24');
  String? _cobrancaId;
  String? _erro;

  Future<void> _usarCobranca(String? id) async {
    setState(() => _cobrancaId = id);
    if (id == null) return;
    final r = await widget.vm.rascunho(id);
    if (r == null || !mounted) return;
    setState(() {
      _valor.text = moneyToText(r.valor);
      _nome.text = r.pagador.nome;
      _documento.text = r.pagador.documento;
      _descricao.text = r.descricao;
    });
  }

  @override
  Widget build(BuildContext context) {
    final abertas = widget.vm.cobrancasAbertas;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Nova cobrança Pix'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<String?>(
                label: 'Preencher com uma cobrança do aluguel (opcional)',
                value: _cobrancaId,
                items: [null, ...abertas.map((c) => c.id)],
                labelOf: (id) {
                  if (id == null) return 'Dados livres';
                  final c = abertas.firstWhere((x) => x.id == id);
                  return '${c.descricao} · ${c.locatario} · ${formatMoney(c.valor)}';
                },
                onChanged: _usarCobranca,
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppTextField.money(label: 'Valor', controller: _valor),
                  AppTextField.integer(
                    label: 'Validade (horas)',
                    controller: _horas,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppTextField(label: 'Pagador (opcional)', controller: _nome),
                  AppTextField(
                    label: 'CPF/CNPJ (opcional)',
                    controller: _documento,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Descrição para o pagador',
                controller: _descricao,
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
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
          onPressed: () {
            final valor = parseMoney(_valor.text) ?? 0;
            if (valor <= 0) {
              setState(() => _erro = 'Informe o valor.');
              return;
            }
            Navigator.pop(
              context,
              NovoPixSicoob(
                valor: valor,
                devedorNome: _nome.text.trim(),
                devedorDocumento: _documento.text,
                descricao: _descricao.text.trim(),
                expiracaoHoras: int.tryParse(_horas.text) ?? 24,
                cobrancaId: _cobrancaId,
              ),
            );
          },
          child: const Text('Gerar Pix'),
        ),
      ],
    );
  }
}
