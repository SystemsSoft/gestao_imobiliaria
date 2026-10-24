import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/pdf/pdf_kit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/sicoob.dart';
import '../pages/integracao_sicoob_page.dart';
import '../viewmodels/integracao_sicoob_viewmodel.dart';
import 'retorno_sicoob.dart';

/// Boletos registrados pela API de Cobrança Bancária (Sandbox).
class BoletosSicoobTab extends StatelessWidget {
  const BoletosSicoobTab({super.key, required this.vm});

  final IntegracaoSicoobViewModel vm;

  Future<void> _novo(BuildContext context) async {
    final dados = await showDialog<NovoBoletoSicoob>(
      context: context,
      builder: (_) => _BoletoDialog(vm: vm),
    );
    if (dados == null || !context.mounted) return;
    final ok = await vm.registrarBoleto(dados);
    if (!context.mounted) return;
    mostrarMensagem(
      context,
      ok ? 'Boleto registrado no Sicoob (Sandbox).' : (vm.erro ?? 'Erro.'),
    );
    final pdf = vm.ultimoPdf;
    if (ok && pdf != null) {
      await PdfKit.imprimir('boleto-sicoob', () async => pdf);
    }
  }

  Future<void> _resultado(
    BuildContext context,
    Future<bool> acao,
    String sucesso,
  ) async {
    final ok = await acao;
    if (context.mounted) {
      mostrarMensagem(context, ok ? sucesso : (vm.erro ?? 'Erro.'));
    }
  }

  Future<void> _pdf(BuildContext context, BoletoSicoob b) async {
    final pdf = await vm.pdfBoleto(b);
    if (!context.mounted) return;
    if (pdf == null || pdf.isEmpty) {
      mostrarMensagem(context, vm.erro ?? 'O Sicoob não devolveu o PDF.');
      return;
    }
    await PdfKit.imprimir('boleto-${b.nossoNumero}', () async => pdf);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.add,
        label: 'Novo boleto de teste',
        onPressed: () => _novo(context),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final m = margemSicoob(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(m, 16, m, 96),
            children: [
              RetornoSicoobCard(vm: vm),
              if (!vm.pronto) avisoConfigurar(),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'API Cobrança Bancária v3: registro, consulta, segunda via em '
                  'PDF e baixa. Gere a partir de uma cobrança do aluguel ou '
                  'com dados livres.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
              if (vm.boletos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'Nenhum boleto registrado ainda.',
                  ),
                ),
              for (final b in vm.boletos)
                CardPadrao(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${formatMoney(b.valor)} · ${b.pagadorNome}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Nosso número ${b.nossoNumero} · vence '
                                  '${formatDate(b.vencimento)}',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GoldChip(
                            b.situacao,
                            color: switch (b.situacao.toLowerCase()) {
                              'liquidado' => Colors.greenAccent,
                              'baixado' => Colors.grey,
                              _ => Colors.orangeAccent,
                            },
                          ),
                        ],
                      ),
                      if (b.linhaDigitavel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  b.linhaDigitavel,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copiar linha digitável',
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: b.linhaDigitavel),
                                  );
                                  if (context.mounted) {
                                    mostrarMensagem(context, 'Linha copiada.');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: vm.ocupado
                                ? null
                                : () => _resultado(
                                    context,
                                    vm.consultarBoleto(b),
                                    'Situação atualizada.',
                                  ),
                            icon: const Icon(Icons.sync, size: 18),
                            label: const Text('Consultar'),
                          ),
                          TextButton.icon(
                            onPressed: vm.ocupado
                                ? null
                                : () => _pdf(context, b),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 18,
                            ),
                            label: const Text('Segunda via'),
                          ),
                          if (b.situacao.toLowerCase() != 'baixado')
                            TextButton.icon(
                              onPressed: vm.ocupado
                                  ? null
                                  : () async {
                                      if (await confirmDelete(
                                        context,
                                        'Pedir a baixa (cancelamento) do '
                                        'boleto ${b.nossoNumero}?',
                                      )) {
                                        if (!context.mounted) return;
                                        await _resultado(
                                          context,
                                          vm.baixarBoleto(b),
                                          'Baixa pedida ao Sicoob.',
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Baixar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Dados do boleto: livres ou a partir de uma cobrança do aluguel.
class _BoletoDialog extends StatefulWidget {
  const _BoletoDialog({required this.vm});

  final IntegracaoSicoobViewModel vm;

  @override
  State<_BoletoDialog> createState() => _BoletoDialogState();
}

class _BoletoDialogState extends State<_BoletoDialog> {
  final _valor = TextEditingController();
  final _nome = TextEditingController();
  final _documento = TextEditingController();
  final _endereco = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _uf = TextEditingController();
  final _cep = TextEditingController();
  final _email = TextEditingController();
  final _multa = TextEditingController();
  final _juros = TextEditingController();
  final _mensagem = TextEditingController();
  DateTime _vencimento = DateTime.now().add(const Duration(days: 7));
  bool _comPix = true;
  String? _cobrancaId;
  String? _erro;

  Future<void> _usarCobranca(String? id) async {
    setState(() => _cobrancaId = id);
    if (id == null) return;
    final r = await widget.vm.rascunho(id);
    if (r == null || !mounted) return;
    setState(() {
      _valor.text = moneyToText(r.valor);
      _vencimento = r.vencimento.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(days: 3))
          : r.vencimento;
      _nome.text = r.pagador.nome;
      _documento.text = r.pagador.documento;
      _endereco.text = r.pagador.endereco;
      _bairro.text = r.pagador.bairro;
      _cidade.text = r.pagador.cidade;
      _uf.text = r.pagador.uf;
      _cep.text = r.pagador.cep;
      _email.text = r.pagador.email;
      _multa.text = decimalToText(r.multaPercentual);
      _juros.text = decimalToText(r.jurosMesPercentual);
      _mensagem.text = r.descricao;
    });
  }

  void _confirmar() {
    final valor = parseMoney(_valor.text) ?? 0;
    if (valor <= 0 || _nome.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o valor e o nome do pagador.');
      return;
    }
    Navigator.pop(
      context,
      NovoBoletoSicoob(
        valor: valor,
        vencimento: _vencimento,
        pagador: PagadorSicoob(
          documento: _documento.text,
          nome: _nome.text.trim(),
          endereco: _endereco.text.trim(),
          bairro: _bairro.text.trim(),
          cidade: _cidade.text.trim(),
          cep: _cep.text,
          uf: _uf.text.trim(),
          email: _email.text.trim(),
        ),
        multaPercentual: parseDecimal(_multa.text) ?? 0,
        jurosMesPercentual: parseDecimal(_juros.text) ?? 0,
        mensagem: _mensagem.text.trim(),
        comPix: _comPix,
        cobrancaId: _cobrancaId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final abertas = widget.vm.cobrancasAbertas;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Novo boleto de teste'),
      content: SizedBox(
        width: 620,
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
                  DateField(
                    label: 'Vencimento',
                    value: _vencimento,
                    onChanged: (d) =>
                        setState(() => _vencimento = d ?? _vencimento),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppTextField(label: 'Pagador', controller: _nome),
                  AppTextField(label: 'CPF/CNPJ', controller: _documento),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Endereço', controller: _endereco),
              const SizedBox(height: 12),
              FieldRow(
                flex: const [3, 3, 1, 2],
                children: [
                  AppTextField(label: 'Bairro', controller: _bairro),
                  AppTextField(label: 'Cidade', controller: _cidade),
                  AppTextField(label: 'UF', controller: _uf),
                  AppTextField(label: 'CEP', controller: _cep),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'E-mail do pagador', controller: _email),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppTextField.decimal(
                    label: 'Multa',
                    suffixText: '%',
                    controller: _multa,
                  ),
                  AppTextField.decimal(
                    label: 'Juros',
                    suffixText: '% ao mês',
                    controller: _juros,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Mensagem no boleto (opcional)',
                controller: _mensagem,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _comPix,
                activeThumbColor: AppColors.gold,
                title: const Text('Incluir QR code Pix no boleto'),
                onChanged: (v) => setState(() => _comPix = v),
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
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Registrar no Sicoob'),
        ),
      ],
    );
  }
}
