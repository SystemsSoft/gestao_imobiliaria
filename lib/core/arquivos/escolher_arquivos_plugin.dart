import 'package:file_picker/file_picker.dart';

import 'arquivo_repository.dart';
import 'escolher_arquivos.dart';

/// Fora da web (Android/iOS/desktop nativos): seletor do plugin.
Future<List<ArquivoEscolhido>> escolherArquivos({
  required List<String> extensoes,
  required List<String> tipos,
  required bool multiplos,
  required OrigemArquivo origem,
}) async {
  final type = extensoes.isNotEmpty
      ? FileType.custom
      : switch (origem) {
          OrigemArquivo.foto => FileType.image,
          OrigemArquivo.video => FileType.video,
          OrigemArquivo.arquivos => FileType.any,
        };
  final allowed = type == FileType.custom ? extensoes : null;
  final escolhidos = multiplos
      ? await FilePicker.pickFiles(type: type, allowedExtensions: allowed)
      : [?await FilePicker.pickFile(type: type, allowedExtensions: allowed)];
  return [
    for (final f in escolhidos)
      ArquivoEscolhido(
        nome: f.name,
        tamanho: await f.length() ?? 0,
        ler: f.readAsBytes,
      ),
  ];
}
