import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../../equipe/domain/entities/equipe_enums.dart';
import '../../../equipe/domain/entities/usuario_sistema.dart';
import '../../../equipe/domain/usecases/usuario_usecases.dart';
import '../../domain/entities/configuracao_site.dart';
import '../../domain/entities/lead_site.dart';
import '../../domain/usecases/site_usecases.dart';

/// Caixa de leads do site.
class LeadsViewModel extends ViewModel {
  LeadsViewModel(
    ObservarLeads observarLeads,
    ObservarImoveis observarImoveis,
    ObservarUsuarios observarUsuarios,
    this._atualizar,
    this._remover,
  ) {
    observar(observarLeads(), (l) {
      _leads = l;
      carregado = true;
    });
    observar(observarImoveis(), (l) => _imoveis = {for (final i in l) i.id: i});
    observar(observarUsuarios(), (l) => _usuarios = l);
  }

  final AtualizarLead _atualizar;
  final RemoverLead _remover;

  List<LeadSite> _leads = const [];
  Map<String, Imovel> _imoveis = const {};
  List<UsuarioSistema> _usuarios = const [];
  bool carregado = false;
  StatusLead? status;
  String _busca = '';

  int contar(StatusLead s) => _leads.where((l) => l.status == s).length;
  int get novos => contar(StatusLead.novo);
  bool get semLeads => _leads.isEmpty;

  List<LeadSite> get filtrados {
    final q = _busca.toLowerCase();
    return _leads.where((l) {
      if (status != null && l.status != status) return false;
      if (q.isEmpty) return true;
      final i = imovel(l.imovelId);
      return [
        l.nome,
        l.email,
        l.telefone,
        l.mensagem,
        i?.codigo ?? '',
        i?.titulo ?? '',
      ].any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  Imovel? imovel(String? id) => id == null ? null : _imoveis[id];

  UsuarioSistema? usuario(String? id) =>
      _usuarios.where((u) => u.id == id).firstOrNull;

  /// Quem pode receber o lead: usuários ativos (corretores primeiro).
  List<UsuarioSistema> get responsaveis =>
      _usuarios.where((u) => u.ativo).toList()..sort(
        (a, b) => (a.perfil == PerfilAcesso.corretor ? 0 : 1).compareTo(
          b.perfil == PerfilAcesso.corretor ? 0 : 1,
        ),
      );

  void filtrar(StatusLead? s) {
    status = s;
    notificar();
  }

  void buscar(String q) {
    _busca = q.trim();
    notificar();
  }

  Future<bool> mudarStatus(LeadSite l, StatusLead s) =>
      executar(() => _atualizar(l.copyWith(status: s)));

  /// Encaminhar a alguém também tira o lead de "Novo".
  Future<bool> atribuir(LeadSite l, String? usuarioId) => executar(
    () => _atualizar(
      l.copyWith(
        corretorId: usuarioId,
        semCorretor: usuarioId == null,
        status: usuarioId != null && l.status == StatusLead.novo
            ? StatusLead.emAtendimento
            : null,
      ),
    ),
  );

  Future<bool> anotar(LeadSite l, String observacao) =>
      executar(() => _atualizar(l.copyWith(observacao: observacao.trim())));

  Future<bool> remover(String id) => executar(() => _remover(id));
}

enum FiltroPublicacao {
  publicados('No site'),
  naoPublicados('Fora do site'),
  destaques('Destaques');

  const FiltroPublicacao(this.label);
  final String label;
}

/// Quais imóveis aparecem no site e quais vão em destaque.
class ImoveisNoSiteViewModel extends ViewModel {
  ImoveisNoSiteViewModel(ObservarImoveis observarImoveis, this._publicar) {
    observar(observarImoveis(), (l) {
      _imoveis = [...l]..sort((a, b) => a.codigo.compareTo(b.codigo));
      carregado = true;
    });
  }

  final PublicarImovelNoSite _publicar;
  List<Imovel> _imoveis = const [];
  bool carregado = false;
  FiltroPublicacao? filtro;
  String _busca = '';

  int get publicados => _imoveis.where((i) => i.publicarSite).length;
  int get destaques => _imoveis.where((i) => i.destaqueSite).length;
  bool get semImoveis => _imoveis.isEmpty;

  List<Imovel> get filtrados {
    final q = _busca.toLowerCase();
    return _imoveis.where((i) {
      final passa = switch (filtro) {
        null => true,
        FiltroPublicacao.publicados => i.publicarSite,
        FiltroPublicacao.naoPublicados => !i.publicarSite,
        FiltroPublicacao.destaques => i.destaqueSite,
      };
      if (!passa) return false;
      return q.isEmpty ||
          [
            i.codigo,
            i.titulo,
            i.bairro,
            i.cidade,
          ].any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  void filtrar(FiltroPublicacao? f) {
    filtro = f;
    notificar();
  }

  void buscar(String q) {
    _busca = q.trim();
    notificar();
  }

  Future<bool> publicar(Imovel i, bool sim) =>
      executar(() => _publicar(i, publicar: sim));

  Future<bool> destacar(Imovel i, bool sim) =>
      executar(() => _publicar(i, destaque: sim));
}

/// Textos, contatos, funcionalidades e atendimento do site.
class ConfiguracaoSiteViewModel extends ViewModel {
  ConfiguracaoSiteViewModel(this._obter, this._salvar, this.enderecoSite) {
    _carregar();
  }

  final ObterConfiguracaoSite _obter;
  final SalvarConfiguracaoSite _salvar;
  final String enderecoSite;

  ConfiguracaoSite config = const ConfiguracaoSite();
  bool carregado = false;

  Future<void> _carregar() async {
    await executar(() async => config = await _obter());
    carregado = true;
    notificar();
  }

  Future<bool> salvar(ConfiguracaoSite c) =>
      executar(() async => config = await _salvar(c));
}
