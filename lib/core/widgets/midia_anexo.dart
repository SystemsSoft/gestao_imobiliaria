import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../arquivos/arquivo_repository.dart';
import '../di/injector.dart';

/// Imagem de um anexo: link da internet ou foto enviada do computador
/// (aberta por link temporário do servidor).
class ImagemAnexo extends StatefulWidget {
  const ImagemAnexo(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    required this.alternativa,
  });

  final String url;
  final BoxFit fit;

  /// Exibida enquanto carrega ou se a imagem não abrir.
  final Widget alternativa;

  @override
  State<ImagemAnexo> createState() => _ImagemAnexoState();
}

class _ImagemAnexoState extends State<ImagemAnexo> {
  late Future<Uri?> _endereco;

  @override
  void initState() {
    super.initState();
    _endereco = sl<ArquivoRepository>().endereco(widget.url);
  }

  @override
  void didUpdateWidget(ImagemAnexo antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.url != widget.url) {
      _endereco = sl<ArquivoRepository>().endereco(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uri?>(
      future: _endereco,
      builder: (context, s) {
        final uri = s.data;
        if (uri == null) return widget.alternativa;
        if (uri.data case final dados?) {
          return Image.memory(
            dados.contentAsBytes(),
            fit: widget.fit,
            errorBuilder: (_, _, _) => widget.alternativa,
          );
        }
        return Image.network(
          uri.toString(),
          fit: widget.fit,
          errorBuilder: (_, _, _) => widget.alternativa,
        );
      },
    );
  }
}

/// Abre o anexo em outra aba (foto, vídeo, PDF) ou baixa o arquivo.
Future<void> abrirAnexo(BuildContext context, String url) async {
  final mensageiro = ScaffoldMessenger.of(context);
  String? erro;
  try {
    final uri = await sl<ArquivoRepository>().endereco(url);
    if (uri == null) {
      erro = 'Arquivo não encontrado no servidor.';
    } else if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
      erro = 'Não foi possível abrir o anexo.';
    }
  } on Exception catch (e) {
    erro = '$e';
  }
  if (erro != null) {
    mensageiro.showSnackBar(SnackBar(content: Text(erro)));
  }
}
