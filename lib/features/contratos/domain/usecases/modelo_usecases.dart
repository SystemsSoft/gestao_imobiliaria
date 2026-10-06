import '../../../../core/errors/domain_exception.dart';
import '../entities/campos_modelo.dart';
import '../entities/contrato_documento.dart';
import '../entities/modelo_contrato.dart';
import '../repositories/contrato_impressao_gateway.dart';
import '../repositories/modelo_contrato_repository.dart';

final _campo = RegExp(r'\{\{(\w+)\}\}');

class ObservarModelos {
  const ObservarModelos(this._repo);
  final ModeloContratoRepository _repo;

  Stream<List<ModeloContrato>> call(TipoModelo tipo) =>
      _repo.observar().map((l) => l.where((m) => m.tipo == tipo).toList());
}

class SalvarModelo {
  const SalvarModelo(this._repo);
  final ModeloContratoRepository _repo;

  Future<void> call(ModeloContrato m) {
    if (m.nome.trim().isEmpty) throw const DomainException('Informe o nome.');
    if (m.texto.trim().isEmpty) throw const DomainException('Informe o texto.');
    final validos = camposDoModelo(m.tipo);
    final invalidos = _campo
        .allMatches(m.texto)
        .map((x) => x.group(1)!)
        .where((c) => !validos.containsKey(c))
        .toSet();
    if (invalidos.isNotEmpty) {
      throw DomainException(
        'Campos desconhecidos para ${m.tipo.label}: ${invalidos.join(', ')}.',
      );
    }
    return _repo.salvar(m);
  }
}

/// Remove o modelo, mantendo ao menos um de cada tipo.
class RemoverModelo {
  const RemoverModelo(this._repo);
  final ModeloContratoRepository _repo;

  Future<void> call(String id) async {
    final todos = await _repo.listar();
    final alvo = todos.where((m) => m.id == id).firstOrNull;
    if (alvo == null) return;
    if (todos.where((m) => m.tipo == alvo.tipo).length <= 1) {
      throw const DomainException('Mantenha ao menos um modelo de cada tipo.');
    }
    await _repo.remover(id);
  }
}

/// Substitui os campos {{campo}} pelos [valores]. A primeira linha do texto
/// vira o título do documento.
class PreencherModelo {
  const PreencherModelo();

  ContratoDocumento call({
    required ModeloContrato modelo,
    required Map<String, String> valores,
    required List<String> assinaturas,
  }) {
    final texto = modelo.texto
        .replaceAllMapped(_campo, (m) => valores[m.group(1)] ?? m.group(0)!)
        .trim();
    final linhas = texto.split('\n');
    return ContratoDocumento(
      titulo: linhas.first.trim(),
      texto: linhas.skip(1).join('\n').trim(),
      assinaturas: assinaturas,
    );
  }
}

class ImprimirContratoDocumento {
  const ImprimirContratoDocumento(this._gateway);
  final ContratoImpressaoGateway _gateway;

  Future<void> call(ContratoDocumento documento) =>
      _gateway.imprimirContrato(documento);
}
