import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../../domain/entities/modelo_pronto.dart';
import '../../domain/services/editor_modelo_service.dart';
import '../../domain/usecases/modelo_usecases.dart';

/// "Meus modelos": lista, duplica, restaura e remove os modelos do usuário.
/// Com [tipoFixo], mostra só os modelos daquele tipo (usado em Locação e Vendas).
class ModelosViewModel extends ViewModel {
  ModelosViewModel(
    this.tipoFixo,
    ObservarModelos observarModelos,
    ListarModelosProntos listarProntos,
    this._remover,
    this._duplicar,
    this._restaurar,
    this._salvar,
    this._imprimirExemplo,
    this._editor,
  ) {
    observar(observarModelos(tipoFixo), (l) {
      modelos = l;
      carregado = true;
    });
    listarProntos().then((l) {
      _prontos = l;
      notificar();
    });
  }

  final TipoModelo? tipoFixo;
  final RemoverModelo _remover;
  final DuplicarModelo _duplicar;
  final RestaurarModelo _restaurar;
  final SalvarModelo _salvar;
  final ImprimirExemploModelo _imprimirExemplo;
  final EditorModeloService _editor;

  List<ModeloContrato> modelos = const [];
  List<ModeloPronto> _prontos = const [];
  bool carregado = false;
  TipoModelo? filtroTipo;
  String query = '';

  List<ModeloContrato> get filtrados {
    final q = query.trim().toLowerCase();
    return modelos
        .where(
          (m) =>
              (filtroTipo == null || m.tipo == filtroTipo) &&
              (q.isEmpty ||
                  m.nome.toLowerCase().contains(q) ||
                  m.descricao.toLowerCase().contains(q)),
        )
        .toList();
  }

  String? nomePronto(String? baseId) =>
      _prontos.where((p) => p.id == baseId).firstOrNull?.nome;

  /// Texto com dados de exemplo, para visualizar o modelo.
  String previa(ModeloContrato m) =>
      _editor.previa(m.texto, m.tipo, m.parametros);

  void filtrar(TipoModelo? t) {
    filtroTipo = t;
    notificar();
  }

  void buscar(String t) {
    query = t;
    notificar();
  }

  Future<bool> remover(String id) => executar(() => _remover(id));

  Future<bool> duplicar(ModeloContrato m) => executar(() async {
    await _duplicar(m);
  });

  /// Volta o texto e os parâmetros ao do modelo pronto de origem.
  Future<bool> restaurar(ModeloContrato m) => executar(() async {
    await _salvar(await _restaurar(m));
  });

  Future<bool> imprimirExemplo(ModeloContrato m) =>
      executar(() => _imprimirExemplo(m));
}
