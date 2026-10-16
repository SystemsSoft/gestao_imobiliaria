import 'dart:typed_data';

import '../utils/id.dart';
import 'arquivo_repository.dart';

/// Arquivos em memória (testes e uso sem servidor): viram `data:` URIs.
class ArquivoRepositoryMemoria implements ArquivoRepository {
  final _arquivos = <String, (Uint8List, String)>{};

  @override
  Future<ArquivoEnviado> enviar({
    required Uint8List bytes,
    required String nome,
    required CategoriaArquivo categoria,
  }) async {
    categoria.validar(nome, bytes.length);
    final id = gerarId();
    _arquivos[id] = (bytes, _mime(nome));
    return ArquivoEnviado(id: id, nome: nome, tamanho: bytes.length);
  }

  @override
  Future<Uri?> endereco(String url) async {
    if (!ehArquivoEnviado(url)) return Uri.tryParse(url);
    final a = _arquivos[url.substring(prefixoArquivo.length)];
    return a == null ? null : Uri.dataFromBytes(a.$1, mimeType: a.$2);
  }

  static String _mime(String nome) =>
      switch (nome.split('.').last.toLowerCase()) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'mp4' || 'm4v' => 'video/mp4',
        'pdf' => 'application/pdf',
        _ => 'application/octet-stream',
      };
}
