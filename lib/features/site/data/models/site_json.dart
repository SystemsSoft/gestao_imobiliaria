import '../../../../core/api/json.dart';
import '../../domain/entities/configuracao_site.dart';
import '../../domain/entities/lead_site.dart';

Map<String, Object?> configuracaoSiteParaJson(ConfiguracaoSite c) => {
  'noAr': c.noAr,
  'titulo': c.titulo,
  'subtitulo': c.subtitulo,
  'textoSobre': c.textoSobre,
  'chamadaAnuncie': c.chamadaAnuncie,
  'mensagemObrigado': c.mensagemObrigado,
  'whatsapp': c.whatsapp,
  'telefone': c.telefone,
  'email': c.email,
  'endereco': c.endereco,
  'horario': c.horario,
  'instagram': c.instagram,
  'facebook': c.facebook,
  'mostrarBusca': c.mostrarBusca,
  'mostrarDestaques': c.mostrarDestaques,
  'mostrarSobre': c.mostrarSobre,
  'mostrarContato': c.mostrarContato,
  'mostrarAnuncie': c.mostrarAnuncie,
  'permitirAgendarVisita': c.permitirAgendarVisita,
  'botaoWhatsapp': c.botaoWhatsapp,
  'mostrarValores': c.mostrarValores,
  'distribuirNaFila': c.distribuirNaFila,
  'criarTarefa': c.criarTarefa,
  'metaDescricao': c.metaDescricao,
};

ConfiguracaoSite configuracaoSiteDeJson(Map<String, dynamic> j) {
  const p = ConfiguracaoSite();
  String t(String k, String padrao) => (j[k] as String?) ?? padrao;
  bool b(String k, bool padrao) => (j[k] as bool?) ?? padrao;
  return ConfiguracaoSite(
    noAr: b('noAr', p.noAr),
    titulo: t('titulo', p.titulo),
    subtitulo: t('subtitulo', p.subtitulo),
    textoSobre: t('textoSobre', p.textoSobre),
    chamadaAnuncie: t('chamadaAnuncie', p.chamadaAnuncie),
    mensagemObrigado: t('mensagemObrigado', p.mensagemObrigado),
    whatsapp: t('whatsapp', ''),
    telefone: t('telefone', ''),
    email: t('email', ''),
    endereco: t('endereco', ''),
    horario: t('horario', p.horario),
    instagram: t('instagram', ''),
    facebook: t('facebook', ''),
    mostrarBusca: b('mostrarBusca', true),
    mostrarDestaques: b('mostrarDestaques', true),
    mostrarSobre: b('mostrarSobre', true),
    mostrarContato: b('mostrarContato', true),
    mostrarAnuncie: b('mostrarAnuncie', true),
    permitirAgendarVisita: b('permitirAgendarVisita', true),
    botaoWhatsapp: b('botaoWhatsapp', true),
    mostrarValores: b('mostrarValores', true),
    distribuirNaFila: b('distribuirNaFila', true),
    criarTarefa: b('criarTarefa', true),
    metaDescricao: t('metaDescricao', ''),
  );
}

/// Só o que a equipe altera; os dados do cliente vêm do site.
Map<String, Object?> leadParaJson(LeadSite l) => {
  'status': l.status.name,
  'corretorId': l.corretorId,
  'observacao': l.observacao,
};

LeadSite leadDeJson(Map<String, dynamic> j) => LeadSite(
  id: j['id'] as String,
  tipo: lerEnum(TipoLead.values, j['tipo'], TipoLead.contato),
  status: lerEnum(StatusLead.values, j['status'], StatusLead.novo),
  nome: lerTexto(j['nome']),
  email: lerTexto(j['email']),
  telefone: lerTexto(j['telefone']),
  mensagem: lerTexto(j['mensagem']),
  dataVisita: lerData(j['dataVisita']),
  imovelId: j['imovelId'] as String?,
  contatoId: j['contatoId'] as String?,
  corretorId: j['corretorId'] as String?,
  observacao: lerTexto(j['observacao']),
  criadoEm: lerData(j['criadoEm'])!,
);
