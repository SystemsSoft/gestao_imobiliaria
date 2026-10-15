import '../entities/boleto_bancario.dart';
import '../entities/conta_bancaria.dart';
import '../entities/indice_mensal.dart';
import '../entities/lancamento.dart';
import '../entities/linha_extrato.dart';

abstract interface class LancamentoRepository {
  Stream<List<Lancamento>> observar();
  Future<List<Lancamento>> listar();
  Future<Lancamento?> obter(String id);
  Future<void> salvar(Lancamento lancamento);
  Future<void> salvarTodos(List<Lancamento> lancamentos);
  Future<void> remover(String id);
}

abstract interface class ContaBancariaRepository {
  Stream<List<ContaBancaria>> observar();
  Future<List<ContaBancaria>> listar();
  Future<ContaBancaria?> obter(String id);
  Future<void> salvar(ContaBancaria conta);
  Future<void> remover(String id);
}

abstract interface class ExtratoRepository {
  Stream<List<LinhaExtrato>> observar();
  Future<List<LinhaExtrato>> listar();
  Future<void> salvar(LinhaExtrato linha);
  Future<void> remover(String id);
}

abstract interface class BoletoRepository {
  Stream<List<BoletoBancario>> observar();
  Future<List<BoletoBancario>> listar();

  /// Grava e devolve o boleto; com nosso número vazio, quem grava atribui o
  /// próximo da conta (sequencial, 10 dígitos).
  Future<BoletoBancario> salvar(BoletoBancario boleto);
}

abstract interface class IndiceRepository {
  Stream<List<IndiceMensal>> observar();
  Future<List<IndiceMensal>> listar();
  Future<void> salvar(IndiceMensal indice);
  Future<void> remover(String id);
}

abstract interface class ConfiguracaoFinanceiraRepository {
  Stream<ConfiguracaoFinanceira> observar();
  Future<ConfiguracaoFinanceira> obter();
  Future<void> salvar(ConfiguracaoFinanceira configuracao);
}
