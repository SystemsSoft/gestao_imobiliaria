/// Conversões comuns entre JSON da API e tipos Dart.
library;

double? lerDouble(Object? v) => (v as num?)?.toDouble();

int lerInt(Object? v, [int padrao = 0]) => (v as num?)?.toInt() ?? padrao;

String lerTexto(Object? v) => (v as String?) ?? '';

DateTime? lerData(Object? v) => v == null ? null : DateTime.parse(v as String);

/// Data sem hora (yyyy-MM-dd), como o servidor espera em campos de data.
String? escreverData(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

/// Data e hora local sem fuso (horário de Brasília no servidor).
String? escreverDataHora(DateTime? d) => d?.toIso8601String().split('.').first;

T lerEnum<T extends Enum>(List<T> valores, Object? nome, T padrao) =>
    valores.asNameMap()[nome] ?? padrao;

Set<T> lerEnums<T extends Enum>(List<T> valores, Object? nomes) => {
  for (final n in (nomes as List?) ?? const []) ?valores.asNameMap()[n],
};

List<String> nomes(Iterable<Enum> valores) => [for (final v in valores) v.name];
