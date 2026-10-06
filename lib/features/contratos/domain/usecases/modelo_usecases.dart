import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../entities/contrato_documento.dart';
import '../entities/modelo_contrato.dart';
import '../entities/modelo_pronto.dart';
import '../repositories/contrato_impressao_gateway.dart';
import '../repositories/modelo_contrato_repository.dart';
import '../repositories/modelos_prontos_repository.dart';
import '../services/editor_modelo_service.dart';

final _campo = RegExp(r'\{\{(\w+)\}\}');

/// Tipos usados pela impressão de contratos de locação e de venda; precisam
/// manter ao menos um modelo.
const _tiposEssenciais = {TipoModelo.locacao, TipoModelo.venda};

class ObservarModelos {
  const ObservarModelos(this._repo);
  final ModeloContratoRepository _repo;

  /// Sem [tipo], todos os modelos.
  Stream<List<ModeloContrato>> call([TipoModelo? tipo]) => _repo.observar().map(
    (l) => [
      for (final m in l)
        if (tipo == null || m.tipo == tipo) m,
    ]..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase())),
  );
}

class SalvarModelo {
  const SalvarModelo(this._repo, [this._editor = const EditorModeloService()]);
  final ModeloContratoRepository _repo;
  final EditorModeloService _editor;

  Future<void> call(ModeloContrato m) {
    if (m.nome.trim().isEmpty) throw const DomainException('Informe o nome.');
    if (m.texto.trim().isEmpty) throw const DomainException('Informe o texto.');
    final analise = _editor.analisar(m.texto, m.tipo, m.parametros);
    if (!analise.valido) {
      throw DomainException(
        'Campos desconhecidos para ${m.tipo.label}: ${analise.desconhecidos.join(', ')}. '
        'Crie um parâmetro com essa chave ou use um campo do sistema.',
      );
    }
    final vistos = <String>[];
    for (final p in m.parametros) {
      final erro = _editor.validarParametro(p, m.tipo, [
        for (final o in m.parametros)
          if (!identical(o, p) && vistos.contains(o.chave)) o,
      ]);
      if (erro != null) throw DomainException(erro);
      vistos.add(p.chave);
    }
    return _repo.salvar(
      m.copyWith(
        id: m.id.isEmpty ? gerarId() : m.id,
        atualizadoEm: DateTime.now(),
      ),
    );
  }
}

/// Remove o modelo, mantendo ao menos um de locação e um de venda.
class RemoverModelo {
  const RemoverModelo(this._repo);
  final ModeloContratoRepository _repo;

  Future<void> call(String id) async {
    final todos = await _repo.listar();
    final alvo = todos.where((m) => m.id == id).firstOrNull;
    if (alvo == null) return;
    if (_tiposEssenciais.contains(alvo.tipo) &&
        todos.where((m) => m.tipo == alvo.tipo).length <= 1) {
      throw DomainException(
        'Mantenha ao menos um modelo de ${alvo.tipo.label.toLowerCase()}: '
        'ele é usado na impressão dos contratos.',
      );
    }
    await _repo.remover(id);
  }
}

class DuplicarModelo {
  const DuplicarModelo(this._repo);
  final ModeloContratoRepository _repo;

  Future<ModeloContrato> call(ModeloContrato m) async {
    final copia = m.copyWith(
      id: gerarId(),
      nome: '${m.nome} (cópia)',
      atualizadoEm: DateTime.now(),
    );
    await _repo.salvar(copia);
    return copia;
  }
}

class ListarModelosProntos {
  const ListarModelosProntos(this._repo);
  final ModelosProntosRepository _repo;

  Future<List<ModeloPronto>> call() => _repo.listar();
}

/// Texto original do modelo pronto de que o modelo deriva.
class RestaurarModelo {
  const RestaurarModelo(this._prontos);
  final ModelosProntosRepository _prontos;

  Future<ModeloContrato> call(ModeloContrato m) async {
    final pronto = m.baseId == null ? null : await _prontos.obter(m.baseId!);
    if (pronto == null) {
      throw const DomainException(
        'Este modelo não deriva de um modelo pronto.',
      );
    }
    return m.copyWith(texto: pronto.texto, parametros: pronto.parametros);
  }
}

/// Substitui os campos {{campo}} pelos [valores]. Parâmetros do modelo sem
/// valor informado usam o valor padrão. A primeira linha vira o título.
class PreencherModelo {
  const PreencherModelo();

  ContratoDocumento call({
    required ModeloContrato modelo,
    required Map<String, String> valores,
    required List<String> assinaturas,
  }) {
    final todos = {
      for (final p in modelo.parametros) p.chave: p.valorPadrao,
      ...valores,
    };
    final texto = modelo.texto
        .replaceAllMapped(_campo, (m) => todos[m.group(1)] ?? m.group(0)!)
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

/// Imprime o modelo com valores de exemplo, para conferir o resultado.
class ImprimirExemploModelo {
  const ImprimirExemploModelo(
    this._imprimir, [
    this._editor = const EditorModeloService(),
  ]);
  final ImprimirContratoDocumento _imprimir;
  final EditorModeloService _editor;

  Future<void> call(ModeloContrato m) {
    final texto = _editor.previa(m.texto, m.tipo, m.parametros).trim();
    final linhas = texto.split('\n');
    return _imprimir(
      ContratoDocumento(
        titulo: linhas.first.trim(),
        texto: linhas.skip(1).join('\n').trim(),
        assinaturas: const [
          'PARTE 1',
          'PARTE 2',
          'TESTEMUNHA 1',
          'TESTEMUNHA 2',
        ],
      ),
    );
  }
}
