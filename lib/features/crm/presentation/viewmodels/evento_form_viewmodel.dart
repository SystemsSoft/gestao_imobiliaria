import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/evento.dart';
import '../../domain/entities/imovel.dart';
import '../../domain/usecases/contato_usecases.dart';
import '../../domain/usecases/evento_usecases.dart';
import '../../domain/usecases/imovel_usecases.dart';

class EventoFormViewModel extends ViewModel {
  EventoFormViewModel(this._listarContatos, this._listarImoveis, this._salvar) {
    _carregar();
  }

  final ListarContatos _listarContatos;
  final ListarImoveis _listarImoveis;
  final SalvarEvento _salvar;

  List<Contato> contatos = const [];
  List<Imovel> imoveis = const [];

  Future<void> _carregar() async {
    contatos = await _listarContatos();
    imoveis = await _listarImoveis();
    notificar();
  }

  Future<bool> salvar(Evento evento) => executar(() => _salvar(evento));
}
