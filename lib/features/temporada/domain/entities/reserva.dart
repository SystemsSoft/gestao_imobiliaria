import 'reserva_enums.dart';

/// Reserva de hospedagem (ou bloqueio de datas) de um imóvel de temporada.
///
/// O período é [checkIn, checkOut): a noite do dia de saída fica livre, então
/// outro hóspede pode entrar no mesmo dia em que o anterior sai.
class Reserva {
  Reserva({
    required this.id,
    required this.imovelId,
    required DateTime checkIn,
    required DateTime checkOut,
    this.numero = '',
    this.hospedeId,
    this.bloqueio = false,
    this.motivoBloqueio = '',
    this.hospedes = 1,
    this.valorDiaria = 0,
    this.taxaLimpeza = 0,
    this.desconto = 0,
    this.valorPago = 0,
    this.situacao = SituacaoReserva.confirmada,
    this.origem = OrigemReserva.direto,
    this.observacoes = '',
  }) : checkIn = soData(checkIn),
       checkOut = soData(checkOut);

  final String id;
  final String numero;
  final String imovelId;
  final String? hospedeId;
  final bool bloqueio;
  final String motivoBloqueio;
  final DateTime checkIn;
  final DateTime checkOut;
  final int hospedes;
  final double valorDiaria;
  final double taxaLimpeza;
  final double desconto;
  final double valorPago;
  final SituacaoReserva situacao;
  final OrigemReserva origem;
  final String observacoes;

  int get noites => checkOut.difference(checkIn).inDays;

  double get subtotal => arredondar(valorDiaria * noites);

  double get total =>
      bloqueio ? 0 : arredondar(subtotal + taxaLimpeza - desconto);

  double get saldo => arredondar(total - valorPago);

  /// Cancelada não ocupa o calendário.
  bool get ocupa => situacao != SituacaoReserva.cancelada;

  /// Há hospedagem na noite que começa em [dia]?
  bool temNoite(DateTime dia) {
    final d = soData(dia);
    return !d.isBefore(checkIn) && d.isBefore(checkOut);
  }

  EstadoReserva estadoEm(DateTime hoje) {
    final h = soData(hoje);
    return switch (situacao) {
      SituacaoReserva.cancelada => EstadoReserva.cancelada,
      SituacaoReserva.preReserva => EstadoReserva.preReserva,
      SituacaoReserva.confirmada =>
        h.isBefore(checkIn)
            ? EstadoReserva.confirmada
            : h.isBefore(checkOut)
            ? EstadoReserva.hospedada
            : EstadoReserva.concluida,
    };
  }

  Reserva copyWith({
    String? numero,
    SituacaoReserva? situacao,
    double? valorPago,
  }) => Reserva(
    id: id,
    numero: numero ?? this.numero,
    imovelId: imovelId,
    hospedeId: hospedeId,
    bloqueio: bloqueio,
    motivoBloqueio: motivoBloqueio,
    checkIn: checkIn,
    checkOut: checkOut,
    hospedes: hospedes,
    valorDiaria: valorDiaria,
    taxaLimpeza: taxaLimpeza,
    desconto: desconto,
    valorPago: valorPago ?? this.valorPago,
    situacao: situacao ?? this.situacao,
    origem: origem,
    observacoes: observacoes,
  );
}
