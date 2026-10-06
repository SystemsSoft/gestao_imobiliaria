import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/entities/reserva_enums.dart';
import '../../domain/usecases/reserva_usecases.dart';

enum FiltroReserva {
  todas('Todas'),
  proximas('Próximas'),
  hospedados('Hospedados'),
  concluidas('Concluídas'),
  pendentes('Pré-reservas'),
  canceladas('Canceladas');

  const FiltroReserva(this.label);
  final String label;
}

class ReservasViewModel extends ViewModel {
  ReservasViewModel(
    ObservarReservas observarReservas,
    ObservarImoveis observarImoveis,
    ObservarContatos observarContatos,
    this._alterar,
    this._quitar,
    this._remover, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    observar(observarReservas(), (l) {
      _reservas = l;
      carregado = true;
    });
    observar(observarImoveis(), (l) => _imoveis = l);
    observar(observarContatos(), (l) => _contatos = l);
  }

  final AlterarSituacaoReserva _alterar;
  final QuitarReserva _quitar;
  final RemoverReserva _remover;
  final DateTime Function() _agora;

  List<Reserva> _reservas = const [];
  List<Imovel> _imoveis = const [];
  List<Contato> _contatos = const [];
  bool carregado = false;
  String query = '';
  FiltroReserva filtro = FiltroReserva.proximas;

  DateTime get hoje => soData(_agora());
  bool get semCadastro => _reservas.isEmpty;

  EstadoReserva estado(Reserva r) => r.estadoEm(hoje);

  String hospede(Reserva r) => r.bloqueio
      ? (r.motivoBloqueio.isEmpty ? 'Bloqueio de datas' : r.motivoBloqueio)
      : _contatos.where((c) => c.id == r.hospedeId).firstOrNull?.nome ?? '—';

  String imovel(Reserva r) {
    final i = _imoveis.where((i) => i.id == r.imovelId).firstOrNull;
    return i == null ? 'Imóvel removido' : '${i.codigo} • ${i.titulo}';
  }

  List<Reserva> get filtradas {
    final q = query.trim().toLowerCase();
    final lista = _reservas.where((r) {
      final e = estado(r);
      final ok = switch (filtro) {
        FiltroReserva.todas => true,
        FiltroReserva.proximas =>
          e == EstadoReserva.confirmada || e == EstadoReserva.preReserva,
        FiltroReserva.hospedados => e == EstadoReserva.hospedada,
        FiltroReserva.concluidas => e == EstadoReserva.concluida,
        FiltroReserva.pendentes => e == EstadoReserva.preReserva,
        FiltroReserva.canceladas => e == EstadoReserva.cancelada,
      };
      if (!ok) return false;
      if (q.isEmpty) return true;
      return [
        r.numero,
        hospede(r),
        imovel(r),
      ].any((t) => t.toLowerCase().contains(q));
    }).toList();
    final passadas =
        filtro == FiltroReserva.concluidas ||
        filtro == FiltroReserva.canceladas;
    return lista..sort(
      (a, b) => passadas
          ? b.checkIn.compareTo(a.checkIn)
          : a.checkIn.compareTo(b.checkIn),
    );
  }

  void buscar(String t) {
    query = t;
    notificar();
  }

  void filtrar(FiltroReserva f) {
    filtro = f;
    notificar();
  }

  Future<bool> confirmar(Reserva r) =>
      executar(() => _alterar(r, SituacaoReserva.confirmada));
  Future<bool> cancelar(Reserva r) =>
      executar(() => _alterar(r, SituacaoReserva.cancelada));
  Future<bool> quitar(Reserva r) => executar(() => _quitar(r));
  Future<bool> remover(Reserva r) => executar(() => _remover(r.id));
}
