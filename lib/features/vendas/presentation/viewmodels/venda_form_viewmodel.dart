import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/venda.dart';
import '../../domain/services/calculadora_financiamento.dart';
import '../../domain/usecases/venda_usecases.dart';

class VendaFormViewModel extends ViewModel {
  VendaFormViewModel(
    this._listarContatos,
    this._listarImoveis,
    this._salvar,
    this._simular,
  ) {
    _carregar();
  }

  final ListarContatos _listarContatos;
  final ListarImoveis _listarImoveis;
  final SalvarVenda _salvar;
  final SimularFinanciamento _simular;

  List<Contato> contatos = const [];
  List<Imovel> imoveis = const [];
  bool carregado = false;

  Future<void> _carregar() async {
    contatos = await _listarContatos();
    // Imóveis à venda primeiro.
    imoveis = [...await _listarImoveis()]
      ..sort((a, b) {
        int peso(Imovel i) => i.finalidades.contains(Finalidade.venda) ? 0 : 1;
        return peso(a).compareTo(peso(b));
      });
    carregado = true;
    notificar();
  }

  Imovel? imovel(String? id) => imoveis.where((i) => i.id == id).firstOrNull;

  String nome(String? id) =>
      contatos.where((c) => c.id == id).firstOrNull?.nome ?? '';

  /// Ao escolher o imóvel: preço anunciado e proprietário como vendedor.
  ({double? valor, String? vendedorId}) sugestoesDoImovel(String id) {
    final i = imovel(id);
    return (valor: i?.valorVenda, vendedorId: i?.proprietarioId);
  }

  List<ParcelaPlano> simular(
    double valorFinanciado,
    PlanoFinanciamento plano,
  ) => _simular(valorFinanciado, plano);

  Future<bool> salvar(Venda v) => executar(() => _salvar(v));
}
