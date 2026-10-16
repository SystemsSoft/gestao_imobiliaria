import '../entities/configuracao_site.dart';
import '../entities/lead_site.dart';

abstract interface class SiteRepository {
  Future<ConfiguracaoSite> obterConfiguracao();
  Future<ConfiguracaoSite> salvarConfiguracao(ConfiguracaoSite configuracao);

  /// Mais recentes primeiro; atualiza sozinho quando chegam leads novos.
  Stream<List<LeadSite>> observarLeads();
  Future<void> salvarLead(LeadSite lead);
  Future<void> removerLead(String id);

  /// Endereço público do site.
  String get endereco;
}
