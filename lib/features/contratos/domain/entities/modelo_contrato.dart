import 'parametro_modelo.dart';

enum TipoModelo {
  locacao('Locação', 'Contratos de aluguel residencial e comercial'),
  temporada('Temporada', 'Hospedagem por curta duração'),
  venda('Compra e venda', 'Promessa e escritura de venda'),
  administracao('Administração', 'Administração de imóveis de terceiros'),
  autorizacao('Autorização de venda', 'Captação e exclusividade'),
  outros('Outros documentos', 'Propostas, distratos e recibos');

  const TipoModelo(this.label, this.descricao);
  final String label;
  final String descricao;
}

/// Modelo de contrato com campos no formato {{campo}}.
class ModeloContrato {
  const ModeloContrato({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.texto,
    this.descricao = '',
    this.parametros = const [],
    this.baseId,
    this.atualizadoEm,
  });

  final String id;
  final String nome;
  final TipoModelo tipo;
  final String texto;
  final String descricao;

  /// Campos próprios do usuário, além dos campos do sistema.
  final List<ParametroModelo> parametros;

  /// Modelo pronto de origem (permite restaurar o texto original).
  final String? baseId;
  final DateTime? atualizadoEm;

  bool get derivadoDePronto => baseId != null;

  ModeloContrato copyWith({
    String? id,
    String? nome,
    TipoModelo? tipo,
    String? texto,
    String? descricao,
    List<ParametroModelo>? parametros,
    String? baseId,
    DateTime? atualizadoEm,
  }) => ModeloContrato(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    tipo: tipo ?? this.tipo,
    texto: texto ?? this.texto,
    descricao: descricao ?? this.descricao,
    parametros: parametros ?? this.parametros,
    baseId: baseId ?? this.baseId,
    atualizadoEm: atualizadoEm ?? this.atualizadoEm,
  );
}
