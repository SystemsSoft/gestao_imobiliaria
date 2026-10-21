import 'dart:typed_data';

import '../entities/documento.dart';

/// Pastas e documentos do Financeiro, guardados no servidor.
abstract interface class DocumentoRepository {
  Future<List<PastaDocumento>> pastas();

  /// Cria ou renomeia a pasta.
  Future<PastaDocumento> salvarPasta(String id, String nome);

  /// Exclui a pasta com todos os documentos dela.
  Future<void> removerPasta(String id);

  /// Inquilinos e proprietários que podem receber pastas.
  Future<List<Destinatario>> destinatarios();

  /// Define quem vê a pasta no portal (lista vazia = só a equipe).
  Future<PastaDocumento> compartilhar(String pastaId, List<String> contatoIds);

  Future<List<Documento>> documentos(String pastaId);

  Future<Documento> enviar(String pastaId, Uint8List bytes, String nomeArquivo);

  /// Renomeia e/ou move para outra pasta.
  Future<Documento> salvar(Documento d);

  /// Cópia na mesma pasta, com o arquivo copiado e "(cópia)" no nome.
  Future<Documento> duplicar(String id);

  /// Troca o arquivo do documento (o antigo é apagado).
  Future<Documento> substituir(String id, Uint8List bytes, String nomeArquivo);

  Future<void> remover(String id);

  /// Endereço para abrir ou baixar o arquivo.
  Future<Uri?> endereco(Documento d);
}
