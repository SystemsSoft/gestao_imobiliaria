import '../entities/cobranca.dart';
import '../entities/contrato_locacao.dart';
import '../entities/despesa.dart';
import '../entities/linha_repasse.dart';
import '../entities/locacao_enums.dart';
import '../repositories/repasse_repository.dart';
import '../services/tabela_ir.dart';

/// Divide uma cobrança paga entre os beneficiários, descontando taxa de
/// administração, intermediação (1º mês), despesas do proprietário e o IR
/// retido quando o locatário é pessoa jurídica.
class CalcularRepasse {
  const CalcularRepasse([this._tabela = const TabelaIR()]);
  final TabelaIR _tabela;

  List<LinhaRepasse> call({
    required Cobranca cobranca,
    required ContratoLocacao contrato,
    required List<Despesa> despesas,
    required bool locatarioPessoaJuridica,
    required bool Function(String contatoId) beneficiarioPessoaJuridica,
  }) {
    if (cobranca.status != StatusCobranca.paga) return const [];
    final comp = cobranca.competencia;
    final ano = (cobranca.dataPagamento ?? comp).year;
    final doProprietario = despesas.where(
      (d) =>
          d.contratoId == contrato.id &&
          d.responsavel == ResponsavelDespesa.proprietario &&
          d.incideEm(comp),
    );
    final totalDespesas = doProprietario.fold<double>(0, (s, d) => s + d.valor);
    final dedutiveis = doProprietario
        .where((d) => d.dedutivelIR)
        .fold<double>(0, (s, d) => s + d.valor);
    final encargos = cobranca.multa + cobranca.juros - cobranca.desconto;
    final intermediacao = contrato.primeiraCompetencia(comp)
        ? cobranca.valorAluguel * contrato.taxaIntermediacao / 100
        : 0.0;

    return [
      for (final b in contrato.beneficiarios)
        _linha(
          cobranca: cobranca,
          contrato: contrato,
          beneficiario: b,
          cota: b.percentual / 100,
          encargos: encargos,
          intermediacao: intermediacao,
          despesas: totalDespesas,
          dedutiveis: dedutiveis,
          retem:
              locatarioPessoaJuridica &&
              !beneficiarioPessoaJuridica(b.contatoId),
          ano: ano,
        ),
    ];
  }

  LinhaRepasse _linha({
    required Cobranca cobranca,
    required ContratoLocacao contrato,
    required Beneficiario beneficiario,
    required double cota,
    required double encargos,
    required double intermediacao,
    required double despesas,
    required double dedutiveis,
    required bool retem,
    required int ano,
  }) {
    final aluguel = arredondar(cobranca.valorAluguel * cota);
    final enc = arredondar(encargos * cota);
    final taxaAdm = arredondar(
      (aluguel + enc) * contrato.taxaAdministracao / 100,
    );
    final ded = arredondar(dedutiveis * cota);
    final base = arredondar(
      (aluguel + enc - taxaAdm - ded).clamp(0, double.infinity),
    );
    return LinhaRepasse(
      cobranca: cobranca,
      contrato: contrato,
      beneficiario: beneficiario,
      aluguel: aluguel,
      encargos: enc,
      taxaAdministracao: taxaAdm,
      taxaIntermediacao: arredondar(intermediacao * cota),
      despesasProprietario: arredondar(despesas * cota),
      baseIR: base,
      irrf: retem ? _tabela.impostoMensal(base, ano: ano) : 0,
      retencaoNaFonte: retem,
    );
  }
}

class ObservarRepassesRealizados {
  const ObservarRepassesRealizados(this._repo);
  final RepasseRepository _repo;

  Stream<Map<String, DateTime>> call() => _repo.observarRealizados();
}

class MarcarRepasse {
  const MarcarRepasse(this._repo);
  final RepasseRepository _repo;

  /// [data] nula desfaz a marcação.
  Future<void> call(String cobrancaId, String contatoId, DateTime? data) =>
      _repo.marcar(cobrancaId, contatoId, data);
}
