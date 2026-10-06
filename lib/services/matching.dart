import '../models/contato.dart';
import '../models/enums.dart';
import '../models/imovel.dart';
import '../utils/formatters.dart';

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

String _norm(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  var out = s.toLowerCase().trim();
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i], to[i]);
  }
  return out;
}

/// Compara o perfil de interesse do [contato] com o [imovel].
/// Retorna null quando o contato não tem perfil, o imóvel não está
/// disponível ou a finalidade não bate.
MatchResult? avaliarMatch(Contato contato, Imovel imovel) {
  final p = contato.perfil;
  if (p == null) return null;
  if (imovel.status != StatusImovel.disponivel) return null;
  if (!imovel.finalidades.contains(p.finalidade)) return null;

  var earned = 0.0;
  var total = 0;
  final atende = <String>[];
  final naoAtende = <String>[];

  void crit(int peso, bool ok, String sim, String nao) {
    total += peso;
    if (ok) {
      earned += peso;
      atende.add(sim);
    } else {
      naoAtende.add(nao);
    }
  }

  if (p.tipos.isNotEmpty) {
    crit(
      20,
      p.tipos.contains(imovel.tipo),
      'Tipo: ${imovel.tipo.label}',
      'Tipo diferente (${imovel.tipo.label})',
    );
  }

  if (p.valorMin != null || p.valorMax != null) {
    final v = imovel.valorPara(p.finalidade);
    final ok =
        v != null &&
        (p.valorMin == null || v >= p.valorMin!) &&
        (p.valorMax == null || v <= p.valorMax!);
    crit(
      25,
      ok,
      'Valor na faixa (${formatMoney(v)})',
      v == null
          ? 'Valor não informado'
          : 'Valor fora da faixa (${formatMoney(v)})',
    );
  }

  if (p.cidade.trim().isNotEmpty) {
    crit(
      10,
      _norm(imovel.cidade) == _norm(p.cidade),
      'Cidade: ${imovel.cidade}',
      'Cidade diferente (${imovel.cidade})',
    );
  }

  final bairros = p.listaBairros.map(_norm).toList();
  if (bairros.isNotEmpty) {
    final b = _norm(imovel.bairro);
    crit(
      15,
      b.isNotEmpty && bairros.any((e) => b.contains(e) || e.contains(b)),
      'Bairro: ${imovel.bairro}',
      'Bairro diferente (${imovel.bairro})',
    );
  }

  if (p.quartosMin > 0) {
    crit(
      10,
      imovel.quartos >= p.quartosMin,
      '${imovel.quartos} quarto(s)',
      'Menos de ${p.quartosMin} quarto(s)',
    );
  }
  if (p.suitesMin > 0) {
    crit(
      5,
      imovel.suites >= p.suitesMin,
      '${imovel.suites} suíte(s)',
      'Menos de ${p.suitesMin} suíte(s)',
    );
  }
  if (p.vagasMin > 0) {
    crit(
      10,
      imovel.vagas >= p.vagasMin,
      '${imovel.vagas} vaga(s)',
      'Menos de ${p.vagasMin} vaga(s)',
    );
  }
  if (p.areaMin != null) {
    final area = imovel.areaUtil ?? imovel.areaTotal ?? 0;
    crit(
      5,
      area >= p.areaMin!,
      'Área de ${decimalToText(area)} m²',
      'Área menor que ${decimalToText(p.areaMin)} m²',
    );
  }

  if (p.comodidades.isNotEmpty) {
    final tem = {
      ...imovel.comodidades.map(_norm),
      ...imovel.personalizadas.map((e) => _norm(e.nome)),
    };
    final achadas = p.comodidades.where((c) => tem.contains(_norm(c))).length;
    total += 10;
    earned += 10 * achadas / p.comodidades.length;
    final texto = 'Comodidades: $achadas de ${p.comodidades.length}';
    (achadas == p.comodidades.length ? atende : naoAtende).add(texto);
  }

  final score = total == 0 ? 100 : (earned * 100 / total).round();
  return MatchResult(
    contato: contato,
    imovel: imovel,
    score: score,
    atende: atende,
    naoAtende: naoAtende,
  );
}

const scoreMinimo = 50;

List<MatchResult> sugestoesParaContato(Contato contato, List<Imovel> imoveis) {
  final r = [
    for (final i in imoveis) ?avaliarMatch(contato, i),
  ].where((m) => m.score >= scoreMinimo).toList();
  r.sort((a, b) => b.score.compareTo(a.score));
  return r;
}

List<MatchResult> sugestoesParaImovel(Imovel imovel, List<Contato> contatos) {
  final r = [
    for (final c in contatos) ?avaliarMatch(c, imovel),
  ].where((m) => m.score >= scoreMinimo).toList();
  r.sort((a, b) => b.score.compareTo(a.score));
  return r;
}
