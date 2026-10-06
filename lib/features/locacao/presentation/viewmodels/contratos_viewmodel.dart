import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/locacao_enums.dart';
import '../../../contratos/domain/entities/modelo_contrato.dart';
import '../../domain/usecases/contrato_usecases.dart';
import '../../domain/usecases/imprimir_documentos.dart';
import '../../../contratos/domain/usecases/modelo_usecases.dart';

class ContratosViewModel extends ViewModel {
  ContratosViewModel(
    ObservarContratos observarContratos,
    ObservarContatos observarContatos,
    ObservarImoveis observarImoveis,
    ObservarModelos observarModelos,
    this._remover,
    this._imprimir,
  ) {
    observar(observarContratos(), (l) {
      _contratos = l;
      carregado = true;
    });
    observar(observarContatos(), (l) => _contatos = l);
    observar(observarImoveis(), (l) => _imoveis = l);
    observar(observarModelos(TipoModelo.locacao), (l) => modelos = l);
  }

  final RemoverContrato _remover;
  final ImprimirContrato _imprimir;

  List<ContratoLocacao> _contratos = const [];
  List<Contato> _contatos = const [];
  List<Imovel> _imoveis = const [];
  List<ModeloContrato> modelos = const [];
  bool carregado = false;
  String query = '';
  StatusContrato? status;

  bool get semCadastro => _contratos.isEmpty;

  String nomeContato(String? id) => contatoPorId(_contatos, id)?.nome ?? '—';

  Imovel? imovel(String id) => _imoveis.where((i) => i.id == id).firstOrNull;

  List<ContratoLocacao> get filtrados {
    final q = query.trim().toLowerCase();
    return _contratos.where((c) {
      if (status != null && c.status != status) return false;
      if (q.isEmpty) return true;
      return [
        c.numero,
        nomeContato(c.locatarioId),
        imovel(c.imovelId)?.titulo ?? '',
        imovel(c.imovelId)?.enderecoResumo ?? '',
      ].any((e) => e.toLowerCase().contains(q));
    }).toList()..sort((a, b) => b.numero.compareTo(a.numero));
  }

  void buscar(String texto) {
    query = texto;
    notificar();
  }

  void filtrarStatus(StatusContrato? s) {
    status = s;
    notificar();
  }

  Future<bool> remover(String id) => executar(() => _remover(id));

  Future<bool> imprimir(ContratoLocacao c, ModeloContrato m) =>
      executar(() => _imprimir(c, m));
}
