import '../../../../core/errors/domain_exception.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/repositories/imovel_repository.dart';
import '../entities/configuracao_site.dart';
import '../entities/lead_site.dart';
import '../repositories/site_repository.dart';

class ObterConfiguracaoSite {
  const ObterConfiguracaoSite(this._repo);
  final SiteRepository _repo;

  Future<ConfiguracaoSite> call() => _repo.obterConfiguracao();
}

class SalvarConfiguracaoSite {
  const SalvarConfiguracaoSite(this._repo);
  final SiteRepository _repo;

  Future<ConfiguracaoSite> call(ConfiguracaoSite c) async {
    final whats = c.whatsapp.replaceAll(RegExp(r'\D'), '');
    if (whats.isNotEmpty && ![10, 11, 12, 13].contains(whats.length)) {
      throw const DomainException('WhatsApp inválido: informe DDD e número.');
    }
    for (final (rede, url) in [
      ('Instagram', c.instagram.trim()),
      ('Facebook', c.facebook.trim()),
    ]) {
      if (url.isNotEmpty && !url.startsWith('https://')) {
        throw DomainException('Link do $rede deve começar com https://');
      }
    }
    if (c.titulo.trim().isEmpty) {
      throw const DomainException('Informe o título da página inicial.');
    }
    return _repo.salvarConfiguracao(c.copyWith(whatsapp: whats));
  }
}

class ObservarLeads {
  const ObservarLeads(this._repo);
  final SiteRepository _repo;

  Stream<List<LeadSite>> call() => _repo.observarLeads();
}

class AtualizarLead {
  const AtualizarLead(this._repo);
  final SiteRepository _repo;

  Future<void> call(LeadSite lead) => _repo.salvarLead(lead);
}

class RemoverLead {
  const RemoverLead(this._repo);
  final SiteRepository _repo;

  Future<void> call(String id) => _repo.removerLead(id);
}

/// Liga/desliga a publicação de um imóvel no site e o destaque na home.
class PublicarImovelNoSite {
  const PublicarImovelNoSite(this._imoveis);
  final ImovelRepository _imoveis;

  Future<void> call(Imovel i, {bool? publicar, bool? destaque}) async {
    final publicado = publicar ?? i.publicarSite;
    if ((destaque ?? false) && !publicado) {
      throw const DomainException('Publique o imóvel antes de destacá-lo.');
    }
    await _imoveis.salvar(
      i.copyWith(
        publicarSite: publicado,
        destaqueSite: publicado && (destaque ?? i.destaqueSite),
      ),
    );
  }
}

/// Por que um imóvel publicado pode não aparecer (ou aparecer mal) no site.
List<String> pendenciasNoSite(Imovel i) => [
  if (i.status != StatusImovel.disponivel)
    'Status "${i.status.label}": só disponíveis aparecem',
  if (!i.anexos.any((a) => a.tipo == AnexoTipo.foto)) 'Sem fotos',
  if (i.descricao.trim().isEmpty) 'Sem descrição',
  if (i.valorVenda == null &&
      i.valorLocacao == null &&
      i.valorTemporada == null)
    'Sem valor',
];
