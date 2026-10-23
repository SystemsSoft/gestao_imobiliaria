import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/core/utils/extenso.dart';
import 'package:gestao_imobiliaria/core/utils/formatters.dart';

void main() {
  group('valorPorExtenso', () {
    test('casos comuns', () {
      expect(valorPorExtenso(1), 'um real');
      expect(valorPorExtenso(0.5), 'cinquenta centavos');
      expect(valorPorExtenso(100), 'cem reais');
      expect(valorPorExtenso(1001), 'mil e um reais');
      expect(valorPorExtenso(2500), 'dois mil e quinhentos reais');
      expect(
        valorPorExtenso(1234.56),
        'mil duzentos e trinta e quatro reais e cinquenta e seis centavos',
      );
      expect(valorPorExtenso(1000000), 'um milhão de reais');
      expect(valorPorExtenso(3200), 'três mil e duzentos reais');
    });
  });

  test('máscaras e conversões', () {
    expect(parseMoney('1.234,56'), 1234.56);
    expect(moneyToText(1234.56), '1.234,56');
    TextEditingValue fmt(TextInputFormatter f, String t) =>
        f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: t));
    expect(fmt(cpfCnpjFormatter, '12345678901').text, '123.456.789-01');
    expect(fmt(cpfCnpjFormatter, '12345678000199').text, '12.345.678/0001-99');
    expect(fmt(phoneFormatter, '21987654321').text, '(21) 98765-4321');
    expect(fmt(cepFormatter, '24220000').text, '24220-000');
  });
}
