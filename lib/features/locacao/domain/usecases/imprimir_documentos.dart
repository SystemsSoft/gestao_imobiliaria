import '../../../../core/errors/domain_exception.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/repositories/contato_repository.dart';
import '../../../crm/domain/repositories/imovel_repository.dart';
import '../entities/cobranca.dart';
import '../entities/contrato_locacao.dart';
import '../entities/documentos.dart';
import '../entities/locacao_enums.dart';
import '../entities/modelo_contrato.dart';
import '../repositories/contrato_locacao_repository.dart';
import '../repositories/documentos_locacao_gateway.dart';
import 'modelo_usecases.dart';

class ImprimirContrato {
  const ImprimirContrato(
    this._gateway,
    this._contatos,
    this._imoveis, [
    this._preencher = const PreencherModeloContrato(),
  ]);
  final DocumentosLocacaoGateway _gateway;
  final ContatoRepository _contatos;
  final ImovelRepository _imoveis;
  final PreencherModeloContrato _preencher;

  Future<void> call(ContratoLocacao contrato, ModeloContrato modelo) async {
    final contatos = await _contatos.listar();
    final doc = _preencher(
      modelo: modelo,
      contrato: contrato,
      contato: (id) => contatos.where((c) => c.id == id).firstOrNull,
      imovel: await _imoveis.obter(contrato.imovelId),
    );
    await _gateway.imprimirContrato(doc);
  }
}

/// Monta os dados de boleto/recibo a partir da cobrança.
class _DadosCobranca {
  const _DadosCobranca(this._contratos, this._contatos, this._imoveis);
  final ContratoLocacaoRepository _contratos;
  final ContatoRepository _contatos;
  final ImovelRepository _imoveis;

  Future<CobrancaDocumento> call(Cobranca c) async {
    final contrato = await _contratos.obter(c.contratoId);
    if (contrato == null) {
      throw const DomainException('Contrato não encontrado.');
    }
    return CobrancaDocumento(
      cobranca: c,
      contrato: contrato,
      locatario: await _contatos.obter(contrato.locatarioId),
      imovel: await _imoveis.obter(contrato.imovelId),
    );
  }
}

class ImprimirBoleto {
  ImprimirBoleto(
    this._gateway,
    ContratoLocacaoRepository contratos,
    ContatoRepository contatos,
    ImovelRepository imoveis,
  ) : _dados = _DadosCobranca(contratos, contatos, imoveis);
  final DocumentosLocacaoGateway _gateway;
  final _DadosCobranca _dados;

  Future<void> call(Cobranca c) async {
    if (c.status == StatusCobranca.cancelada) {
      throw const DomainException('Cobrança cancelada.');
    }
    await _gateway.imprimirBoleto(await _dados(c));
  }
}

class ImprimirRecibo {
  ImprimirRecibo(
    this._gateway,
    ContratoLocacaoRepository contratos,
    ContatoRepository contatos,
    ImovelRepository imoveis,
  ) : _dados = _DadosCobranca(contratos, contatos, imoveis);
  final DocumentosLocacaoGateway _gateway;
  final _DadosCobranca _dados;

  Future<void> call(Cobranca c) async {
    if (c.status != StatusCobranca.paga) {
      throw const DomainException('O recibo só é emitido após o pagamento.');
    }
    await _gateway.imprimirRecibo(await _dados(c));
  }
}

class ImprimirDemonstrativoRepasse {
  const ImprimirDemonstrativoRepasse(this._gateway);
  final DocumentosLocacaoGateway _gateway;

  Future<void> call(DemonstrativoRepasse d) =>
      _gateway.imprimirDemonstrativo(d);
}

class ImprimirInformeRendimentos {
  const ImprimirInformeRendimentos(this._gateway);
  final DocumentosLocacaoGateway _gateway;

  Future<void> call(InformeRendimentos i) => _gateway.imprimirInforme(i);
}

/// Atalho usado pelos ViewModels para localizar contatos por id.
Contato? contatoPorId(List<Contato> contatos, String? id) =>
    contatos.where((c) => c.id == id).firstOrNull;
