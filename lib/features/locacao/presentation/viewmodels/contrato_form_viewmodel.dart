import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/usecases/contrato_usecases.dart';

class ContratoFormViewModel extends ViewModel {
  ContratoFormViewModel(
    this._listarContatos,
    this._listarImoveis,
    this._salvar,
  ) {
    _carregar();
  }

  final ListarContatos _listarContatos;
  final ListarImoveis _listarImoveis;
  final SalvarContrato _salvar;

  List<Contato> contatos = const [];
  List<Imovel> imoveis = const [];
  bool carregado = false;

  Future<void> _carregar() async {
    contatos = await _listarContatos();
    // Imóveis para locação primeiro.
    imoveis = [...await _listarImoveis()]
      ..sort((a, b) {
        int peso(Imovel i) =>
            i.finalidades.contains(Finalidade.locacao) ? 0 : 1;
        return peso(a).compareTo(peso(b));
      });
    carregado = true;
    notificar();
  }

  Imovel? imovel(String? id) => imoveis.where((i) => i.id == id).firstOrNull;

  /// Sugestões ao escolher o imóvel: valor do aluguel e proprietário como
  /// beneficiário de 100%.
  ({double? aluguel, List<Beneficiario> beneficiarios}) sugestoesDoImovel(
    String imovelId,
  ) {
    final i = imovel(imovelId);
    return (
      aluguel: i?.valorLocacao,
      beneficiarios: [
        if (i?.proprietarioId != null)
          Beneficiario(contatoId: i!.proprietarioId!, percentual: 100),
      ],
    );
  }

  Future<bool> salvar(ContratoLocacao c) => executar(() => _salvar(c));
}
