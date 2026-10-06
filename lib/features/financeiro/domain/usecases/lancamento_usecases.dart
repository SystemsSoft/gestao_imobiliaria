import '../../../../core/domain/encargos.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/datas.dart';
import '../../../../core/utils/id.dart';
import '../entities/financeiro_enums.dart';
import '../entities/indice_mensal.dart';
import '../entities/lancamento.dart';
import '../repositories/financeiro_repositories.dart';
import '../services/atualizacao_monetaria.dart';

class ObservarLancamentos {
  const ObservarLancamentos(this._repo);
  final LancamentoRepository _repo;

  Stream<List<Lancamento>> call() => _repo.observar();
}

/// Valida e salva. Com [repetir] > 1 cria uma conta por mês, a partir do
/// vencimento informado.
class SalvarLancamento {
  const SalvarLancamento(this._repo);
  final LancamentoRepository _repo;

  Future<void> call(Lancamento l, {int repetir = 1}) async {
    if (l.descricao.trim().isEmpty) {
      throw const DomainException('Informe a descrição.');
    }
    if (l.valor <= 0) throw const DomainException('Informe o valor.');
    if (l.multaPercentual < 0 || l.jurosMesPercentual < 0) {
      throw const DomainException('Multa e juros não podem ser negativos.');
    }
    if (repetir < 1 || repetir > 60) {
      throw const DomainException('A repetição deve ser de 1 a 60 meses.');
    }
    if (repetir == 1) {
      await _repo.salvar(l);
      return;
    }
    final grupo = gerarId();
    await _repo.salvarTodos([
      for (var i = 0; i < repetir; i++)
        l.copyWith(
          id: gerarId(),
          vencimento: somarMeses(l.vencimento, i),
          parcelaNumero: i + 1,
          parcelaTotal: repetir,
          grupoId: grupo,
        ),
    ]);
  }
}

class RemoverLancamento {
  const RemoverLancamento(this._repo);
  final LancamentoRepository _repo;

  Future<void> call(Lancamento l) {
    if (l.baixado) {
      throw const DomainException('Estorne a baixa antes de excluir.');
    }
    return _repo.remover(l.id);
  }
}

class CalcularEncargosLancamento {
  const CalcularEncargosLancamento([this._calc = const AtualizacaoMonetaria()]);
  final AtualizacaoMonetaria _calc;

  ({Encargos encargos, VariacaoAcumulada variacao}) call(
    Lancamento l,
    DateTime pagamento,
    List<IndiceMensal> indices,
  ) => _calc.calcular(l, pagamento, indices);
}

/// Dá baixa na conta (pagamento ou recebimento) calculando juros, multa e
/// atualização monetária pela data.
class BaixarLancamento {
  const BaixarLancamento(this._repo, this._indices, this._calc);
  final LancamentoRepository _repo;
  final IndiceRepository _indices;
  final CalcularEncargosLancamento _calc;

  Future<Lancamento> call(
    Lancamento l,
    DateTime data, {
    double? valorBaixa,
    MeioPagamento? meio,
    String? contaId,
  }) async {
    if (!l.emAberto) {
      throw const DomainException('Só contas em aberto podem ser baixadas.');
    }
    final r = _calc(l, data, await _indices.listar());
    final e = r.encargos;
    final baixado = l.copyWith(
      status: StatusLancamento.baixado,
      dataBaixa: soData(data),
      valorBaixa: valorBaixa ?? arredondar(e.devido(l.valor)),
      multa: e.multa,
      juros: e.juros,
      correcao: e.correcao,
      desconto: e.desconto,
      meio: meio,
      contaBaixaId: contaId,
    );
    await _repo.salvar(baixado);
    return baixado;
  }
}

class EstornarBaixa {
  const EstornarBaixa(this._repo, this._extrato);
  final LancamentoRepository _repo;
  final ExtratoRepository _extrato;

  Future<void> call(Lancamento l) async {
    if (!l.baixado) return;
    final conciliada = (await _extrato.listar()).any(
      (x) => x.lancamentoId == l.id,
    );
    if (conciliada) {
      throw const DomainException(
        'Esta baixa está conciliada com o extrato. Desfaça a conciliação primeiro.',
      );
    }
    await _repo.salvar(
      l.copyWith(status: StatusLancamento.aberto, limparBaixa: true),
    );
  }
}

class CancelarLancamento {
  const CancelarLancamento(this._repo);
  final LancamentoRepository _repo;

  Future<void> call(Lancamento l) {
    if (l.baixado) {
      throw const DomainException('Estorne a baixa antes de cancelar.');
    }
    return _repo.salvar(l.copyWith(status: StatusLancamento.cancelado));
  }
}
