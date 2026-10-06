import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _moneyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _plainMoneyFmt = NumberFormat('#,##0.00', 'pt_BR');
final _dateFmt = DateFormat('dd/MM/yyyy');
final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

String formatMoney(double? v) => v == null ? '—' : _moneyFmt.format(v);

String formatDate(DateTime? d) => d == null ? '' : _dateFmt.format(d);

String formatDateTime(DateTime? d) => d == null ? '' : _dateTimeFmt.format(d);

/// Valor monetário sem símbolo, para preencher campos ("1.234,56").
String moneyToText(double? v) => v == null ? '' : _plainMoneyFmt.format(v);

double? parseMoney(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  return int.parse(digits) / 100;
}

String decimalToText(double? v) {
  if (v == null) return '';
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  return s.replaceAll('.', ',');
}

double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

int? parseInt(String text) => int.tryParse(text.trim());

String intToText(int? v) => (v == null || v == 0) ? '' : v.toString();

/// Formata um campo de dinheiro digitando apenas números (centavos).
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = _plainMoneyFmt.format(int.parse(digits) / 100);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Máscara que depende da quantidade de dígitos digitados.
class DigitsMaskFormatter extends TextInputFormatter {
  DigitsMaskFormatter(this.maskFor, {required this.maxDigits});

  final String Function(int digits) maskFor;
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final mask = maskFor(digits.length);
    final buf = StringBuffer();
    var i = 0;
    for (final ch in mask.split('')) {
      if (i >= digits.length) break;
      if (ch == '#') {
        buf.write(digits[i++]);
      } else {
        buf.write(ch);
      }
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

final cpfCnpjFormatter = DigitsMaskFormatter(
  (n) => n <= 11 ? '###.###.###-##' : '##.###.###/####-##',
  maxDigits: 14,
);

final cepFormatter = DigitsMaskFormatter((_) => '#####-###', maxDigits: 8);

final phoneFormatter = DigitsMaskFormatter(
  (n) => n <= 10 ? '(##) ####-####' : '(##) #####-####',
  maxDigits: 11,
);
