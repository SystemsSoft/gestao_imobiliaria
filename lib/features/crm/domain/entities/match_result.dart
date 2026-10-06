import 'contato.dart';
import 'imovel.dart';

/// Resultado do cruzamento entre o perfil de um contato e um imóvel.
class MatchResult {
  const MatchResult({
    required this.contato,
    required this.imovel,
    required this.score,
    required this.atende,
    required this.naoAtende,
  });

  final Contato contato;
  final Imovel imovel;

  /// Compatibilidade de 0 a 100.
  final int score;
  final List<String> atende;
  final List<String> naoAtende;
}
