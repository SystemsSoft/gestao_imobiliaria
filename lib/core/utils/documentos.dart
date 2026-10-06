/// Apenas os dígitos de um documento.
String soDigitos(String s) => s.replaceAll(RegExp(r'\D'), '');

bool _todosIguais(String d) => d.split('').every((c) => c == d[0]);

bool validarCpf(String valor) {
  final d = soDigitos(valor);
  if (d.length != 11 || _todosIguais(d)) return false;
  int dv(int n) {
    var soma = 0;
    for (var i = 0; i < n; i++) {
      soma += int.parse(d[i]) * (n + 1 - i);
    }
    final r = (soma * 10) % 11;
    return r == 10 ? 0 : r;
  }

  return dv(9) == int.parse(d[9]) && dv(10) == int.parse(d[10]);
}

bool validarCnpj(String valor) {
  final d = soDigitos(valor);
  if (d.length != 14 || _todosIguais(d)) return false;
  int dv(int n) {
    const pesos = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    var soma = 0;
    for (var i = 0; i < n; i++) {
      soma += int.parse(d[i]) * pesos[13 - n + i];
    }
    final r = soma % 11;
    return r < 2 ? 0 : 11 - r;
  }

  return dv(12) == int.parse(d[12]) && dv(13) == int.parse(d[13]);
}

/// CPF (11 dígitos) ou CNPJ (14 dígitos) válido.
bool validarCpfCnpj(String valor) {
  final n = soDigitos(valor).length;
  return n == 11 ? validarCpf(valor) : n == 14 && validarCnpj(valor);
}

/// Último dia útil (segunda a sexta) do mês, sem considerar feriados.
DateTime ultimoDiaUtil(int ano, int mes) {
  var d = DateTime(ano, mes + 1, 0);
  while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
    d = d.subtract(const Duration(days: 1));
  }
  return d;
}
