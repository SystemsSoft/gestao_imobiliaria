import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../../../crm/domain/repositories/contato_repository.dart';
import '../entities/boleto_bancario.dart';
import '../entities/financeiro_enums.dart';
import '../entities/lancamento.dart';
import '../repositories/boleto_impressao_gateway.dart';
import '../repositories/financeiro_repositories.dart';
import 'lancamento_usecases.dart';

class ObservarBoletos {
  const ObservarBoletos(this._repo);
  final BoletoRepository _repo;

  Stream<List<BoletoBancario>> call() => _repo.observar();
}

/// Emite o boleto de uma conta a receber em aberto.
class EmitirBoleto {
  const EmitirBoleto(this._boletos, this._contas);
  final BoletoRepository _boletos;
  final ContaBancariaRepository _contas;

  Future<BoletoBancario> call(Lancamento l, String contaId) async {
    if (l.tipo != TipoLancamento.receber) {
      throw const DomainException('Só contas a receber geram boleto.');
    }
    if (!l.emAberto) throw const DomainException('A conta não está em aberto.');
    if (await _contas.obter(contaId) == null) {
      throw const DomainException('Selecione a conta bancária.');
    }
    final existente = (await _boletos.listar()).any(
      (b) => b.lancamentoId == l.id && b.status == StatusBoleto.emitido,
    );
    if (existente) {
      throw const DomainException(
        'Já existe um boleto em aberto para esta conta.',
      );
    }
    final boleto = BoletoBancario(
      id: gerarId(),
      lancamentoId: l.id,
      contaId: contaId,
      nossoNumero: '', // atribuído por quem grava (servidor ou memória)
      valor: l.valor,
      vencimento: l.vencimento,
      emissao: DateTime.now(),
    );
    return _boletos.salvar(boleto);
  }
}

class CancelarBoleto {
  const CancelarBoleto(this._repo);
  final BoletoRepository _repo;

  Future<void> call(BoletoBancario b) {
    if (b.status != StatusBoleto.emitido) {
      throw const DomainException('Só boletos emitidos podem ser cancelados.');
    }
    return _repo.salvar(b.copyWith(status: StatusBoleto.cancelado));
  }
}

/// Lê o texto de retorno: uma linha por pagamento, no formato
/// `nossoNumero;valor;dd/mm/aaaa`.
({List<RetornoItem> itens, List<String> invalidas}) interpretarRetorno(
  String texto,
) {
  final itens = <RetornoItem>[];
  final invalidas = <String>[];
  for (final bruta in texto.split('\n')) {
    final linha = bruta.trim();
    if (linha.isEmpty) continue;
    final p = linha.split(';').map((e) => e.trim()).toList();
    final valor = p.length > 1
        ? double.tryParse(p[1].replaceAll('.', '').replaceAll(',', '.'))
        : null;
    final d = p.length > 2
        ? RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(p[2])
        : null;
    if (p.isEmpty || p[0].isEmpty || valor == null || valor <= 0 || d == null) {
      invalidas.add(linha);
      continue;
    }
    itens.add(
      RetornoItem(
        nossoNumero: p[0],
        valorPago: valor,
        dataPagamento: DateTime(
          int.parse(d.group(3)!),
          int.parse(d.group(2)!),
          int.parse(d.group(1)!),
        ),
      ),
    );
  }
  return (itens: itens, invalidas: invalidas);
}

/// Baixa automática: cada pagamento do retorno marca o boleto como pago e dá
/// baixa na conta a receber, na conta bancária do boleto.
class ProcessarRetornoBancario {
  const ProcessarRetornoBancario(
    this._boletos,
    this._lancamentos,
    this._baixar,
  );
  final BoletoRepository _boletos;
  final LancamentoRepository _lancamentos;
  final BaixarLancamento _baixar;

  Future<ResultadoRetorno> call(String texto) async {
    final lido = interpretarRetorno(texto);
    final boletos = await _boletos.listar();
    var baixados = 0;
    final naoEncontrados = <String>[];
    final ignorados = <String>[];

    for (final item in lido.itens) {
      final b = boletos
          .where((x) => x.nossoNumero == item.nossoNumero)
          .firstOrNull;
      if (b == null) {
        naoEncontrados.add(item.nossoNumero);
        continue;
      }
      final l = await _lancamentos.obter(b.lancamentoId);
      if (b.status != StatusBoleto.emitido || l == null || !l.emAberto) {
        ignorados.add(item.nossoNumero);
        continue;
      }
      await _baixar(
        l,
        item.dataPagamento,
        valorBaixa: item.valorPago,
        meio: MeioPagamento.boleto,
        contaId: b.contaId,
      );
      await _boletos.salvar(
        b.copyWith(
          status: StatusBoleto.pago,
          dataPagamento: item.dataPagamento,
          valorPago: item.valorPago,
        ),
      );
      baixados++;
    }
    return ResultadoRetorno(
      baixados: baixados,
      naoEncontrados: naoEncontrados,
      ignorados: ignorados,
      linhasInvalidas: lido.invalidas,
    );
  }
}

class ImprimirBoletoBancario {
  const ImprimirBoletoBancario(
    this._gateway,
    this._lancamentos,
    this._contas,
    this._contatos,
  );
  final BoletoImpressaoGateway _gateway;
  final LancamentoRepository _lancamentos;
  final ContaBancariaRepository _contas;
  final ContatoRepository _contatos;

  Future<void> call(BoletoBancario b) async {
    final l = await _lancamentos.obter(b.lancamentoId);
    final conta = await _contas.obter(b.contaId);
    if (l == null || conta == null) {
      throw const DomainException('Dados do boleto não encontrados.');
    }
    await _gateway.imprimirBoleto(
      BoletoDocumento(
        boleto: b,
        lancamento: l,
        conta: conta,
        pagador: l.contatoId == null
            ? null
            : await _contatos.obter(l.contatoId!),
      ),
    );
  }
}
