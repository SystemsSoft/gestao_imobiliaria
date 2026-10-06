import '../entities/dia_calendario.dart';
import '../entities/reserva.dart';
import '../entities/reserva_enums.dart';

/// Regras de calendário e disponibilidade da locação por temporada.
class CalendarioTemporada {
  const CalendarioTemporada();

  /// Reserva que ocupa a noite de [dia] no imóvel, ignorando as canceladas.
  Reserva? reservaNaNoite(
    List<Reserva> reservas,
    String imovelId,
    DateTime dia,
  ) => reservas
      .where((r) => r.imovelId == imovelId && r.ocupa && r.temNoite(dia))
      .firstOrNull;

  /// Reservas que conflitam com o período [checkIn, checkOut).
  List<Reserva> conflitos(
    List<Reserva> reservas, {
    required String imovelId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? ignorarId,
  }) {
    final ini = soData(checkIn), fim = soData(checkOut);
    return reservas
        .where(
          (r) =>
              r.imovelId == imovelId &&
              r.ocupa &&
              r.id != ignorarId &&
              r.checkIn.isBefore(fim) &&
              ini.isBefore(r.checkOut),
        )
        .toList();
  }

  List<DiaCalendario> diasDoMes(
    List<Reserva> reservas,
    String imovelId,
    int ano,
    int mes,
  ) {
    final total = DateTime(ano, mes + 1, 0).day;
    return [
      for (var d = 1; d <= total; d++)
        () {
          final data = DateTime(ano, mes, d);
          return DiaCalendario(
            data: data,
            noiteAnterior: reservaNaNoite(
              reservas,
              imovelId,
              data.subtract(const Duration(days: 1)),
            ),
            noite: reservaNaNoite(reservas, imovelId, data),
          );
        }(),
    ];
  }

  /// Quantas noites da reserva caem no mês.
  int noitesNoMes(Reserva r, int ano, int mes) {
    final ini = DateTime(ano, mes);
    final fim = DateTime(ano, mes + 1);
    final de = r.checkIn.isAfter(ini) ? r.checkIn : ini;
    final ate = r.checkOut.isBefore(fim) ? r.checkOut : fim;
    final n = ate.difference(de).inDays;
    return n < 0 ? 0 : n;
  }

  OcupacaoMes ocupacao(
    List<Reserva> reservas,
    String imovelId,
    int ano,
    int mes,
  ) {
    var noites = 0;
    var receita = 0.0;
    var qtd = 0;
    for (final r in reservas) {
      if (r.imovelId != imovelId || !r.ocupa) continue;
      final n = noitesNoMes(r, ano, mes);
      if (n == 0) continue;
      noites += n;
      if (!r.bloqueio) {
        receita += r.valorDiaria * n;
        qtd++;
      }
    }
    return OcupacaoMes(
      diasNoMes: DateTime(ano, mes + 1, 0).day,
      noitesOcupadas: noites,
      receita: arredondar(receita),
      reservas: qtd,
    );
  }
}

/// Valor da estadia a partir da diária do imóvel.
class CalcularEstadia {
  const CalcularEstadia();

  ({int noites, double subtotal, double total}) call({
    required DateTime checkIn,
    required DateTime checkOut,
    required double valorDiaria,
    double taxaLimpeza = 0,
    double desconto = 0,
  }) {
    final noites = soData(checkOut).difference(soData(checkIn)).inDays;
    final n = noites < 0 ? 0 : noites;
    final subtotal = arredondar(valorDiaria * n);
    return (
      noites: n,
      subtotal: subtotal,
      total: arredondar(subtotal + taxaLimpeza - desconto),
    );
  }
}
