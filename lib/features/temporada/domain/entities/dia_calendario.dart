import 'reserva.dart';

/// Um dia do calendário de um imóvel, dividido em duas metades:
/// a noite anterior (esquerda) e a noite que começa neste dia (direita).
class DiaCalendario {
  const DiaCalendario({required this.data, this.noiteAnterior, this.noite});

  final DateTime data;

  /// Reserva que ocupa a noite anterior (sai neste dia ou continua).
  final Reserva? noiteAnterior;

  /// Reserva que ocupa a noite deste dia (entra neste dia ou continua).
  final Reserva? noite;

  bool get livre => noiteAnterior == null && noite == null;

  /// Hóspede sai e outro entra no mesmo dia.
  bool get viradaDeHospede =>
      noiteAnterior != null && noite != null && noiteAnterior!.id != noite!.id;

  bool get checkIn => noite != null && noite!.checkIn == data;
  bool get checkOut => noiteAnterior != null && noiteAnterior!.checkOut == data;
}

class OcupacaoMes {
  const OcupacaoMes({
    required this.diasNoMes,
    required this.noitesOcupadas,
    required this.receita,
    required this.reservas,
  });

  final int diasNoMes;
  final int noitesOcupadas;

  /// Receita proporcional às noites que caem no mês.
  final double receita;
  final int reservas;

  double get taxa => diasNoMes == 0 ? 0 : noitesOcupadas / diasNoMes;
}
