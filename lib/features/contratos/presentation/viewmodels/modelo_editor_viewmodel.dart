import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/campos_modelo.dart';
import '../../domain/entities/clausula_modelo.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../../domain/entities/parametro_modelo.dart';
import '../../domain/services/editor_modelo_service.dart';
import '../../domain/usecases/modelo_usecases.dart';

/// Ferramenta de edição de modelos: análise, visualização e salvamento.
class ModeloEditorViewModel extends ViewModel {
  ModeloEditorViewModel(
    this._salvar,
    this._restaurar,
    this._imprimirExemplo,
    this._editor,
  );

  final SalvarModelo _salvar;
  final RestaurarModelo _restaurar;
  final ImprimirExemploModelo _imprimirExemplo;
  final EditorModeloService _editor;

  /// Resultado do último "restaurar texto original".
  ModeloContrato? restaurado;

  List<CampoModelo> campos(TipoModelo t) => camposModelo(t);

  List<ClausulaModelo> get clausulas => biblioteca;

  AnaliseModelo analisar(
    String texto,
    TipoModelo tipo,
    List<ParametroModelo> parametros,
  ) => _editor.analisar(texto, tipo, parametros);

  String previa(
    String texto,
    TipoModelo tipo,
    List<ParametroModelo> parametros,
  ) => _editor.previa(texto, tipo, parametros);

  String renumerar(String texto) => _editor.renumerarClausulas(texto);

  String clausulaNumerada(ClausulaModelo c, String textoAtual) =>
      _editor.clausulaNumerada(c.texto, textoAtual);

  String novaClausula(String textoAtual) =>
      'CLÁUSULA ${_editor.proximaClausula(textoAtual)}ª – . ';

  String chaveDoRotulo(String rotulo) => _editor.chaveDoRotulo(rotulo);

  String? validarParametro(
    ParametroModelo p,
    TipoModelo tipo,
    List<ParametroModelo> outros,
  ) => _editor.validarParametro(p, tipo, outros);

  Future<bool> salvar(ModeloContrato m) => executar(() => _salvar(m));

  Future<bool> restaurar(ModeloContrato m) => executar(() async {
    restaurado = await _restaurar(m);
  });

  Future<bool> imprimirExemplo(ModeloContrato m) =>
      executar(() => _imprimirExemplo(m));
}
