import '../../../../core/presentation/view_model.dart';
import '../../../contratos/domain/entities/modelo_contrato.dart';
import '../../../contratos/domain/usecases/modelo_usecases.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/parcela.dart';
import '../../domain/entities/venda.dart';
import '../../domain/entities/venda_enums.dart';
import '../../domain/usecases/imprimir_documentos_venda.dart';
import '../../domain/usecases/parcela_usecases.dart';
import '../../domain/usecases/venda_usecases.dart';

class VendasViewModel extends ViewModel {
  VendasViewModel(
    ObservarVendas observarVendas,
    ObservarParcelas observarParcelas,
    ObservarContatos observarContatos,
    ObservarImoveis observarImoveis,
    ObservarModelos observarModelos,
    this._remover,
    this._imprimir,
  ) {
    observar(observarVendas(), (l) {
      _vendas = l;
      carregado = true;
    });
    observar(observarParcelas(), (l) => _parcelas = l);
    observar(observarContatos(), (l) => _contatos = l);
    observar(observarImoveis(), (l) => _imoveis = l);
    observar(observarModelos(TipoModelo.venda), (l) => modelos = l);
  }

  final RemoverVenda _remover;
  final ImprimirContratoVenda _imprimir;

  List<Venda> _vendas = const [];
  List<Parcela> _parcelas = const [];
  List<Contato> _contatos = const [];
  List<Imovel> _imoveis = const [];
  List<ModeloContrato> modelos = const [];
  bool carregado = false;
  String query = '';
  StatusVenda? status;

  bool get semCadastro => _vendas.isEmpty;

  String nomes(Iterable<String?> ids) => ids
      .map((id) => _contatos.where((c) => c.id == id).firstOrNull?.nome ?? '—')
      .join(', ');

  Imovel? imovel(String id) => _imoveis.where((i) => i.id == id).firstOrNull;

  ResumoFinanciamento resumo(Venda v) =>
      ResumoFinanciamento(_parcelas.where((p) => p.vendaId == v.id).toList());

  List<Venda> get filtradas {
    final q = query.trim().toLowerCase();
    return _vendas.where((v) {
      if (status != null && v.status != status) return false;
      if (q.isEmpty) return true;
      return [
        v.numero,
        nomes(v.compradores),
        imovel(v.imovelId)?.titulo ?? '',
      ].any((e) => e.toLowerCase().contains(q));
    }).toList()..sort((a, b) => b.numero.compareTo(a.numero));
  }

  void buscar(String t) {
    query = t;
    notificar();
  }

  void filtrarStatus(StatusVenda? s) {
    status = s;
    notificar();
  }

  Future<bool> remover(String id) => executar(() => _remover(id));

  Future<bool> imprimir(Venda v, ModeloContrato m) =>
      executar(() => _imprimir(v, m));
}
