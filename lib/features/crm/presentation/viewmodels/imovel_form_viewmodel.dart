import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/imovel.dart';
import '../../domain/usecases/contato_usecases.dart';
import '../../domain/usecases/imovel_usecases.dart';

class ImovelFormViewModel extends ViewModel {
  ImovelFormViewModel(this._listarContatos, this._salvar) {
    _carregar();
  }

  final ListarContatos _listarContatos;
  final SalvarImovel _salvar;

  /// Contatos disponíveis para vincular como proprietário.
  List<Contato> contatos = const [];

  Future<void> _carregar() async {
    contatos = await _listarContatos();
    notificar();
  }

  Future<bool> salvar(Imovel imovel) => executar(() => _salvar(imovel));
}
