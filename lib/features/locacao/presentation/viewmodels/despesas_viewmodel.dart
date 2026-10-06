import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/despesa.dart';
import '../../domain/entities/locacao_enums.dart';
import '../../domain/usecases/contrato_usecases.dart';
import '../../domain/usecases/despesa_usecases.dart';

class DespesasViewModel extends ViewModel {
  DespesasViewModel(
    ObservarDespesas observarDespesas,
    ObservarContratos observarContratos,
    ObservarImoveis observarImoveis,
    this._salvar,
    this._remover,
  ) {
    observar(observarDespesas(), (l) {
      _despesas = l;
      carregado = true;
    });
    observar(observarContratos(), (l) => contratos = l);
    observar(observarImoveis(), (l) => _imoveis = l);
  }

  final SalvarDespesa _salvar;
  final RemoverDespesa _remover;

  List<Despesa> _despesas = const [];
  List<ContratoLocacao> contratos = const [];
  List<Imovel> _imoveis = const [];
  bool carregado = false;
  String? contratoId;
  NaturezaDespesa? natureza;

  bool get semCadastro => _despesas.isEmpty;

  void filtrarContrato(String? id) {
    contratoId = id;
    notificar();
  }

  void filtrarNatureza(NaturezaDespesa? n) {
    natureza = n;
    notificar();
  }

  String descricaoContrato(String id) {
    final c = contratos.where((c) => c.id == id).firstOrNull;
    if (c == null) return '—';
    final i = _imoveis.where((i) => i.id == c.imovelId).firstOrNull;
    return '${c.numero}${i == null ? '' : ' • ${i.titulo}'}';
  }

  List<Despesa> get filtradas =>
      _despesas
          .where(
            (d) =>
                (contratoId == null || d.contratoId == contratoId) &&
                (natureza == null || d.natureza == natureza),
          )
          .toList()
        ..sort((a, b) => b.competenciaInicio.compareTo(a.competenciaInicio));

  Future<bool> salvar(Despesa d) => executar(() => _salvar(d));
  Future<bool> remover(String id) => executar(() => _remover(id));
}
