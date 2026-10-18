import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/arquivos/arquivo_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/portal.dart';

typedef Aviso = ({String titulo, String mensagem});

/// Pede título e mensagem de um aviso do portal.
Future<Aviso?> pedirComunicado(BuildContext context, {required String titulo}) {
  final t = TextEditingController();
  final m = TextEditingController();
  return showDialog<Aviso>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(titulo),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Título', controller: t),
            const SizedBox(height: 12),
            AppTextField(label: 'Mensagem', controller: m, maxLines: 6),
            const SizedBox(height: 8),
            const Text(
              'Aparece em "Avisos" na Área do inquilino do site.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(ctx, (titulo: t.text, mensagem: m.text)),
          child: const Text('Publicar aviso'),
        ),
      ],
    ),
  );
}

typedef NovoDocumento = ({
  TipoArquivoContrato tipo,
  String titulo,
  ArquivoEscolhido arquivo,
});

/// Escolhe o tipo, o título e o arquivo de um documento do contrato.
Future<NovoDocumento?> pedirDocumento(BuildContext context) =>
    showDialog<NovoDocumento>(
      context: context,
      builder: (_) => const _DocumentoDialog(),
    );

class _DocumentoDialog extends StatefulWidget {
  const _DocumentoDialog();

  @override
  State<_DocumentoDialog> createState() => _DocumentoDialogState();
}

class _DocumentoDialogState extends State<_DocumentoDialog> {
  TipoArquivoContrato _tipo = TipoArquivoContrato.contrato;
  final _titulo = TextEditingController();
  ArquivoEscolhido? _arquivo;

  Future<void> _escolher() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: CategoriaArquivo.arquivo.extensoes,
    );
    if (f == null) return;
    final tamanho = await f.length() ?? 0;
    if (!mounted) return;
    setState(
      () => _arquivo = ArquivoEscolhido(
        nome: f.name,
        tamanho: tamanho,
        ler: f.readAsBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Publicar documento no portal'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDropdown<TipoArquivoContrato>(
              label: 'Tipo',
              value: _tipo,
              items: TipoArquivoContrato.daImobiliaria,
              labelOf: (t) => t.label,
              onChanged: (v) => setState(() => _tipo = v ?? _tipo),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Título (opcional)',
              hint: 'Ex.: Contrato assinado, Vistoria de entrada',
              controller: _titulo,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _escolher,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _arquivo?.nome ?? 'Escolher arquivo (PDF, imagem...)',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O inquilino recebe um aviso e passa a ver o documento em '
              '"Documentos" na Área do inquilino.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
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
          onPressed: _arquivo == null
              ? null
              : () => Navigator.pop(context, (
                  tipo: _tipo,
                  titulo: _titulo.text,
                  arquivo: _arquivo!,
                )),
          child: const Text('Publicar'),
        ),
      ],
    );
  }
}

/// Mostra a senha provisória (uma única vez) e ajuda a enviá-la.
Future<void> mostrarSenhaProvisoria(
  BuildContext context, {
  required SenhaProvisoria senha,
  required String mensagem,
  required String telefone,
}) {
  final digitos = telefone.replaceAll(RegExp(r'\D'), '');
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Acesso liberado'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anote ou envie agora: a senha provisória não será mostrada de '
              'novo. No primeiro acesso o inquilino cria a própria senha.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SelectableText('Login (CPF/CNPJ): ${senha.login}'),
            const SizedBox(height: 6),
            SelectableText(
              'Senha provisória: ${senha.senha}',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: mensagem));
            if (ctx.mounted) mostrarMensagem(ctx, 'Mensagem copiada.');
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar mensagem'),
        ),
        if (digitos.length >= 10)
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(
                'https://wa.me/55$digitos?text=${Uri.encodeComponent(mensagem)}',
              ),
              webOnlyWindowName: '_blank',
            ),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Enviar por WhatsApp'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Concluir'),
        ),
      ],
    ),
  );
}
