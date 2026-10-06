import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../entities/parcela.dart';
import '../entities/venda.dart';
import '../entities/venda_enums.dart';
import '../repositories/parcela_repository.dart';
import '../repositories/venda_repository.dart';
import '../services/calculadora_financiamento.dart';

class ObservarVendas {
  const ObservarVendas(this._repo);
  final VendaRepository _repo;

  Stream<List<Venda>> call() => _repo.observar();
}

class ObservarParcelas {
  const ObservarParcelas(this._repo);
  final ParcelaRepository _repo;

  Stream<List<Parcela>> call() => _repo.observar();
}

/// Prévia da tabela de parcelas exibida no formulário.
class SimularFinanciamento {
  const SimularFinanciamento([this._calc = const CalculadoraFinanciamento()]);
  final CalculadoraFinanciamento _calc;

  List<ParcelaPlano> call(double valorFinanciado, PlanoFinanciamento plano) =>
      _calc.calcular(valorFinanciado, plano);
}

/// Gera as parcelas (entrada + mensais) do financiamento próprio.
List<Parcela> gerarParcelas(
  Venda v, [
  CalculadoraFinanciamento calc = const CalculadoraFinanciamento(),
]) {
  final plano = v.plano;
  if (!v.financiamentoProprio || plano == null) return const [];
  final tabela = calc.calcular(v.valorFinanciado, plano);
  return [
    if (v.valorEntrada > 0)
      Parcela(
        id: gerarId(),
        vendaId: v.id,
        numero: 0,
        totalParcelas: tabela.length,
        tipo: TipoParcela.entrada,
        vencimento: v.vencimentoEntrada ?? v.dataVenda,
        valor: v.valorEntrada,
        amortizacao: v.valorEntrada,
        juros: 0,
        saldoDevedor: v.valorFinanciado,
      ),
    for (final p in tabela)
      Parcela(
        id: gerarId(),
        vendaId: v.id,
        numero: p.numero,
        totalParcelas: tabela.length,
        tipo: TipoParcela.mensal,
        vencimento: p.vencimento,
        valor: p.valor,
        amortizacao: p.amortizacao,
        juros: p.juros,
        saldoDevedor: p.saldoDevedor,
      ),
  ];
}

/// Valida e salva a venda. Gera (ou regera) as parcelas quando as condições
/// de pagamento mudam, desde que nenhuma parcela tenha sido paga.
class SalvarVenda {
  const SalvarVenda(this._vendas, this._parcelas);
  final VendaRepository _vendas;
  final ParcelaRepository _parcelas;

  Future<Venda> call(Venda v) async {
    _validar(v);
    final anterior = await _vendas.obter(v.id);
    final salva = v.numero.isEmpty
        ? v.copyWith(numero: await _vendas.proximoNumero())
        : v;

    if (anterior == null || _condicoesMudaram(anterior, v)) {
      final atuais = await _parcelas.daVenda(v.id);
      if (atuais.any((p) => p.status == StatusParcela.paga)) {
        throw const DomainException(
          'Há parcelas pagas: as condições de pagamento não podem ser alteradas.',
        );
      }
      await _parcelas.removerDaVenda(v.id);
      await _parcelas.salvarTodas(gerarParcelas(salva));
    }
    await _vendas.salvar(salva);
    return salva;
  }

  bool _condicoesMudaram(Venda a, Venda b) =>
      a.formaPagamento != b.formaPagamento ||
      a.valorVenda != b.valorVenda ||
      a.valorEntrada != b.valorEntrada ||
      a.vencimentoEntrada != b.vencimentoEntrada ||
      !(b.plano?.mesmoQue(a.plano) ?? a.plano == null);

  void _validar(Venda v) {
    if (v.imovelId.isEmpty) throw const DomainException('Selecione o imóvel.');
    if (v.compradores.isEmpty) {
      throw const DomainException('Informe ao menos um comprador.');
    }
    if (v.valorVenda <= 0) {
      throw const DomainException('Informe o valor da venda.');
    }
    if (v.valorEntrada < 0 || v.valorEntrada > v.valorVenda) {
      throw const DomainException(
        'A entrada deve estar entre zero e o valor da venda.',
      );
    }
    _somaCem(v.vendedores, 'vendedores');
    if (v.vendedores.any((p) => p.contatoId == null)) {
      throw const DomainException('Selecione todos os vendedores.');
    }
    if (v.vendedores.any((p) => v.compradores.contains(p.contatoId))) {
      throw const DomainException(
        'Uma pessoa não pode ser compradora e vendedora.',
      );
    }
    if (v.comissaoPercentual < 0) {
      throw const DomainException('Comissão inválida.');
    }
    if (v.comissaoPercentual > 0) _somaCem(v.corretores, 'divisão da comissão');
    if (v.financiamentoProprio) {
      final p = v.plano;
      if (p == null || p.numeroParcelas < 1) {
        throw const DomainException('Informe a quantidade de parcelas.');
      }
      if (p.taxaJurosMes < 0) {
        throw const DomainException('Taxa de juros inválida.');
      }
      if (v.valorFinanciado <= 0) {
        throw const DomainException('Não há saldo a financiar.');
      }
    }
  }

  void _somaCem(List<Participacao> ps, String nome) {
    if (ps.isEmpty) throw DomainException('Informe os $nome.');
    final soma = ps.fold<double>(0, (s, p) => s + p.percentual);
    if ((soma - 100).abs() > 0.01) {
      throw DomainException(
        'Os percentuais de $nome somam ${soma.toStringAsFixed(2)}%; devem somar 100%.',
      );
    }
  }
}

class RemoverVenda {
  const RemoverVenda(this._vendas, this._parcelas);
  final VendaRepository _vendas;
  final ParcelaRepository _parcelas;

  Future<void> call(String id) async {
    await _parcelas.removerDaVenda(id);
    await _vendas.remover(id);
  }
}

/// Marca (ou desmarca, com [data] nula) a comissão de um participante como paga.
class MarcarComissaoPaga {
  const MarcarComissaoPaga(this._vendas);
  final VendaRepository _vendas;

  Future<void> call(Venda v, int indice, DateTime? data) {
    final corretores = [...v.corretores];
    corretores[indice] = corretores[indice].marcarPaga(data);
    return _vendas.salvar(v.copyWith(corretores: corretores));
  }
}
