import '../../../../core/config/empresa_info.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../contratos/domain/entities/modelo_contrato.dart';
import '../../../contratos/domain/usecases/modelo_usecases.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/repositories/contato_repository.dart';
import '../../../crm/domain/repositories/imovel_repository.dart';
import '../entities/documentos_venda.dart';
import '../entities/parcela.dart';
import '../entities/venda.dart';
import '../entities/venda_enums.dart';
import '../repositories/documentos_venda_gateway.dart';
import 'montar_contrato_venda.dart';

class ImprimirContratoVenda {
  const ImprimirContratoVenda(
    this._imprimir,
    this._contatos,
    this._imoveis, [
    this._montar = const MontarContratoVenda(),
  ]);
  final ImprimirContratoDocumento _imprimir;
  final ContatoRepository _contatos;
  final ImovelRepository _imoveis;
  final MontarContratoVenda _montar;

  Future<void> call(Venda venda, ModeloContrato modelo) async {
    final contatos = await _contatos.listar();
    await _imprimir(
      _montar(
        modelo: modelo,
        venda: venda,
        contato: (id) => contatos.where((c) => c.id == id).firstOrNull,
        imovel: await _imoveis.obter(venda.imovelId),
      ),
    );
  }
}

/// Monta os dados de carnê/promissórias com as parcelas em aberto.
class _MontarParcelas {
  const _MontarParcelas(this._contatos, this._imoveis);
  final ContatoRepository _contatos;
  final ImovelRepository _imoveis;

  Future<ParcelasDocumento> call(Venda v, List<Parcela> parcelas) async {
    final abertas =
        parcelas
            .where((p) => p.vendaId == v.id && p.status == StatusParcela.aberta)
            .toList()
          ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
    if (abertas.isEmpty) {
      throw const DomainException('Não há parcelas em aberto nesta venda.');
    }
    final contatos = await _contatos.listar();
    Contato? c(String? id) => contatos.where((x) => x.id == id).firstOrNull;
    final vendedores = [for (final p in v.vendedores) ?c(p.contatoId)];
    return ParcelasDocumento(
      venda: v,
      compradores: [for (final id in v.compradores) ?c(id)],
      credor: v.credor == CredorParcelas.imobiliaria
          ? _imobiliaria()
          : Credor(
              nome: vendedores.map((x) => x.nome).join(' e '),
              documento: vendedores
                  .map((x) => x.documento)
                  .where((d) => d.isNotEmpty)
                  .join(' / '),
            ),
      imovel: await _imoveis.obter(v.imovelId),
      parcelas: abertas,
    );
  }
}

class ImprimirCarne {
  ImprimirCarne(this._gateway, ContatoRepository c, ImovelRepository i)
    : _montar = _MontarParcelas(c, i);
  final DocumentosVendaGateway _gateway;
  final _MontarParcelas _montar;

  Future<void> call(Venda v, List<Parcela> parcelas) async =>
      _gateway.imprimirCarne(await _montar(v, parcelas));
}

class ImprimirPromissorias {
  ImprimirPromissorias(this._gateway, ContatoRepository c, ImovelRepository i)
    : _montar = _MontarParcelas(c, i);
  final DocumentosVendaGateway _gateway;
  final _MontarParcelas _montar;

  Future<void> call(Venda v, List<Parcela> parcelas) async =>
      _gateway.imprimirPromissorias(await _montar(v, parcelas));
}

class ImprimirReciboComissao {
  const ImprimirReciboComissao(this._gateway, this._contatos, this._imoveis);
  final DocumentosVendaGateway _gateway;
  final ContatoRepository _contatos;
  final ImovelRepository _imoveis;

  Future<void> call(Venda v, int indice) async {
    if (v.comissaoPercentual <= 0) {
      throw const DomainException('Esta venda não tem comissão.');
    }
    final p = v.corretores[indice];
    final contatos = await _contatos.listar();
    Contato? c(String? id) => contatos.where((x) => x.id == id).firstOrNull;
    final corretor = c(p.contatoId);
    await _gateway.imprimirReciboComissao(
      ReciboComissaoDocumento(
        venda: v,
        imovel: await _imoveis.obter(v.imovelId),
        recebedor: p.contatoId == null
            ? _imobiliaria()
            : Credor(
                nome: corretor?.nome ?? '',
                documento: corretor?.documento ?? '',
              ),
        pagadores: [for (final x in v.vendedores) ?c(x.contatoId)],
        percentualParticipacao: p.percentual,
        valor: arredondar(v.valorComissao * p.percentual / 100),
        data: p.pagaEm ?? DateTime.now(),
      ),
    );
  }
}

/// A imobiliária como credora/recebedora: CNPJ/CPF da Personalização ou,
/// sem ele, o CRECI.
Credor _imobiliaria() {
  final e = EmpresaInfo.atual;
  return Credor(
    nome: e.nome,
    documento: e.documento.isNotEmpty ? e.documento : e.creci,
  );
}
