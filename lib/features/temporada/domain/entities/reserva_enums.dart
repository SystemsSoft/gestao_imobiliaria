/// Situação definida pelo usuário.
enum SituacaoReserva {
  preReserva('Pré-reserva'),
  confirmada('Confirmada'),
  cancelada('Cancelada');

  const SituacaoReserva(this.label);
  final String label;
}

/// Estado calculado automaticamente pelas datas.
enum EstadoReserva {
  preReserva('Pré-reserva'),
  confirmada('Confirmada'),
  hospedada('Hospedado'),
  concluida('Concluída'),
  cancelada('Cancelada');

  const EstadoReserva(this.label);
  final String label;
}

enum OrigemReserva {
  direto('Direto'),
  airbnb('Airbnb'),
  booking('Booking.com'),
  indicacao('Indicação'),
  outro('Outro');

  const OrigemReserva(this.label);
  final String label;
}

/// Remove a hora: o calendário trabalha só com datas.
DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

double arredondar(double v) => (v * 100).roundToDouble() / 100;
