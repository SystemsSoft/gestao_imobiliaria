import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/manutencao.dart';
import '../../domain/usecases/manutencao_usecases.dart';

class ManutencoesViewModel extends ViewModel {
  ManutencoesViewModel(
    this.contexto,
    ObservarManutencoes observarManutencoes,
    ObservarImoveis observarImoveis,
    this._salvar,
    this._remover,
    this._registrar,
    this._removerRegistro,
    this._alterarStatus,
    this._imprimirDiario, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    observar(observarManutencoes(contexto), (l) {
      _manutencoes = l;
      carregado = true;
    });
    observar(observarImoveis(), (l) => _imoveis = l);
  }

  final ContextoManutencao contexto;
  final SalvarManutencao _salvar;
  final RemoverManutencao _remover;
  final RegistrarDiario _registrar;
  final RemoverRegistroDiario _removerRegistro;
  final AlterarStatusManutencao _alterarStatus;
  final ImprimirDiarioManutencao _imprimirDiario;
  final DateTime Function() _agora;

  List<Manutencao> _manutencoes = const [];
  List<Imovel> _imoveis = const [];
  bool carregado = false;

  String? imovelId;
  StatusManutencao? status;
  TipoManutencao? tipo;

  DateTime get hoje => _agora();

  /// Imóveis com a finalidade do módulo (ou todos, se nenhum tiver).
  List<Imovel> get imoveis {
    final alvo = contexto == ContextoManutencao.venda
        ? {Finalidade.venda}
        : {Finalidade.locacao, Finalidade.temporada};
    final doModulo = _imoveis
        .where((i) => i.finalidades.any(alvo.contains))
        .toList();
    return doModulo.isEmpty ? _imoveis : doModulo;
  }

  bool get semImoveis => _imoveis.isEmpty;

  String descricaoImovel(String id) {
    final i = _imoveis.where((i) => i.id == id).firstOrNull;
    if (i == null) return 'Imóvel removido';
    return i.codigo.isEmpty ? i.titulo : '${i.codigo} • ${i.titulo}';
  }

  Manutencao? porId(String id) =>
      _manutencoes.where((m) => m.id == id).firstOrNull;

  int quantidade(StatusManutencao s) =>
      _manutencoes.where((m) => m.status == s).length;

  double get totalGasto => _manutencoes.fold(0, (s, m) => s + m.total);

  List<Manutencao> get filtradas {
    final ordem = StatusManutencao.values;
    return _manutencoes
        .where(
          (m) =>
              (imovelId == null || m.imovelId == imovelId) &&
              (status == null || m.status == status) &&
              (tipo == null || m.tipo == tipo),
        )
        .toList()
      ..sort((a, b) {
        final s = ordem.indexOf(a.status).compareTo(ordem.indexOf(b.status));
        if (s != 0) return s;
        final pa = a.dataPrevista ?? a.criadaEm;
        final pb = b.dataPrevista ?? b.criadaEm;
        return pa.compareTo(pb);
      });
  }

  void filtrarImovel(String? id) {
    imovelId = id;
    notificar();
  }

  void filtrarStatus(StatusManutencao? s) {
    status = s;
    notificar();
  }

  void filtrarTipo(TipoManutencao? t) {
    tipo = t;
    notificar();
  }

  Future<bool> salvar(Manutencao m) => executar(() => _salvar(m));
  Future<bool> remover(String id) => executar(() => _remover(id));
  Future<bool> registrar(String id, RegistroDiario r) =>
      executar(() => _registrar(id, r));
  Future<bool> removerRegistro(String id, String registroId) =>
      executar(() => _removerRegistro(id, registroId));
  Future<bool> imprimirDiario(String id) => executar(() => _imprimirDiario(id));
  Future<bool> alterarStatus(String id, StatusManutencao s) =>
      executar(() => _alterarStatus(id, s));
}
