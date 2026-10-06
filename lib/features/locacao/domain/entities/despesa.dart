import 'locacao_enums.dart';

/// Despesa fixa (mensal) ou extraordinária vinculada a um contrato.
class Despesa {
  const Despesa({
    required this.id,
    required this.contratoId,
    required this.descricao,
    required this.valor,
    required this.competenciaInicio,
    this.natureza = NaturezaDespesa.fixa,
    this.responsavel = ResponsavelDespesa.locatario,
    this.competenciaFim,
    this.dedutivelIR = false,
  });

  final String id;
  final String contratoId;
  final String descricao;
  final double valor;
  final NaturezaDespesa natureza;
  final ResponsavelDespesa responsavel;
  final DateTime competenciaInicio;

  /// Só para despesas fixas; nulo = enquanto durar o contrato.
  final DateTime? competenciaFim;

  /// IPTU, condomínio etc. pagos pelo locador podem ser deduzidos da base
  /// de cálculo do Imposto de Renda.
  final bool dedutivelIR;

  bool incideEm(DateTime competencia) {
    final c = competenciaDe(competencia);
    final ini = competenciaDe(competenciaInicio);
    if (natureza == NaturezaDespesa.extraordinaria) return c == ini;
    if (c.isBefore(ini)) return false;
    final fim = competenciaFim;
    return fim == null || !c.isAfter(competenciaDe(fim));
  }
}

/// Descrições sugeridas ao lançar despesas.
const despesasSugeridas = [
  'Condomínio',
  'IPTU',
  'Seguro incêndio',
  'Taxa de lixo',
  'Fundo de reserva',
  'Reparo / manutenção',
  'Pintura',
  'Obras estruturais',
];
