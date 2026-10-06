import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/services/calendario_temporada.dart';
import '../../domain/usecases/reserva_usecases.dart';

class ReservaFormViewModel extends ViewModel {
  ReservaFormViewModel(
    this._listarContatos,
    this._listarImoveis,
    this._salvar,
    this._disponibilidade,
    this._estadia,
  ) {
    _carregar();
  }

  final ListarContatos _listarContatos;
  final ListarImoveis _listarImoveis;
  final SalvarReserva _salvar;
  final ConsultarDisponibilidade _disponibilidade;
  final CalcularEstadia _estadia;

  List<Contato> contatos = const [];
  List<Imovel> imoveis = const [];
  bool carregado = false;

  /// Reservas em conflito com o período digitado.
  List<Reserva> conflitos = const [];

  Future<void> _carregar() async {
    contatos = await _listarContatos();
    // Imóveis de temporada primeiro.
    imoveis = [...await _listarImoveis()]
      ..sort((a, b) {
        int peso(Imovel i) =>
            i.finalidades.contains(Finalidade.temporada) ? 0 : 1;
        return peso(a).compareTo(peso(b));
      });
    carregado = true;
    notificar();
  }

  Imovel? imovel(String? id) => imoveis.where((i) => i.id == id).firstOrNull;

  String nome(String? id) =>
      contatos.where((c) => c.id == id).firstOrNull?.nome ?? '';

  ({int noites, double subtotal, double total}) estadia({
    required DateTime checkIn,
    required DateTime checkOut,
    required double valorDiaria,
    double taxaLimpeza = 0,
    double desconto = 0,
  }) => _estadia(
    checkIn: checkIn,
    checkOut: checkOut,
    valorDiaria: valorDiaria,
    taxaLimpeza: taxaLimpeza,
    desconto: desconto,
  );

  /// Atualiza a lista de conflitos do período informado.
  Future<void> verificar({
    required String? imovelId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? ignorarId,
  }) async {
    conflitos = imovelId == null || !checkOut.isAfter(checkIn)
        ? const []
        : await _disponibilidade(
            imovelId: imovelId,
            checkIn: checkIn,
            checkOut: checkOut,
            ignorarId: ignorarId,
          );
    notificar();
  }

  Future<bool> salvar(Reserva r) => executar(() async {
    await _salvar(r);
  });
}
