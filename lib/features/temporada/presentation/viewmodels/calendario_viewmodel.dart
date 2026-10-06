import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/dia_calendario.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/entities/reserva_enums.dart';
import '../../domain/services/calendario_temporada.dart';
import '../../domain/usecases/reserva_usecases.dart';

enum VisaoCalendario {
  linhaDoTempo('Todos os imóveis'),
  mes('Mês do imóvel');

  const VisaoCalendario(this.label);
  final String label;
}

/// Calendário de reservas, montado automaticamente a partir das reservas.
class CalendarioViewModel extends ViewModel {
  CalendarioViewModel(
    ObservarReservas observarReservas,
    ObservarImoveis observarImoveis,
    ObservarContatos observarContatos,
    this._calendario, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    mes = DateTime(_agora().year, _agora().month);
    observar(observarReservas(), (l) {
      _reservas = l;
      carregado = true;
    });
    observar(observarImoveis(), (l) => _imoveis = l);
    observar(observarContatos(), (l) => _contatos = l);
  }

  final CalendarioTemporada _calendario;
  final DateTime Function() _agora;

  List<Reserva> _reservas = const [];
  List<Imovel> _imoveis = const [];
  List<Contato> _contatos = const [];
  bool carregado = false;
  late DateTime mes;
  VisaoCalendario visao = VisaoCalendario.linhaDoTempo;
  String? imovelId;

  DateTime get hoje => soData(_agora());

  /// Imóveis cadastrados com a finalidade "Temporada".
  List<Imovel> get imoveis =>
      _imoveis
          .where((i) => i.finalidades.contains(Finalidade.temporada))
          .toList()
        ..sort((a, b) => a.codigo.compareTo(b.codigo));

  /// Imóvel exibido na visão mensal (o escolhido ou o primeiro).
  Imovel? get imovelSelecionado =>
      imoveis.where((i) => i.id == imovelId).firstOrNull ?? imoveis.firstOrNull;

  /// Imóveis exibidos na linha do tempo (todos ou o filtrado).
  List<Imovel> get imoveisVisiveis => imovelId == null
      ? imoveis
      : imoveis.where((i) => i.id == imovelId).toList();

  int get diasNoMes => DateTime(mes.year, mes.month + 1, 0).day;

  void mudarMes(DateTime m) {
    mes = DateTime(m.year, m.month);
    notificar();
  }

  void mudarVisao(VisaoCalendario v) {
    visao = v;
    notificar();
  }

  void filtrarImovel(String? id) {
    imovelId = id;
    notificar();
  }

  List<Reserva> reservasDoImovel(String id) =>
      _reservas.where((r) => r.imovelId == id && r.ocupa).toList()
        ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

  /// Reservas do imóvel que tocam o mês exibido.
  List<Reserva> reservasNoMes(String id) => reservasDoImovel(
    id,
  ).where((r) => _calendario.noitesNoMes(r, mes.year, mes.month) > 0).toList();

  List<DiaCalendario> diasDoMes(String id) =>
      _calendario.diasDoMes(_reservas, id, mes.year, mes.month);

  OcupacaoMes ocupacao(String id) =>
      _calendario.ocupacao(_reservas, id, mes.year, mes.month);

  /// Ocupação média de todos os imóveis no mês.
  double get ocupacaoGeral {
    final lista = imoveisVisiveis;
    if (lista.isEmpty) return 0;
    return lista.map((i) => ocupacao(i.id).taxa).reduce((a, b) => a + b) /
        lista.length;
  }

  double get receitaMes =>
      imoveisVisiveis.fold(0, (s, i) => s + ocupacao(i.id).receita);

  String nomeHospede(Reserva r) => r.bloqueio
      ? (r.motivoBloqueio.isEmpty ? 'Bloqueado' : r.motivoBloqueio)
      : _contatos.where((c) => c.id == r.hospedeId).firstOrNull?.nome ?? '—';

  Iterable<Reserva> get _ativas =>
      _reservas.where((r) => r.ocupa && !r.bloqueio);

  /// Check-ins previstos para hoje.
  List<Reserva> get chegadasHoje => _ativas
      .where(
        (r) => r.checkIn == hoje && r.situacao == SituacaoReserva.confirmada,
      )
      .toList();

  List<Reserva> get saidasHoje =>
      _ativas.where((r) => r.checkOut == hoje).toList();

  List<Reserva> get hospedadosAgora => _ativas
      .where((r) => r.estadoEm(hoje) == EstadoReserva.hospedada)
      .toList();

  String? nomeImovel(String id) =>
      _imoveis.where((i) => i.id == id).firstOrNull?.codigo;
}
