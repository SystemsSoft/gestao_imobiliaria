import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/contato.dart';
import '../../domain/usecases/contato_usecases.dart';

class ContatoFormViewModel extends ViewModel {
  ContatoFormViewModel(this._salvar);

  final SalvarContato _salvar;

  Future<bool> salvar(Contato contato) => executar(() => _salvar(contato));
}
