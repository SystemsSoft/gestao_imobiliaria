import 'dart:typed_data';

import '../entities/documento.dart';

/// Pastas e documentos do Financeiro, guardados no servidor.
abstract interface class DocumentoRepository {
  Future<List<PastaDocumento>> pastas();

  /// Cria ou renomeia a pasta.
  Future<PastaDocumento> salvarPasta(String id, String nome);

  /// Exclui a pasta com todos os documentos dela.
  Future<void> removerPasta(String id);

  Future<List<Documento>> documentos(String pastaId);

  Future<Documento> enviar(String pastaId, Uint8List bytes, String nomeArquivo);

  /// Renomeia e/ou move para outra pasta.
  Future<Documento> salvar(Documento d);

  /// Troca o arquivo do documento (o antigo é apagado).
  Future<Documento> substituir(String id, Uint8List bytes, String nomeArquivo);

  Future<void> remover(String id);

  /// Endereço para abrir ou baixar o arquivo.
  Future<Uri?> endereco(Documento d);
}
