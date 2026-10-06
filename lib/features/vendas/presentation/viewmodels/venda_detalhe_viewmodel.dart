import '../../../../core/domain/encargos.dart';
import '../../../../core/config/empresa_info.dart';
import '../../../../core/presentation/view_model.dart';
import '../../../contratos/domain/entities/modelo_contrato.dart';
import '../../../contratos/domain/usecases/modelo_usecases.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/parcela.dart';
import '../../domain/entities/venda.dart';
import '../../domain/usecases/imprimir_documentos_venda.dart';
import '../../domain/usecases/parcela_usecases.dart';
import '../../domain/usecases/venda_usecases.dart';

class VendaDetalheViewModel extends ViewModel {
  VendaDetalheViewModel(
    this.vendaId,
    ObservarVendas observarVendas,
    ObservarParcelas observarParcelas,
    ObservarContatos observarContatos,
    ObservarImoveis observarImoveis,
    ObservarModelos observarModelos,
    this._encargos,
    this._pagar,
    this._estornar,
    this._marcarComissao,
    this._contrato,
    this._carne,
    this._promissorias,
    this._reciboComissao,
  ) {
    observar(observarVendas(), (l) {
      venda = l.where((v) => v.id == vendaId).firstOrNull;
      carregado = true;
    });
    observar(observarParcelas(), (l) {
      parcelas = l.where((p) => p.vendaId == vendaId).toList()
        ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
    });
    observar(observarContatos(), (l) => _contatos = l);
    observar(observarImoveis(), (l) => _imoveis = l);
    observar(observarModelos(TipoModelo.venda), (l) => modelos = l);
  }

  final String vendaId;
  final CalcularEncargosParcela _encargos;
  final RegistrarPagamentoParcela _pagar;
  final EstornarPagamentoParcela _estornar;
  final MarcarComissaoPaga _marcarComissao;
  final ImprimirContratoVenda _contrato;
  final ImprimirCarne _carne;
  final ImprimirPromissorias _promissorias;
  final ImprimirReciboComissao _reciboComissao;

  Venda? venda;
  List<Parcela> parcelas = const [];
  List<Contato> _contatos = const [];
  List<Imovel> _imoveis = const [];
  List<ModeloContrato> modelos = const [];
  bool carregado = false;

  DateTime get hoje => DateTime.now();

  ResumoFinanciamento get resumo => ResumoFinanciamento(parcelas);

  Imovel? get imovel =>
      _imoveis.where((i) => i.id == venda?.imovelId).firstOrNull;

  String nome(String? id) => id == null
      ? '${EmpresaInfo.nome} (imobiliária)'
      : _contatos.where((c) => c.id == id).firstOrNull?.nome ?? '—';

  Encargos? simular(Parcela p, DateTime data) {
    final v = venda;
    return v == null ? null : _encargos(v, p, data);
  }

  Future<bool> pagar(Parcela p, DateTime data, double valor) =>
      executar(() => _pagar(p, data, valorPago: valor));
  Future<bool> estornar(Parcela p) => executar(() => _estornar(p));

  Future<bool> marcarComissao(int indice, bool paga) => executar(
    () => _marcarComissao(venda!, indice, paga ? DateTime.now() : null),
  );

  Future<bool> imprimirContrato(ModeloContrato m) =>
      executar(() => _contrato(venda!, m));
  Future<bool> imprimirCarne() => executar(() => _carne(venda!, parcelas));
  Future<bool> imprimirPromissorias() =>
      executar(() => _promissorias(venda!, parcelas));
  Future<bool> imprimirReciboComissao(int indice) =>
      executar(() => _reciboComissao(venda!, indice));
}
