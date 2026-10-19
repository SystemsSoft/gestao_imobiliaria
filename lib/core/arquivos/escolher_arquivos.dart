import 'arquivo_repository.dart';
import 'escolher_arquivos_plugin.dart'
    if (dart.library.js_interop) 'escolher_arquivos_web.dart'
    as plataforma;

/// O que abrir ao escolher arquivos.
enum OrigemArquivo {
  /// Arquivos e galeria do aparelho.
  arquivos,

  /// Câmera traseira para tirar uma foto (no computador abre os arquivos).
  foto,

  /// Câmera traseira para gravar um vídeo (no computador abre os arquivos).
  video,
}

/// Abre o seletor do aparelho e devolve os arquivos escolhidos (vazio se
/// cancelar). Na web usa o campo de arquivo do próprio navegador, que no
/// celular oferece câmera e galeria e pede a permissão da câmera sozinho.
///
/// [extensoes] filtra os formatos (sem ponto); [tipos] são tipos MIME
/// amplos (ex.: `image/*`), que no celular liberam câmera e galeria.
Future<List<ArquivoEscolhido>> escolherArquivos({
  List<String> extensoes = const [],
  List<String> tipos = const [],
  bool multiplos = false,
  OrigemArquivo origem = OrigemArquivo.arquivos,
}) => plataforma.escolherArquivos(
  extensoes: extensoes,
  tipos: tipos,
  multiplos: multiplos,
  origem: origem,
);
