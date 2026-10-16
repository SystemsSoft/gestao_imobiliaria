import 'dart:typed_data';

import '../errors/domain_exception.dart';

/// Tipos de mídia que podem ser enviados do computador, com os formatos e o
/// tamanho máximo aceitos pelo servidor.
enum CategoriaArquivo {
  foto('fotos', ['jpg', 'jpeg', 'png', 'webp', 'gif'], 15),
  video('vídeos', ['mp4', 'm4v', 'mov', 'webm'], 300),
  arquivo('arquivos', [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', //
    'txt', 'csv', 'zip', 'dwg', 'jpg', 'jpeg', 'png', 'webp', 'gif',
  ], 30);

  const CategoriaArquivo(this.plural, this.extensoes, this.maximoMb);

  final String plural;
  final List<String> extensoes;
  final int maximoMb;

  /// Confere formato e tamanho antes de enviar (evita subir à toa).
  void validar(String nome, int tamanho) {
    final ext = nome.contains('.') ? nome.split('.').last.toLowerCase() : '';
    if (!extensoes.contains(ext)) {
      throw DomainException(
        'Formato não aceito para $plural. Envie: '
        '${extensoes.toSet().join(', ').toUpperCase()}.',
      );
    }
    if (tamanho > maximoMb * 1024 * 1024) {
      throw DomainException(
        '"$nome" é grande demais (máximo $maximoMb MB para $plural).',
      );
    }
  }
}

/// Prefixo das mídias enviadas do computador; os links continuam `http...`.
const prefixoArquivo = 'arquivo:';

bool ehArquivoEnviado(String url) => url.startsWith(prefixoArquivo);

class ArquivoEnviado {
  const ArquivoEnviado({
    required this.id,
    required this.nome,
    required this.tamanho,
  });

  final String id;
  final String nome;
  final int tamanho;

  /// Valor guardado no cadastro (no lugar do link).
  String get referencia => '$prefixoArquivo$id';
}

/// Arquivo escolhido no computador; o conteúdo só é lido depois de
/// conferidos formato e tamanho.
class ArquivoEscolhido {
  const ArquivoEscolhido({
    required this.nome,
    required this.tamanho,
    required this.ler,
  });

  final String nome;
  final int tamanho;
  final Future<Uint8List> Function() ler;
}

abstract interface class ArquivoRepository {
  Future<ArquivoEnviado> enviar({
    required Uint8List bytes,
    required String nome,
    required CategoriaArquivo categoria,
  });

  /// Endereço para exibir ou baixar: o próprio link, ou um link temporário
  /// para os arquivos enviados. Nulo se o arquivo não existe mais.
  Future<Uri?> endereco(String url);
}
