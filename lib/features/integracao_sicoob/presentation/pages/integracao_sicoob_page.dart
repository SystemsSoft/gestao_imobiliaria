import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../domain/entities/sicoob.dart';
import '../viewmodels/integracao_sicoob_viewmodel.dart';
import '../widgets/boletos_sicoob_tab.dart';
import '../widgets/conta_sicoob_tab.dart';
import '../widgets/pix_sicoob_tab.dart';
import '../widgets/retorno_sicoob.dart';

/// Módulo "Integração Sicoob": testes das APIs no Sandbox (boletos, Pix e
/// conta corrente) antes de ligar a produção.
class IntegracaoSicoobPage extends StatefulWidget {
  const IntegracaoSicoobPage({super.key, this.abaInicial = 0});

  final int abaInicial;

  @override
  State<IntegracaoSicoobPage> createState() => _IntegracaoSicoobPageState();
}

class _IntegracaoSicoobPageState extends State<IntegracaoSicoobPage> {
  final _vm = sl<IntegracaoSicoobViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: widget.abaInicial,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: AbasModulo(
                  abas: [
                    (Icons.tune, 'Configuração'),
                    (Icons.receipt_long_outlined, 'Boletos'),
                    (Icons.pix, 'Pix'),
                    (Icons.account_balance_outlined, 'Conta corrente'),
                    (Icons.list_alt, 'Chamadas'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListenableBuilder(
                  listenable: _vm,
                  builder: (context, _) => BotaoAbrirSicoob(vm: _vm),
                ),
              ),
            ],
          ),
          Expanded(
            child: PainelConteudo(
              child: TabBarView(
                children: [
                  ConfiguracaoSicoobTab(vm: _vm),
                  BoletosSicoobTab(vm: _vm),
                  PixSicoobTab(vm: _vm),
                  ContaSicoobTab(vm: _vm),
                  ChamadasSicoobTab(vm: _vm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Margem lateral: menor no celular.
double margemSicoob(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600 ? 16 : 24;

/// Aviso quando a configuração ainda não permite chamar o banco.
Widget avisoConfigurar() => const CardPadrao(
  borda: Colors.orangeAccent,
  child: Row(
    children: [
      Icon(Icons.info_outline, color: Colors.orangeAccent),
      SizedBox(width: 12),
      Expanded(
        child: Text(
          'Preencha a aba Configuração (client_id e token do Sandbox) para '
          'testar as chamadas ao Sicoob.',
        ),
      ),
    ],
  ),
);

// ------------------------------------------------------------ Configuração

class ConfiguracaoSicoobTab extends StatefulWidget {
  const ConfiguracaoSicoobTab({super.key, required this.vm});

  final IntegracaoSicoobViewModel vm;

  @override
  State<ConfiguracaoSicoobTab> createState() => _ConfiguracaoSicoobTabState();
}

class _ConfiguracaoSicoobTabState extends State<ConfiguracaoSicoobTab> {
  final _clientId = TextEditingController();
  final _token = TextEditingController();
  final _numeroCliente = TextEditingController();
  final _modalidade = TextEditingController(text: '1');
  final _conta = TextEditingController();
  final _chavePix = TextEditingController();
  final _link = TextEditingController(text: linkSicoobPadrao);
  String? _contaBancariaId;
  ConfiguracaoSicoob? _carregada;
  bool _tokenOculto = true;

  IntegracaoSicoobViewModel get _vm => widget.vm;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_preencher);
    _preencher();
  }

  void _preencher() {
    final c = _vm.configuracao;
    if (c == null || identical(c, _carregada)) return;
    _carregada = c;
    _clientId.text = c.clientId;
    _numeroCliente.text = c.numeroCliente;
    _modalidade.text = '${c.codigoModalidade}';
    _conta.text = c.numeroContaCorrente;
    _chavePix.text = c.chavePix;
    _link.text = c.linkInternetBanking;
    _contaBancariaId = c.contaBancariaId;
    _token.clear();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_preencher);
    for (final c in [
      _clientId,
      _token,
      _numeroCliente,
      _modalidade,
      _conta,
      _chavePix,
      _link,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  ConfiguracaoSicoob _montar() => ConfiguracaoSicoob(
    clientId: _clientId.text.trim(),
    numeroCliente: _numeroCliente.text.trim(),
    codigoModalidade: int.tryParse(_modalidade.text) ?? 1,
    numeroContaCorrente: _conta.text.trim(),
    chavePix: _chavePix.text.trim(),
    contaBancariaId: _contaBancariaId,
    linkInternetBanking: _link.text.trim().isEmpty
        ? linkSicoobPadrao
        : _link.text.trim(),
  );

  Future<bool> _salvar({bool avisar = true}) async {
    final ok = await _vm.salvarConfiguracao(_montar(), token: _token.text);
    if (mounted && (avisar || !ok)) {
      mostrarMensagem(
        context,
        ok ? 'Configuração salva.' : (_vm.erro ?? 'Erro.'),
      );
    }
    return ok;
  }

  Future<void> _testar() async {
    if (!await _salvar(avisar: false)) return;
    final ok = await _vm.testar();
    if (!ok && mounted) mostrarMensagem(context, _vm.erro ?? 'Erro.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (!_vm.carregado) {
          return const Center(child: CircularProgressIndicator());
        }
        final c = _vm.configuracao;
        final m = margemSicoob(context);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: EdgeInsets.fromLTRB(m, 20, m, 64),
              children: [
                const CardPadrao(
                  child: Row(
                    children: [
                      Icon(Icons.science_outlined, color: AppColors.gold),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ambiente de testes (Sandbox): nada é cobrado nem '
                          'movimentado de verdade. Pegue o client_id e o token '
                          'em developers.sicoob.com.br › Sandbox. A produção '
                          'exige a conta da imobiliária no Sicoob e o '
                          'certificado digital da empresa.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FormSection(
                  title: 'Acesso ao Sandbox',
                  icon: Icons.key_outlined,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'sandbox',
                          icon: Icon(Icons.science_outlined),
                          label: Text('Sandbox'),
                        ),
                        ButtonSegment(
                          value: 'producao',
                          icon: Icon(Icons.lock_outline),
                          label: Text('Produção'),
                          enabled: false,
                        ),
                      ],
                      selected: const {'sandbox'},
                      onSelectionChanged: (_) {},
                    ),
                    const SizedBox(height: 14),
                    AppTextField(label: 'client_id', controller: _clientId),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _token,
                      obscureText: _tokenOculto,
                      decoration: InputDecoration(
                        labelText: 'Token de acesso (Bearer)',
                        hintText: (c?.tokenConfigurado ?? false)
                            ? 'Já configurado; deixe em branco para manter'
                            : 'Cole o token do Sandbox',
                        suffixIcon: IconButton(
                          tooltip: _tokenOculto ? 'Mostrar' : 'Ocultar',
                          icon: Icon(
                            _tokenOculto
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => _tokenOculto = !_tokenOculto),
                        ),
                      ),
                    ),
                    if (c?.tokenConfigurado ?? false)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Token salvo no servidor (não é exibido).',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                FormSection(
                  title: 'Dados da conta',
                  icon: Icons.account_balance_outlined,
                  children: [
                    FieldRow(
                      children: [
                        AppTextField.integer(
                          label: 'Número do cliente (beneficiário)',
                          controller: _numeroCliente,
                        ),
                        AppTextField.integer(
                          label: 'Modalidade da cobrança',
                          controller: _modalidade,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FieldRow(
                      children: [
                        AppTextField.integer(
                          label: 'Número da conta corrente',
                          controller: _conta,
                        ),
                        AppTextField(
                          label: 'Chave Pix da imobiliária',
                          controller: _chavePix,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppDropdown<String?>(
                      label: 'Conta do Financeiro que recebe o extrato',
                      value: _contaBancariaId,
                      items: [null, ..._vm.contasBancarias.map((x) => x.id)],
                      labelOf: (id) => id == null
                          ? 'Nenhuma'
                          : _vm.contasBancarias
                                    .where((x) => x.id == id)
                                    .firstOrNull
                                    ?.nome ??
                                id,
                      onChanged: (v) => setState(() => _contaBancariaId = v),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Endereço do botão "Abrir Sicoob"',
                      controller: _link,
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _vm.ocupado ? null : _salvar,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                      ),
                      onPressed: _vm.ocupado ? null : _testar,
                      icon: const Icon(Icons.wifi_tethering),
                      label: const Text('Salvar e testar conexão'),
                    ),
                  ],
                ),
                if (_vm.testes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  for (final t in _vm.testes)
                    CardPadrao(
                      borda: t.ok ? Colors.greenAccent : Colors.redAccent,
                      child: Row(
                        children: [
                          Icon(
                            t.ok ? Icons.check_circle : Icons.error_outline,
                            color: t.ok ? Colors.greenAccent : Colors.redAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  t.mensagem,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (t.statusHttp != null)
                            GoldChip('HTTP ${t.statusHttp}'),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------------- Chamadas

class ChamadasSicoobTab extends StatelessWidget {
  const ChamadasSicoobTab({super.key, required this.vm});

  final IntegracaoSicoobViewModel vm;

  Future<void> _detalhe(BuildContext context, ChamadaSicoob c) async {
    final d = await vm.detalheChamada(c);
    if (d == null || !context.mounted) return;
    Widget bloco(String titulo, String texto) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (texto.isNotEmpty)
              IconButton(
                tooltip: 'Copiar',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => Clipboard.setData(ClipboardData(text: texto)),
              ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            texto.isEmpty ? '(vazio)' : texto,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: Text(d.operacao),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.metodo} ${d.caminho}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatDateTime(d.criadoEm)} · '
                  '${d.statusHttp != null ? 'HTTP ${d.statusHttp}' : 'sem resposta'}'
                  ' · ${d.duracaoMs} ms',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (d.erro.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      d.erro,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 12),
                bloco('Enviado', d.requisicao),
                bloco('Resposta do Sicoob', d.resposta),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final m = margemSicoob(context);
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(m, 16, m, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cada requisição feita ao Sicoob, com o que foi enviado e '
                      'a resposta (o token nunca é guardado aqui).',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar',
                    icon: const Icon(Icons.refresh),
                    onPressed: vm.atualizarChamadas,
                  ),
                ],
              ),
            ),
            Expanded(
              child: vm.chamadas.isEmpty
                  ? const EmptyState(
                      icon: Icons.list_alt,
                      message: 'Nenhuma chamada ainda.',
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(m, 4, m, 48),
                      itemCount: vm.chamadas.length,
                      itemBuilder: (_, i) {
                        final c = vm.chamadas[i];
                        final cor = c.sucesso
                            ? Colors.greenAccent
                            : Colors.redAccent;
                        return CardPadrao(
                          onTap: () => _detalhe(context, c),
                          child: Row(
                            children: [
                              Icon(
                                c.sucesso ? Icons.check_circle : Icons.cancel,
                                color: cor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.operacao,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${c.metodo} ${c.caminho}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11.5,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    Text(
                                      [
                                        formatDateTime(c.criadoEm),
                                        '${c.duracaoMs} ms',
                                        if (c.erro.isNotEmpty) c.erro,
                                      ].join(' · '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: c.erro.isEmpty
                                            ? Colors.white38
                                            : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GoldChip(
                                c.statusHttp != null
                                    ? '${c.statusHttp}'
                                    : 'erro',
                                color: cor,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
