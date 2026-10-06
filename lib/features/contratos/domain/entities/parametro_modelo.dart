enum TipoParametro {
  texto('Texto'),
  numero('Número'),
  dinheiro('Valor em R\$'),
  data('Data');

  const TipoParametro(this.label);
  final String label;
}

/// Campo criado pelo usuário, usado no texto como {{chave}}. Na impressão é
/// substituído pelo [valorPadrao].
class ParametroModelo {
  const ParametroModelo({
    required this.chave,
    required this.rotulo,
    this.tipo = TipoParametro.texto,
    this.valorPadrao = '',
    this.descricao = '',
  });

  /// Identificador no texto: minúsculas, números e "_" (ex.: foro_cidade).
  final String chave;
  final String rotulo;
  final TipoParametro tipo;
  final String valorPadrao;
  final String descricao;

  String get marcador => '{{$chave}}';

  ParametroModelo copyWith({
    String? chave,
    String? rotulo,
    TipoParametro? tipo,
    String? valorPadrao,
    String? descricao,
  }) => ParametroModelo(
    chave: chave ?? this.chave,
    rotulo: rotulo ?? this.rotulo,
    tipo: tipo ?? this.tipo,
    valorPadrao: valorPadrao ?? this.valorPadrao,
    descricao: descricao ?? this.descricao,
  );
}
