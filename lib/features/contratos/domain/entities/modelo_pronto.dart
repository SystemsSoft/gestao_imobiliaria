import 'modelo_contrato.dart';
import 'parametro_modelo.dart';

/// Modelo de contrato pronto, que o usuário pode visualizar e copiar para
/// "Meus modelos" para personalizar.
class ModeloPronto {
  const ModeloPronto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.texto,
    this.parametros = const [],
  });

  final String id;
  final String nome;
  final String descricao;
  final TipoModelo tipo;
  final String texto;
  final List<ParametroModelo> parametros;

  /// Cópia editável deste modelo (ainda não salva).
  ModeloContrato comoRascunho() => ModeloContrato(
    id: '',
    nome: nome,
    tipo: tipo,
    texto: texto,
    descricao: descricao,
    parametros: parametros,
    baseId: id,
  );
}
