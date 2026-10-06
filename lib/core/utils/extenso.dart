const _unidades = [
  '', 'um', 'dois', 'três', 'quatro', 'cinco', 'seis', 'sete', 'oito', //
  'nove', 'dez', 'onze', 'doze', 'treze', 'quatorze', 'quinze', 'dezesseis',
  'dezessete', 'dezoito', 'dezenove',
];
const _dezenas = [
  '', '', 'vinte', 'trinta', 'quarenta', 'cinquenta', 'sessenta', 'setenta', //
  'oitenta', 'noventa',
];
const _centenas = [
  '', 'cento', 'duzentos', 'trezentos', 'quatrocentos', 'quinhentos', //
  'seiscentos', 'setecentos', 'oitocentos', 'novecentos',
];
const _escalaSing = ['', 'mil', 'milhão', 'bilhão'];
const _escalaPlur = ['', 'mil', 'milhões', 'bilhões'];

String _ate999(int n) {
  if (n == 100) return 'cem';
  final partes = <String>[];
  final c = n ~/ 100, r = n % 100;
  if (c > 0) partes.add(_centenas[c]);
  if (r > 0) {
    if (r < 20) {
      partes.add(_unidades[r]);
    } else {
      final d = r ~/ 10, u = r % 10;
      partes.add(u == 0 ? _dezenas[d] : '${_dezenas[d]} e ${_unidades[u]}');
    }
  }
  return partes.join(' e ');
}

String numeroPorExtenso(int n) {
  if (n == 0) return 'zero';
  final grupos = <int>[];
  for (var x = n; x > 0; x ~/= 1000) {
    grupos.add(x % 1000);
  }
  final partes = <String>[];
  var ultimoGrupo = 0;
  for (var i = grupos.length - 1; i >= 0; i--) {
    final g = grupos[i];
    if (g == 0) continue;
    if (i == 1 && g == 1) {
      partes.add('mil');
    } else {
      final escala = i == 0
          ? ''
          : ' ${g == 1 ? _escalaSing[i] : _escalaPlur[i]}';
      partes.add('${_ate999(g)}$escala');
    }
    ultimoGrupo = g;
  }
  if (partes.length == 1) return partes.first;
  // "mil e quinhentos", mas "mil duzentos e trinta".
  final conectivo = (ultimoGrupo < 100 || ultimoGrupo % 100 == 0) ? ' e ' : ' ';
  return partes.sublist(0, partes.length - 1).join(' ') +
      conectivo +
      partes.last;
}

/// Valor monetário por extenso: 1234.5 → "mil duzentos e trinta e quatro
/// reais e cinquenta centavos".
String valorPorExtenso(double valor) {
  final centavosTotais = (valor * 100).round();
  final reais = centavosTotais ~/ 100;
  final centavos = centavosTotais % 100;
  final partes = <String>[];
  if (reais > 0) {
    final de = reais % 1000000 == 0 ? ' de' : '';
    partes.add(
      '${numeroPorExtenso(reais)}$de ${reais == 1 ? 'real' : 'reais'}',
    );
  }
  if (centavos > 0) {
    partes.add(
      '${numeroPorExtenso(centavos)} '
      '${centavos == 1 ? 'centavo' : 'centavos'}',
    );
  }
  return partes.isEmpty ? 'zero real' : partes.join(' e ');
}
