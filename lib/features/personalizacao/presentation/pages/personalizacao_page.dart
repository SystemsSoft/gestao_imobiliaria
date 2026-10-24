import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/arquivos/escolher_arquivos.dart';
import '../../../../core/config/empresa_info.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../viewmodels/personalizacao_viewmodel.dart';

/// Logotipo e dados da imobiliária usados em contratos, boletos, recibos,
/// repasses e relatórios.
class PersonalizacaoPage extends StatefulWidget {
  const PersonalizacaoPage({super.key});

  @override
  State<PersonalizacaoPage> createState() => _PersonalizacaoPageState();
}

class _PersonalizacaoPageState extends State<PersonalizacaoPage> {
  final _vm = sl<PersonalizacaoViewModel>();
  final _nome = TextEditingController();
  final _atividade = TextEditingController();
  final _creci = TextEditingController();
  final _documento = TextEditingController();
  final _endereco = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _site = TextEditingController();
  final _pix = TextEditingController();
  bool _preenchido = false;

  List<TextEditingController> get _campos => [
    _nome,
    _atividade,
    _creci,
    _documento,
    _endereco,
    _telefone,
    _email,
    _site,
    _pix,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _campos) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _campos) {
      c.dispose();
    }
    _vm.dispose();
    super.dispose();
  }

  void _preencher(DadosEmpresa d) {
    _preenchido = true;
    _nome.text = d.nome;
    _atividade.text = d.atividade;
    _creci.text = d.creci;
    _documento.text = d.documento;
    _endereco.text = d.endereco;
    _telefone.text = d.telefone;
    _email.text = d.email;
    _site.text = d.site;
    _pix.text = d.chavePix;
  }

  DadosEmpresa get _editado => DadosEmpresa(
    nome: _nome.text.trim(),
    atividade: _atividade.text.trim(),
    creci: _creci.text.trim(),
    documento: _documento.text.trim(),
    endereco: _endereco.text.trim(),
    telefone: _telefone.text.trim(),
    email: _email.text.trim(),
    site: _site.text.trim(),
    chavePix: _pix.text.trim(),
  );

  Future<void> _resultado(bool ok, String sucesso) async {
    if (!mounted) return;
    mostrarMensagem(
      context,
      ok ? sucesso : (_vm.erro ?? 'Não foi possível salvar.'),
    );
  }

  Future<void> _escolherLogo() async {
    final escolhidos = await escolherArquivos(
      extensoes: const ['png', 'jpg', 'jpeg'],
    );
    if (escolhidos.isEmpty) return;
    final bytes = await escolhidos.first.ler();
    await _resultado(await _vm.trocarLogo(bytes), 'Logotipo atualizado.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (!_vm.carregado) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!_preenchido) _preencher(_vm.dados);
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: goldFab(
            icon: Icons.save_outlined,
            label: 'Salvar dados',
            onPressed: () async => _resultado(
              await _vm.salvar(_editado),
              'Dados da imobiliária salvos.',
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  const Text(
                    'O logotipo e os dados abaixo aparecem no cabeçalho de '
                    'contratos, boletos, recibos, demonstrativos de repasse, '
                    'carnês e relatórios, e nos campos {{empresa_...}} dos '
                    'modelos de contrato.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  _logo(),
                  const SizedBox(height: 12),
                  _formulario(),
                  const SizedBox(height: 12),
                  FormSection(
                    title: 'Prévia do cabeçalho dos documentos',
                    icon: Icons.picture_as_pdf_outlined,
                    children: [_PreviaCabecalho(_editado, _vm.logo)],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _logo() => FormSection(
    title: 'Logotipo',
    icon: Icons.image_outlined,
    children: [
      Row(
        children: [
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _ImagemLogo(_vm.logo),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vm.logo == null
                      ? 'Usando o logotipo padrão do sistema.'
                      : 'Logotipo personalizado.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Text(
                  'PNG ou JPG, até 2 MB. Prefira fundo transparente ou branco.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                      ),
                      onPressed: _vm.ocupado ? null : _escolherLogo,
                      icon: const Icon(Icons.upload_outlined),
                      label: const Text('Enviar logotipo'),
                    ),
                    if (_vm.logo != null)
                      OutlinedButton.icon(
                        onPressed: _vm.ocupado
                            ? null
                            : () async => _resultado(
                                await _vm.usarLogoPadrao(),
                                'Voltou ao logotipo padrão.',
                              ),
                        icon: const Icon(Icons.restore),
                        label: const Text('Usar o padrão'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  Widget _formulario() => FormSection(
    title: 'Dados da imobiliária',
    icon: Icons.business_outlined,
    children: [
      AppTextField(label: 'Nome / razão social *', controller: _nome),
      const SizedBox(height: 12),
      FieldRow(
        children: [
          AppTextField(label: 'Atividade', controller: _atividade),
          AppTextField(label: 'CRECI', controller: _creci),
        ],
      ),
      const SizedBox(height: 12),
      FieldRow(
        children: [
          AppTextField(
            label: 'CNPJ ou CPF',
            controller: _documento,
            keyboardType: TextInputType.number,
            inputFormatters: [cpfCnpjFormatter],
          ),
          AppTextField(
            label: 'Telefone',
            controller: _telefone,
            keyboardType: TextInputType.phone,
            inputFormatters: [phoneFormatter],
          ),
        ],
      ),
      const SizedBox(height: 12),
      AppTextField(label: 'Endereço completo', controller: _endereco),
      const SizedBox(height: 12),
      FieldRow(
        children: [
          AppTextField(
            label: 'E-mail',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          AppTextField(label: 'Site', controller: _site),
        ],
      ),
      const SizedBox(height: 12),
      AppTextField(
        label: 'Chave PIX (aparece em boletos e carnês)',
        controller: _pix,
      ),
    ],
  );
}

class _ImagemLogo extends StatelessWidget {
  const _ImagemLogo(this.logo);

  final Uint8List? logo;

  @override
  Widget build(BuildContext context) => logo == null
      ? const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white38,
          ),
        )
      : Image.memory(logo!, fit: BoxFit.contain);
}

/// Como o cabeçalho sai nos PDFs (mesma disposição do PdfKit).
class _PreviaCabecalho extends StatelessWidget {
  const _PreviaCabecalho(this.dados, this.logo);

  final DadosEmpresa dados;
  final Uint8List? logo;

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF061A48);
    const dourado = Color(0xFFC8921A);
    const cinza = Color(0xFF666666);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: dourado, width: 2)),
        ),
        child: Row(
          children: [
            SizedBox(width: 56, height: 56, child: _ImagemLogo(logo)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dados.nome.toUpperCase(),
                    style: const TextStyle(
                      color: azul,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (dados.atividadeECreci.isNotEmpty)
                    Text(
                      dados.atividadeECreci,
                      style: const TextStyle(color: cinza, fontSize: 11),
                    ),
                  if (dados.contatos.isNotEmpty)
                    Text(
                      dados.contatos,
                      style: const TextStyle(color: cinza, fontSize: 10),
                    ),
                ],
              ),
            ),
            const Text(
              'RECIBO DE ALUGUEL',
              style: TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
