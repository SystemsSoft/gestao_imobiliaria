import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'arquivo_repository.dart';
import 'escolher_arquivos.dart';

/// Web: `<input type="file">` do navegador. Com `capture`, o celular abre a
/// câmera direto (e o próprio navegador pede a permissão da câmera).
Future<List<ArquivoEscolhido>> escolherArquivos({
  required List<String> extensoes,
  required List<String> tipos,
  required bool multiplos,
  required OrigemArquivo origem,
}) {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = multiplos && origem == OrigemArquivo.arquivos
    ..accept = switch (origem) {
      OrigemArquivo.foto => 'image/*',
      OrigemArquivo.video => 'video/*',
      OrigemArquivo.arquivos => [
        ...tipos,
        for (final e in extensoes) '.$e',
      ].join(','),
    }
    ..style.display = 'none';
  if (origem != OrigemArquivo.arquivos) {
    input.setAttribute('capture', 'environment'); // câmera traseira
  }

  final concluido = Completer<List<ArquivoEscolhido>>();
  void terminar() {
    if (concluido.isCompleted) return;
    final lista = input.files;
    final arquivos = <ArquivoEscolhido>[
      for (var i = 0; i < (lista?.length ?? 0); i++)
        if (lista!.item(i) case final f?)
          ArquivoEscolhido(
            nome: f.name.isEmpty ? _nomePadrao(origem, f.type) : f.name,
            tamanho: f.size,
            ler: () async =>
                (await f.arrayBuffer().toDart).toDart.asUint8List(),
          ),
    ];
    input.remove();
    concluido.complete(arquivos);
  }

  input
    ..addEventListener('change', ((web.Event _) => terminar()).toJS)
    ..addEventListener('cancel', ((web.Event _) => terminar()).toJS);
  // O Safari só avisa a escolha se o campo estiver na página.
  web.document.body?.append(input);
  input.click(); // ainda dentro do toque do usuário
  return concluido.future;
}

/// Algumas câmeras entregam o arquivo sem nome.
String _nomePadrao(OrigemArquivo origem, String mime) {
  final agora = DateTime.now().millisecondsSinceEpoch;
  final ext = switch (mime) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'video/webm' => 'webm',
    'video/quicktime' => 'mov',
    _ when mime.startsWith('video/') => 'mp4',
    _ => 'jpg',
  };
  return '${origem == OrigemArquivo.video ? 'video' : 'foto'}-$agora.$ext';
}
