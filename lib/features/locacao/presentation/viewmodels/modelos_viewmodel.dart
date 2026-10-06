import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../../domain/usecases/modelo_usecases.dart';

class ModelosViewModel extends ViewModel {
  ModelosViewModel(
    ObservarModelos observarModelos,
    this._salvar,
    this._remover,
  ) {
    observar(observarModelos(), (l) {
      modelos = l;
      carregado = true;
    });
  }

  final SalvarModelo _salvar;
  final RemoverModelo _remover;

  List<ModeloContrato> modelos = const [];
  bool carregado = false;

  Future<bool> salvar(ModeloContrato m) => executar(() => _salvar(m));
  Future<bool> remover(String id) => executar(() => _remover(id));
}
