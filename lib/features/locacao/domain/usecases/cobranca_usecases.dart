import 'dart:math';

import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../entities/cobranca.dart';
import '../entities/contrato_locacao.dart';
import '../entities/despesa.dart';
import '../../../../core/domain/encargos.dart';
import '../entities/locacao_enums.dart';
import '../repositories/cobranca_repository.dart';
import '../repositories/contrato_locacao_repository.dart';
import '../repositories/despesa_repository.dart';

class ObservarCobrancas {
  const ObservarCobrancas(this._repo);
  final CobrancaRepository _repo;

  Stream<List<Cobranca>> call() => _repo.observar();
}

/// Vencimento na competência, ajustado para o último dia em meses curtos.
DateTime vencimentoDe(ContratoLocacao c, DateTime competencia) {
  final ultimoDia = DateTime(competencia.year, competencia.month + 1, 0).day;
  return DateTime(
    competencia.year,
    competencia.month,
    min(c.diaVencimento, ultimoDia),
  );
}

/// Aluguel + despesas a cargo do locatário que incidem na competência.
List<ItemCobranca> itensDaCobranca(
  ContratoLocacao contrato,
  DateTime competencia,
  List<Despesa> despesas,
) => [
  ItemCobranca(
    descricao: 'Aluguel ${competenciaLabel(competencia)}',
    valor: contrato.valorAluguel,
    tipo: TipoItemCobranca.aluguel,
  ),
  for (final d in despesas)
    if (d.contratoId == contrato.id &&
        d.responsavel == ResponsavelDespesa.locatario &&
        d.incideEm(competencia))
      ItemCobranca(
        descricao: d.descricao,
        valor: d.valor,
        tipo: TipoItemCobranca.despesa,
      ),
];

/// Cria as cobranças dos contratos vigentes na competência e atualiza os
/// itens das cobranças ainda em aberto (ex.: despesa lançada depois).
class GerarCobrancasDoMes {
  const GerarCobrancasDoMes(this._contratos, this._despesas, this._cobrancas);
  final ContratoLocacaoRepository _contratos;
  final DespesaRepository _despesas;
  final CobrancaRepository _cobrancas;

  Future<({int criadas, int atualizadas})> call(DateTime competencia) async {
    final comp = competenciaDe(competencia);
    final despesas = await _despesas.listar();
    final existentes = await _cobrancas.listar();
    var criadas = 0, atualizadas = 0;
    for (final c in await _contratos.listar()) {
      if (!c.vigenteEm(comp)) continue;
      final itens = itensDaCobranca(c, comp, despesas);
      final atual = existentes
          .where((e) => e.contratoId == c.id && e.competencia == comp)
          .firstOrNull;
      if (atual == null) {
        await _cobrancas.salvar(
          Cobranca(
            id: gerarId(),
            contratoId: c.id,
            competencia: comp,
            vencimento: vencimentoDe(c, comp),
            itens: itens,
          ),
        );
        criadas++;
      } else if (atual.status == StatusCobranca.aberta) {
        await _cobrancas.salvar(atual.copyWith(itens: itens));
        atualizadas++;
      }
    }
    return (criadas: criadas, atualizadas: atualizadas);
  }
}

/// Multa e juros pro rata die após o vencimento, ou desconto de
/// pontualidade até o vencimento.
class CalcularEncargos {
  const CalcularEncargos();

  Encargos call(
    ContratoLocacao contrato,
    Cobranca cobranca,
    DateTime dataPagamento,
  ) => calcularEncargos(
    valor: cobranca.total,
    vencimento: cobranca.vencimento,
    pagamento: dataPagamento,
    multaPercentual: contrato.multaAtraso,
    jurosMesPercentual: contrato.jurosMes,
    descontoPontualidade: contrato.descontoPontualidade,
  );
}

class RegistrarPagamento {
  const RegistrarPagamento(this._cobrancas, this._contratos, this._encargos);
  final CobrancaRepository _cobrancas;
  final ContratoLocacaoRepository _contratos;
  final CalcularEncargos _encargos;

  Future<void> call(
    Cobranca cobranca,
    DateTime dataPagamento, {
    double? valorPago,
  }) async {
    if (cobranca.status != StatusCobranca.aberta) {
      throw const DomainException('Só cobranças em aberto podem ser pagas.');
    }
    final contrato = await _contratos.obter(cobranca.contratoId);
    if (contrato == null) {
      throw const DomainException('Contrato não encontrado.');
    }
    final e = _encargos(contrato, cobranca, dataPagamento);
    await _cobrancas.salvar(
      cobranca.copyWith(
        status: StatusCobranca.paga,
        dataPagamento: dataPagamento,
        valorPago: valorPago ?? arredondar(e.devido(cobranca.total)),
        multa: e.multa,
        juros: e.juros,
        desconto: e.desconto,
      ),
    );
  }
}

class EstornarPagamento {
  const EstornarPagamento(this._cobrancas);
  final CobrancaRepository _cobrancas;

  Future<void> call(Cobranca c) => _cobrancas.salvar(
    c.copyWith(status: StatusCobranca.aberta, limparPagamento: true),
  );
}

class CancelarCobranca {
  const CancelarCobranca(this._cobrancas);
  final CobrancaRepository _cobrancas;

  Future<void> call(Cobranca c) {
    if (c.status == StatusCobranca.paga) {
      throw const DomainException('Estorne o pagamento antes de cancelar.');
    }
    return _cobrancas.salvar(c.copyWith(status: StatusCobranca.cancelada));
  }
}

class RemoverCobranca {
  const RemoverCobranca(this._cobrancas);
  final CobrancaRepository _cobrancas;

  Future<void> call(String id) => _cobrancas.remover(id);
}
