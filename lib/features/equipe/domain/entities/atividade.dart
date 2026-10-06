import 'equipe_enums.dart';

class Atividade {
  const Atividade({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.descricao,
    required this.quando,
    this.modulo,
  });

  final String id;
  final String usuarioId;
  final TipoAtividade tipo;
  final String descricao;
  final DateTime quando;
  final ModuloSistema? modulo;
}
