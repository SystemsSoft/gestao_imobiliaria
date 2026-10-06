import 'cobranca.dart';
import 'contrato_locacao.dart';

/// Parte de uma cobrança paga que cabe a um beneficiário.
class LinhaRepasse {
  const LinhaRepasse({
    required this.cobranca,
    required this.contrato,
    required this.beneficiario,
    required this.aluguel,
    required this.encargos,
    required this.taxaAdministracao,
    required this.taxaIntermediacao,
    required this.despesasProprietario,
    required this.baseIR,
    required this.irrf,
    required this.retencaoNaFonte,
  });

  final Cobranca cobranca;
  final ContratoLocacao contrato;
  final Beneficiario beneficiario;

  /// Aluguel recebido (cota do beneficiário).
  final double aluguel;

  /// Multa + juros − desconto de pontualidade (cota do beneficiário).
  final double encargos;
  final double taxaAdministracao;
  final double taxaIntermediacao;
  final double despesasProprietario;

  /// Base de cálculo do Imposto de Renda (rendimento − deduções legais).
  final double baseIR;

  /// IR retido na fonte pelo locatário pessoa jurídica.
  final double irrf;

  /// Verdadeiro quando o locatário é PJ (retém IR); senão, carnê-leão.
  final bool retencaoNaFonte;

  double get bruto => aluguel + encargos;

  double get liquido =>
      bruto -
      taxaAdministracao -
      taxaIntermediacao -
      despesasProprietario -
      irrf;
}
