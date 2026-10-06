import '../../../../core/domain/encargos.dart';
import '../../../../core/errors/domain_exception.dart';
import '../entities/parcela.dart';
import '../entities/venda.dart';
import '../entities/venda_enums.dart';
import '../repositories/parcela_repository.dart';
import '../repositories/venda_repository.dart';

class CalcularEncargosParcela {
  const CalcularEncargosParcela();

  Encargos call(Venda venda, Parcela parcela, DateTime dataPagamento) =>
      calcularEncargos(
        valor: parcela.valor,
        vencimento: parcela.vencimento,
        pagamento: dataPagamento,
        multaPercentual: venda.multaAtraso,
        jurosMesPercentual: venda.jurosMes,
      );
}

/// Registra o pagamento; com todas as parcelas pagas, a venda fica quitada.
class RegistrarPagamentoParcela {
  const RegistrarPagamentoParcela(this._parcelas, this._vendas, this._encargos);
  final ParcelaRepository _parcelas;
  final VendaRepository _vendas;
  final CalcularEncargosParcela _encargos;

  Future<void> call(Parcela p, DateTime data, {double? valorPago}) async {
    if (p.status != StatusParcela.aberta) {
      throw const DomainException('Só parcelas em aberto podem ser pagas.');
    }
    final venda = await _vendas.obter(p.vendaId);
    if (venda == null) throw const DomainException('Venda não encontrada.');
    final e = _encargos(venda, p, data);
    await _parcelas.salvar(
      p.pagar(
        data: data,
        valorPago: valorPago ?? arredondar(e.devido(p.valor)),
        multa: e.multa,
        jurosMora: e.juros,
        desconto: e.desconto,
      ),
    );
    final restantes = (await _parcelas.daVenda(
      venda.id,
    )).where((x) => x.status == StatusParcela.aberta);
    if (restantes.isEmpty) {
      await _vendas.salvar(venda.copyWith(status: StatusVenda.quitada));
    }
  }
}

class EstornarPagamentoParcela {
  const EstornarPagamentoParcela(this._parcelas, this._vendas);
  final ParcelaRepository _parcelas;
  final VendaRepository _vendas;

  Future<void> call(Parcela p) async {
    await _parcelas.salvar(p.estornar());
    final venda = await _vendas.obter(p.vendaId);
    if (venda != null && venda.status == StatusVenda.quitada) {
      await _vendas.salvar(venda.copyWith(status: StatusVenda.ativa));
    }
  }
}

/// Resumo financeiro de uma venda a partir das parcelas.
class ResumoFinanciamento {
  const ResumoFinanciamento(this.parcelas);

  final List<Parcela> parcelas;

  Iterable<Parcela> get _pagas =>
      parcelas.where((p) => p.status == StatusParcela.paga);
  Iterable<Parcela> get _abertas =>
      parcelas.where((p) => p.status == StatusParcela.aberta);

  int get quantidadePagas => _pagas.length;
  int get quantidade => parcelas.length;
  double get totalRecebido => _pagas.fold(0, (s, p) => s + (p.valorPago ?? 0));
  double get totalJuros => parcelas.fold(0, (s, p) => s + p.juros);
  double get totalAPagar => parcelas.fold(0, (s, p) => s + p.valor);

  /// Valor para quitar hoje: o principal ainda não amortizado (sem os juros
  /// futuros).
  double get saldoDevedor =>
      arredondar(_abertas.fold(0, (s, p) => s + p.amortizacao));

  Parcela? get proxima {
    final l = _abertas.toList()
      ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
    return l.firstOrNull;
  }
}
