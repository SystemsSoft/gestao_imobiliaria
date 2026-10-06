import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../../domain/entities/modelo_pronto.dart';
import '../../domain/services/editor_modelo_service.dart';
import '../../domain/usecases/modelo_usecases.dart';

/// Galeria de modelos prontos.
class ModelosProntosViewModel extends ViewModel {
  ModelosProntosViewModel(ListarModelosProntos listar, this._editor) {
    listar().then((l) {
      prontos = l;
      carregado = true;
      notificar();
    });
  }

  final EditorModeloService _editor;

  List<ModeloPronto> prontos = const [];
  bool carregado = false;
  TipoModelo? filtroTipo;
  String query = '';

  List<ModeloPronto> get filtrados {
    final q = query.trim().toLowerCase();
    return prontos
        .where(
          (p) =>
              (filtroTipo == null || p.tipo == filtroTipo) &&
              (q.isEmpty ||
                  p.nome.toLowerCase().contains(q) ||
                  p.descricao.toLowerCase().contains(q)),
        )
        .toList();
  }

  int quantidade(TipoModelo? t) =>
      prontos.where((p) => t == null || p.tipo == t).length;

  /// Quantidade de campos distintos usados no texto.
  int camposUsados(ModeloPronto p) =>
      _editor.analisar(p.texto, p.tipo, p.parametros).usados.length;

  String previa(ModeloPronto p) =>
      _editor.previa(p.texto, p.tipo, p.parametros);

  void filtrar(TipoModelo? t) {
    filtroTipo = t;
    notificar();
  }

  void buscar(String t) {
    query = t;
    notificar();
  }
}
