enum TipoModelo {
  locacao('Locação'),
  venda('Compra e venda');

  const TipoModelo(this.label);
  final String label;
}

/// Modelo de contrato com campos no formato {{campo}}.
class ModeloContrato {
  const ModeloContrato({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.texto,
  });

  final String id;
  final String nome;
  final TipoModelo tipo;
  final String texto;
}
