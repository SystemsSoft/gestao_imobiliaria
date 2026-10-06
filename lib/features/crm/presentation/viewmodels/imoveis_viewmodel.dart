import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/imovel.dart';
import '../../domain/usecases/imovel_usecases.dart';

class ImoveisViewModel extends ViewModel {
  ImoveisViewModel(ObservarImoveis observarImoveis, this._remover) {
    observar(observarImoveis(), (lista) {
      _todos = lista;
      carregado = true;
    });
  }

  final RemoverImovel _remover;

  List<Imovel> _todos = const [];
  bool carregado = false;
  String query = '';
  StatusImovel? status;

  bool get semCadastro => _todos.isEmpty;

  List<Imovel> get filtrados {
    final q = query.trim().toLowerCase();
    return _todos.where((i) {
      if (status != null && i.status != status) return false;
      if (q.isEmpty) return true;
      return [
        i.codigo,
        i.titulo,
        i.enderecoResumo,
        i.condominioNome,
      ].any((e) => e.toLowerCase().contains(q));
    }).toList();
  }

  void buscar(String texto) {
    query = texto;
    notificar();
  }

  void filtrarStatus(StatusImovel? s) {
    status = s;
    notificar();
  }

  Future<void> remover(String id) => executar(() => _remover(id));
}
