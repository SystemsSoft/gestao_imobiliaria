import 'dart:typed_data';

import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../entities/documento.dart';
import '../repositories/documento_repository.dart';

/// Confere formato (PDF, Word ou Excel) e tamanho antes de enviar.
void validarArquivoDocumento(String nome, int tamanho) {
  final ext = nome.contains('.') ? nome.split('.').last.toLowerCase() : '';
  if (!extensoesDocumento.contains(ext)) {
    throw DomainException(
      '"$nome" não é aceito. Envie PDF, Word ou Excel '
      '(${extensoesDocumento.join(', ').toUpperCase()}).',
    );
  }
  if (tamanho > maximoMbDocumento * 1024 * 1024) {
    throw DomainException(
      '"$nome" é grande demais (máximo $maximoMbDocumento MB).',
    );
  }
}

class ListarPastas {
  const ListarPastas(this._repo);
  final DocumentoRepository _repo;

  Future<List<PastaDocumento>> call() => _repo.pastas();
}

/// Cria ou renomeia a pasta, sem repetir nome.
class SalvarPasta {
  const SalvarPasta(this._repo);
  final DocumentoRepository _repo;

  Future<PastaDocumento> call(String id, String nome) async {
    final n = aparar(nome);
    if (n.isEmpty) throw const DomainException('Informe o nome da pasta.');
    final repetida = (await _repo.pastas()).any(
      (p) => p.id != id && p.nome.toLowerCase() == n.toLowerCase(),
    );
    if (repetida) {
      throw DomainException('Já existe uma pasta chamada "$n".');
    }
    return _repo.salvarPasta(id, n);
  }
}

class RemoverPasta {
  const RemoverPasta(this._repo);
  final DocumentoRepository _repo;

  Future<void> call(String id) => _repo.removerPasta(id);
}

class ListarDocumentos {
  const ListarDocumentos(this._repo);
  final DocumentoRepository _repo;

  Future<List<Documento>> call(String pastaId) => _repo.documentos(pastaId);
}

class EnviarDocumento {
  const EnviarDocumento(this._repo);
  final DocumentoRepository _repo;

  Future<Documento> call(String pastaId, String nome, Uint8List bytes) {
    validarArquivoDocumento(nome, bytes.length);
    return _repo.enviar(pastaId, bytes, nome);
  }
}

/// Renomeia e/ou move o documento para outra pasta.
class SalvarDocumento {
  const SalvarDocumento(this._repo);
  final DocumentoRepository _repo;

  Future<Documento> call(Documento d, {String? nome, String? pastaId}) {
    final n = aparar(nome ?? d.nome);
    if (n.isEmpty) throw const DomainException('Informe o nome do documento.');
    return _repo.salvar(
      Documento(
        id: d.id,
        pastaId: pastaId ?? d.pastaId,
        nome: n,
        arquivoId: d.arquivoId,
        arquivoNome: d.arquivoNome,
        tamanho: d.tamanho,
        atualizadoEm: d.atualizadoEm,
      ),
    );
  }
}

/// Troca o arquivo do documento, mantendo o nome e a pasta.
class SubstituirArquivoDocumento {
  const SubstituirArquivoDocumento(this._repo);
  final DocumentoRepository _repo;

  Future<Documento> call(Documento d, String nome, Uint8List bytes) {
    validarArquivoDocumento(nome, bytes.length);
    return _repo.substituir(d.id, bytes, nome);
  }
}

class RemoverDocumento {
  const RemoverDocumento(this._repo);
  final DocumentoRepository _repo;

  Future<void> call(String id) => _repo.remover(id);
}

class EnderecoDocumento {
  const EnderecoDocumento(this._repo);
  final DocumentoRepository _repo;

  Future<Uri?> call(Documento d) => _repo.endereco(d);
}
