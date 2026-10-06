import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/boleto_bancario.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/entities/indice_mensal.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/entities/linha_extrato.dart';

/// Armazenamento em memória do financeiro, até existir um backend.
class FinanceiroMemoryDataSource {
  final lancamentos = MemoryCollection<Lancamento>((e) => e.id);
  final contas = MemoryCollection<ContaBancaria>((e) => e.id);
  final extrato = MemoryCollection<LinhaExtrato>((e) => e.id);
  final boletos = MemoryCollection<BoletoBancario>((e) => e.id);
  final indices = MemoryCollection<IndiceMensal>((e) => e.id);
  final configuracao = MemoryCollection<ConfiguracaoFinanceira>(
    (_) => 'config',
  );

  /// Último nosso número emitido, por conta.
  final Map<String, int> sequenciaNossoNumero = {};
}
