import '../entities/cobranca.dart';
import '../entities/contrato_locacao.dart';
import '../entities/despesa.dart';
import '../entities/ir_mensal.dart';
import '../entities/locacao_enums.dart';
import '../services/tabela_ir.dart';
import 'repasse_usecases.dart';

/// Resumo anual do IR sobre aluguéis de um beneficiário, mês a mês, pelo
/// regime de caixa (mês do recebimento).
///
/// Aluguéis pagos por pessoa jurídica têm IR retido na fonte; os pagos por
/// pessoa física são somados no mês e calculados pelo carnê-leão.
class CalcularResumoIrAnual {
  const CalcularResumoIrAnual([
    this._repasse = const CalcularRepasse(),
    this._tabela = const TabelaIR(),
  ]);
  final CalcularRepasse _repasse;
  final TabelaIR _tabela;

  List<IrMensal> call({
    required String beneficiarioId,
    required int ano,
    required List<Cobranca> cobrancas,
    required List<ContratoLocacao> contratos,
    required List<Despesa> despesas,
    required bool Function(String contatoId) pessoaJuridica,
  }) {
    final bruto = List<double>.filled(13, 0);
    final deducoes = List<double>.filled(13, 0);
    final baseCarne = List<double>.filled(13, 0);
    final baseIrrf = List<double>.filled(13, 0);
    final irrf = List<double>.filled(13, 0);

    for (final c in cobrancas) {
      final pg = c.dataPagamento;
      if (c.status != StatusCobranca.paga || pg == null || pg.year != ano) {
        continue;
      }
      final contrato = contratos.where((k) => k.id == c.contratoId).firstOrNull;
      if (contrato == null) continue;
      final linhas = _repasse(
        cobranca: c,
        contrato: contrato,
        despesas: despesas,
        locatarioPessoaJuridica: pessoaJuridica(contrato.locatarioId),
        beneficiarioPessoaJuridica: pessoaJuridica,
      ).where((l) => l.beneficiario.contatoId == beneficiarioId);
      for (final l in linhas) {
        final m = pg.month;
        bruto[m] += l.bruto;
        deducoes[m] += l.bruto - l.baseIR;
        if (l.retencaoNaFonte) {
          baseIrrf[m] += l.baseIR;
          irrf[m] += l.irrf;
        } else {
          baseCarne[m] += l.baseIR;
        }
      }
    }

    return [
      for (var m = 1; m <= 12; m++)
        IrMensal(
          mes: m,
          rendimentoBruto: arredondar(bruto[m]),
          deducoes: arredondar(deducoes[m]),
          baseCarneLeao: arredondar(baseCarne[m]),
          impostoCarneLeao: _tabela.impostoMensal(baseCarne[m], ano: ano),
          baseIrrf: arredondar(baseIrrf[m]),
          irrfRetido: arredondar(irrf[m]),
        ),
    ];
  }
}
