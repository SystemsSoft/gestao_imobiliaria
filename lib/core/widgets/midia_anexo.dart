import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../arquivos/arquivo_repository.dart';
import '../di/injector.dart';

/// Imagem de um anexo: link da internet ou foto enviada do computador
/// (aberta por link temporário do servidor).
///
/// Mostra a miniatura: o servidor manda a foto já reduzida a [largura] e
/// ela é decodificada nesse tamanho, sem travar a tela com fotos de 12 MP.
class ImagemAnexo extends StatefulWidget {
  const ImagemAnexo(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.largura = 640,
    required this.alternativa,
  });

  final String url;
  final BoxFit fit;

  /// Largura (px) da miniatura; nulo para a imagem original.
  final int? largura;

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
    _endereco = _buscar();
  }

  @override
  void didUpdateWidget(ImagemAnexo antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.url != widget.url || antigo.largura != widget.largura) {
      _endereco = _buscar();
    }
  }

  /// Link da miniatura (só para fotos enviadas ao servidor).
  Future<Uri?> _buscar() async {
    final uri = await sl<ArquivoRepository>().endereco(widget.url);
    final largura = widget.largura;
    if (uri == null ||
        largura == null ||
        uri.data != null ||
        !ehArquivoEnviado(widget.url)) {
      return uri;
    }
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'largura': '$largura'},
    );
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
            cacheWidth: widget.largura,
            errorBuilder: (_, _, _) => widget.alternativa,
          );
        }
        return Image.network(
          uri.toString(),
          fit: widget.fit,
          cacheWidth: widget.largura,
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
