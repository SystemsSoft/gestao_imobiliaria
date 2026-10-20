import 'dart:typed_data';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/json.dart';
import '../../../../core/arquivos/arquivo_repository.dart';
import '../../domain/entities/documento.dart';
import '../../domain/repositories/documento_repository.dart';

typedef _Json = Map<String, dynamic>;

PastaDocumento _pasta(_Json j) => PastaDocumento(
  id: j['id'] as String,
  nome: lerTexto(j['nome']),
  documentos: lerInt(j['documentos']),
);

Documento _documento(_Json j) => Documento(
  id: j['id'] as String,
  pastaId: j['pastaId'] as String,
  nome: lerTexto(j['nome']),
  arquivoId: j['arquivoId'] as String,
  arquivoNome: lerTexto(j['arquivoNome']),
  tamanho: lerInt(j['tamanho']),
  atualizadoEm: lerData(j['atualizadoEm']) ?? DateTime.now(),
);

/// Pastas e documentos no servidor (`/financeiro/pastas`).
class DocumentoApiRepository implements DocumentoRepository {
  const DocumentoApiRepository(this._api, this._arquivos);
  final ApiClient _api;
  final ArquivoRepository _arquivos;

  @override
  Future<List<PastaDocumento>> pastas() async => [
    for (final j in await _api.get('financeiro/pastas') as List) _pasta(j),
  ];

  @override
  Future<PastaDocumento> salvarPasta(String id, String nome) async =>
      _pasta(await _api.put('financeiro/pastas/$id', {'nome': nome}));

  @override
  Future<void> removerPasta(String id) => _api.delete('financeiro/pastas/$id');

  @override
  Future<List<Documento>> documentos(String pastaId) async => [
    for (final j
        in await _api.get('financeiro/pastas/$pastaId/documentos') as List)
      _documento(j),
  ];

  @override
  Future<Documento> enviar(
    String pastaId,
    Uint8List bytes,
    String nomeArquivo,
  ) async => _documento(
    await _api.enviarArquivo(
      'financeiro/pastas/$pastaId/documentos',
      bytes: bytes,
      nomeArquivo: nomeArquivo,
    ),
  );

  @override
  Future<Documento> salvar(Documento d) async => _documento(
    await _api.put('financeiro/documentos/${d.id}', {
      'nome': d.nome,
      'pastaId': d.pastaId,
    }),
  );

  @override
  Future<Documento> substituir(
    String id,
    Uint8List bytes,
    String nomeArquivo,
  ) async => _documento(
    await _api.enviarArquivo(
      'financeiro/documentos/$id/arquivo',
      bytes: bytes,
      nomeArquivo: nomeArquivo,
    ),
  );

  @override
  Future<void> remover(String id) => _api.delete('financeiro/documentos/$id');

  @override
  Future<Uri?> endereco(Documento d) =>
      _arquivos.endereco('$prefixoArquivo${d.arquivoId}');
}
