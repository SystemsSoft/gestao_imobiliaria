import '../../../../core/api/api_client.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/memory_collection.dart';
import '../../../../core/data/remote_collection.dart';
import '../../domain/entities/configuracao_site.dart';
import '../../domain/entities/lead_site.dart';
import '../../domain/repositories/site_repository.dart';
import '../models/site_json.dart';

List<LeadSite> _recentes(List<LeadSite> l) =>
    [...l]..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

/// Site no servidor (`/api/v1/site`). Os leads são consultados a cada 30 s
/// enquanto a tela está aberta; quando chegam novos, [aoChegarLead] avisa
/// para recarregar o CRM (o servidor criou contato, tarefa e atendimento).
class SiteApiRepository implements SiteRepository {
  SiteApiRepository(
    this._api,
    StatusConexao status, {
    required this.endereco,
    this.aoChegarLead,
  }) {
    _leads = RemoteCollection(
      idOf: (l) => l.id,
      status: status,
      intervalo: const Duration(seconds: 30),
      carregar: () async {
        final leads = [
          for (final j in await _api.listarTudo('site/leads')) leadDeJson(j),
        ];
        final ids = {for (final l in leads) l.id};
        if (_conhecidos != null && !ids.every(_conhecidos!.contains)) {
          aoChegarLead?.call();
        }
        _conhecidos = ids;
        return leads;
      },
    );
  }

  final ApiClient _api;
  late final RemoteCollection<LeadSite> _leads;
  Set<String>? _conhecidos;
  final void Function()? aoChegarLead;

  @override
  final String endereco;

  @override
  Future<ConfiguracaoSite> obterConfiguracao() async => configuracaoSiteDeJson(
    await _api.get('site/configuracao') as Map<String, dynamic>,
  );

  @override
  Future<ConfiguracaoSite> salvarConfiguracao(ConfiguracaoSite c) async =>
      configuracaoSiteDeJson(
        await _api.put('site/configuracao', configuracaoSiteParaJson(c))
            as Map<String, dynamic>,
      );

  @override
  Stream<List<LeadSite>> observarLeads() => _leads.watch().map(_recentes);

  @override
  Future<void> salvarLead(LeadSite lead) async {
    final json = await _api.put('site/leads/${lead.id}', leadParaJson(lead));
    _leads.cache.upsert(leadDeJson(json as Map<String, dynamic>));
  }

  @override
  Future<void> removerLead(String id) async {
    await _api.delete('site/leads/$id');
    _leads.cache.removeWhere((l) => l.id == id);
  }
}

/// Sem servidor (testes): configuração e leads em memória.
class SiteMemoryRepository implements SiteRepository {
  ConfiguracaoSite _config = const ConfiguracaoSite();
  final leads = MemoryCollection<LeadSite>((l) => l.id);

  @override
  String get endereco => 'http://localhost:8000';

  @override
  Future<ConfiguracaoSite> obterConfiguracao() async => _config;

  @override
  Future<ConfiguracaoSite> salvarConfiguracao(ConfiguracaoSite c) async =>
      _config = c;

  @override
  Stream<List<LeadSite>> observarLeads() => leads.watch().map(_recentes);

  @override
  Future<void> salvarLead(LeadSite lead) async => leads.upsert(lead);

  @override
  Future<void> removerLead(String id) async =>
      leads.removeWhere((l) => l.id == id);
}
