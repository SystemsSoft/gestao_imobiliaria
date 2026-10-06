import '../../../../core/errors/domain_exception.dart';
import '../entities/conta_bancaria.dart';
import '../entities/financeiro_enums.dart';
import '../entities/fluxo_caixa.dart';
import '../entities/indice_mensal.dart';
import '../entities/lancamento.dart';
import '../entities/linha_extrato.dart';
import '../repositories/financeiro_repositories.dart';
import '../services/conciliacao_service.dart';
import '../services/fluxo_caixa_service.dart';

class ObservarContasBancarias {
  const ObservarContasBancarias(this._repo);
  final ContaBancariaRepository _repo;

  Stream<List<ContaBancaria>> call() => _repo.observar();
}

class ListarContasBancarias {
  const ListarContasBancarias(this._repo);
  final ContaBancariaRepository _repo;

  Future<List<ContaBancaria>> call() => _repo.listar();
}

class SalvarContaBancaria {
  const SalvarContaBancaria(this._repo);
  final ContaBancariaRepository _repo;

  Future<void> call(ContaBancaria c) {
    if (c.nome.trim().isEmpty) {
      throw const DomainException('Informe o nome da conta.');
    }
    return _repo.salvar(c);
  }
}

class RemoverContaBancaria {
  const RemoverContaBancaria(this._repo, this._extrato, this._lancamentos);
  final ContaBancariaRepository _repo;
  final ExtratoRepository _extrato;
  final LancamentoRepository _lancamentos;

  Future<void> call(String id) async {
    final usada =
        (await _extrato.listar()).any((l) => l.contaId == id) ||
        (await _lancamentos.listar()).any((l) => l.contaBaixaId == id);
    if (usada) {
      throw const DomainException(
        'A conta tem movimentações e não pode ser excluída.',
      );
    }
    await _repo.remover(id);
  }
}

class CalcularFluxoCaixa {
  const CalcularFluxoCaixa([this._service = const FluxoCaixaService()]);
  final FluxoCaixaService _service;

  FluxoAno call({
    required List<Lancamento> lancamentos,
    required List<ContaBancaria> contas,
    required int ano,
    required RegimeFluxo regime,
  }) => _service.calcular(
    lancamentos: lancamentos,
    contas: contas,
    ano: ano,
    regime: regime,
  );
}

// ---- Extrato e conciliação

class ObservarExtrato {
  const ObservarExtrato(this._repo);
  final ExtratoRepository _repo;

  Stream<List<LinhaExtrato>> call() => _repo.observar();
}

class SalvarLinhaExtrato {
  const SalvarLinhaExtrato(this._repo);
  final ExtratoRepository _repo;

  Future<void> call(LinhaExtrato l) {
    if (l.contaId.isEmpty) {
      throw const DomainException('Selecione a conta bancária.');
    }
    if (l.descricao.trim().isEmpty) {
      throw const DomainException('Informe a descrição.');
    }
    if (l.valor == 0) throw const DomainException('Informe o valor.');
    return _repo.salvar(l);
  }
}

class RemoverLinhaExtrato {
  const RemoverLinhaExtrato(this._repo);
  final ExtratoRepository _repo;

  Future<void> call(String id) => _repo.remover(id);
}

class ConciliarLinha {
  const ConciliarLinha(this._repo);
  final ExtratoRepository _repo;

  Future<void> call(LinhaExtrato linha, Lancamento lancamento) async {
    if ((linha.valor - lancamento.baixaComSinal).abs() > 0.005) {
      throw const DomainException(
        'Os valores do extrato e da baixa são diferentes.',
      );
    }
    final ja = (await _repo.listar()).any(
      (x) => x.lancamentoId == lancamento.id,
    );
    if (ja) {
      throw const DomainException(
        'Esta baixa já está conciliada com outra linha.',
      );
    }
    await _repo.salvar(linha.comLancamento(lancamento.id));
  }
}

class DesfazerConciliacao {
  const DesfazerConciliacao(this._repo);
  final ExtratoRepository _repo;

  Future<void> call(LinhaExtrato linha) =>
      _repo.salvar(linha.comLancamento(null));
}

/// Concilia todas as sugestões automáticas; devolve quantas foram feitas.
class ConciliarAutomaticamente {
  const ConciliarAutomaticamente(
    this._repo, [
    this._service = const ConciliacaoService(),
  ]);
  final ExtratoRepository _repo;
  final ConciliacaoService _service;

  Future<int> call(List<Lancamento> lancamentos, String contaId) async {
    final linhas = await _repo.listar();
    final sugestoes = _service.sugerir(lancamentos, linhas, contaId);
    for (final s in sugestoes) {
      await _repo.salvar(s.linha.comLancamento(s.lancamento.id));
    }
    return sugestoes.length;
  }
}

// ---- Índices e configuração

class ObservarIndices {
  const ObservarIndices(this._repo);
  final IndiceRepository _repo;

  Stream<List<IndiceMensal>> call() => _repo.observar();
}

class SalvarIndice {
  const SalvarIndice(this._repo);
  final IndiceRepository _repo;

  Future<void> call(IndiceMensal i) {
    if (i.indice == IndiceMonetario.nenhum) {
      throw const DomainException('Selecione o índice.');
    }
    if (i.mes < 1 || i.mes > 12) throw const DomainException('Mês inválido.');
    if (i.percentual < -50 || i.percentual > 100) {
      throw const DomainException('Variação mensal fora do esperado.');
    }
    return _repo.salvar(i);
  }
}

class RemoverIndice {
  const RemoverIndice(this._repo);
  final IndiceRepository _repo;

  Future<void> call(String id) => _repo.remover(id);
}

class ObservarConfiguracaoFinanceira {
  const ObservarConfiguracaoFinanceira(this._repo);
  final ConfiguracaoFinanceiraRepository _repo;

  Stream<ConfiguracaoFinanceira> call() => _repo.observar();
}

class ObterConfiguracaoFinanceira {
  const ObterConfiguracaoFinanceira(this._repo);
  final ConfiguracaoFinanceiraRepository _repo;

  Future<ConfiguracaoFinanceira> call() => _repo.obter();
}

class SalvarConfiguracaoFinanceira {
  const SalvarConfiguracaoFinanceira(this._repo);
  final ConfiguracaoFinanceiraRepository _repo;

  Future<void> call(ConfiguracaoFinanceira c) {
    if (c.multaPercentual < 0 || c.jurosMesPercentual < 0) {
      throw const DomainException('Multa e juros não podem ser negativos.');
    }
    return _repo.salvar(c);
  }
}
