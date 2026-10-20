import 'dart:typed_data';

import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../../domain/entities/documento.dart';
import '../../domain/repositories/documento_repository.dart';

/// Pastas e documentos em memória (testes e uso sem servidor).
class DocumentoMemoriaRepository implements DocumentoRepository {
  final _pastas = <String, String>{};
  final _docs = <String, Documento>{};
  final _conteudo = <String, Uint8List>{};

  int _quantos(String pastaId) =>
      _docs.values.where((d) => d.pastaId == pastaId).length;

  @override
  Future<List<PastaDocumento>> pastas() async => [
    for (final MapEntry(key: id, value: nome) in _pastas.entries)
      PastaDocumento(id: id, nome: nome, documentos: _quantos(id)),
  ]..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

  @override
  Future<PastaDocumento> salvarPasta(String id, String nome) async {
    _pastas[id] = nome;
    return PastaDocumento(id: id, nome: nome, documentos: _quantos(id));
  }

  @override
  Future<void> removerPasta(String id) async {
    _pastas.remove(id);
    _docs.removeWhere((_, d) => d.pastaId == id);
  }

  @override
  Future<List<Documento>> documentos(String pastaId) async {
    if (!_pastas.containsKey(pastaId)) {
      throw const DomainException('Pasta não encontrada.');
    }
    return _docs.values.where((d) => d.pastaId == pastaId).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  Documento _novo(
    String id,
    String pastaId,
    String nome,
    Uint8List bytes,
    String arquivo,
  ) {
    final arquivoId = gerarId();
    _conteudo[arquivoId] = bytes;
    return Documento(
      id: id,
      pastaId: pastaId,
      nome: nome,
      arquivoId: arquivoId,
      arquivoNome: arquivo,
      tamanho: bytes.length,
      atualizadoEm: DateTime.now(),
    );
  }

  @override
  Future<Documento> enviar(
    String pastaId,
    Uint8List bytes,
    String nomeArquivo,
  ) async {
    final titulo = nomeArquivo.contains('.')
        ? nomeArquivo.substring(0, nomeArquivo.lastIndexOf('.'))
        : nomeArquivo;
    final d = _novo(gerarId(), pastaId, titulo, bytes, nomeArquivo);
    return _docs[d.id] = d;
  }

  @override
  Future<Documento> salvar(Documento d) async => _docs[d.id] = d;

  @override
  Future<Documento> substituir(
    String id,
    Uint8List bytes,
    String nomeArquivo,
  ) async {
    final atual = _docs[id]!;
    _conteudo.remove(atual.arquivoId);
    return _docs[id] = _novo(id, atual.pastaId, atual.nome, bytes, nomeArquivo);
  }

  @override
  Future<void> remover(String id) async {
    final d = _docs.remove(id);
    if (d != null) _conteudo.remove(d.arquivoId);
  }

  @override
  Future<Uri?> endereco(Documento d) async {
    final bytes = _conteudo[d.arquivoId];
    return bytes == null
        ? null
        : Uri.dataFromBytes(bytes, mimeType: 'application/octet-stream');
  }
}
