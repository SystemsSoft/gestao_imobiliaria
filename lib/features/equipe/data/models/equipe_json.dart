import '../../../../core/api/json.dart';
import '../../domain/entities/atividade.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/comissao_equipe.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/fila.dart';
import '../../domain/entities/permissoes.dart';
import '../../domain/entities/sessao.dart';
import '../../domain/entities/usuario_sistema.dart';

// ----------------------------------------------------------------- Usuário

Map<String, Object?> permissoesParaJson(Permissoes p) => {
  'modulos': {for (final e in p.modulos.entries) e.key.name: nomes(e.value)},
  'especiais': nomes(p.especiais),
};

Permissoes permissoesDeJson(Map<String, dynamic>? j) => Permissoes(
  modulos: {
    for (final e in ((j?['modulos'] as Map?) ?? const {}).entries)
      ?ModuloSistema.values.asNameMap()[e.key]: lerEnums(
        AcaoPermissao.values,
        e.value,
      ),
  },
  especiais: lerEnums(PermissaoEspecial.values, j?['especiais']),
);

Map<String, Object?> usuarioParaJson(UsuarioSistema u, {String? senha}) => {
  'nome': u.nome,
  'email': u.email,
  'perfil': u.perfil.name,
  'permissoes': permissoesParaJson(u.permissoes),
  'ativo': u.ativo,
  'telefone': u.telefone,
  'creci': u.creci,
  'atendeNaFila': u.atendeNaFila,
  'senha': ?senha,
};

UsuarioSistema usuarioDeJson(Map<String, dynamic> j) => UsuarioSistema(
  id: j['id'] as String,
  nome: lerTexto(j['nome']),
  email: lerTexto(j['email']),
  perfil: lerEnum(PerfilAcesso.values, j['perfil'], PerfilAcesso.atendente),
  permissoes: permissoesDeJson(j['permissoes'] as Map<String, dynamic>?),
  criadoEm: lerData(j['criadoEm']) ?? DateTime.now(),
  ativo: j['ativo'] as bool? ?? true,
  telefone: lerTexto(j['telefone']),
  creci: lerTexto(j['creci']),
  atendeNaFila: j['atendeNaFila'] as bool? ?? false,
);

// ------------------------------------------------- Sessão e configuração

SessaoUsuario sessaoDeJson(Map<String, dynamic> j) => SessaoUsuario(
  id: j['id'] as String,
  usuarioId: lerTexto(j['usuarioId']),
  inicio: lerData(j['inicio'])!,
  ultimaAtividade: lerData(j['ultimaAtividade'])!,
  dispositivo: lerTexto(j['dispositivo']),
);

Map<String, Object?> configuracaoParaJson(ConfiguracaoSeguranca c) => {
  'limiteSessoes': c.limiteSessoes,
  'inatividadeMinutos': c.inatividadeMinutos,
};

ConfiguracaoSeguranca configuracaoDeJson(Map<String, dynamic> j) =>
    ConfiguracaoSeguranca(
      limiteSessoes: lerInt(j['limiteSessoes'], 5),
      inatividadeMinutos: lerInt(j['inatividadeMinutos'], 30),
    );

// --------------------------------------------------------------- Atividade

Map<String, Object?> atividadeParaJson(Atividade a) => {
  'tipo': a.tipo.name,
  'descricao': a.descricao,
  'modulo': a.modulo?.name,
};

Atividade atividadeDeJson(Map<String, dynamic> j) => Atividade(
  id: j['id'] as String,
  usuarioId: lerTexto(j['usuarioId']),
  tipo: lerEnum(TipoAtividade.values, j['tipo'], TipoAtividade.edicao),
  descricao: lerTexto(j['descricao']),
  quando: lerData(j['quando'])!,
  modulo: ModuloSistema.values.asNameMap()[j['modulo']],
);

// ---------------------------------------------------- Fila e atendimento

Map<String, Object?> itemFilaParaJson(ItemFila i) => {
  'usuarioId': i.usuarioId,
  'status': i.status.name,
  'desde': escreverDataHora(i.desde),
};

ItemFila itemFilaDeJson(Map<String, dynamic> j) => ItemFila(
  usuarioId: lerTexto(j['usuarioId']),
  status: lerEnum(StatusFila.values, j['status'], StatusFila.disponivel),
  desde: lerData(j['desde'])!,
);

Map<String, Object?> atendimentoParaJson(Atendimento a) => {
  'corretorId': a.corretorId,
  'clienteNome': a.clienteNome,
  'origem': a.origem.name,
  'iniciadoEm': escreverDataHora(a.iniciadoEm),
  'contatoId': a.contatoId,
  'observacao': a.observacao,
  'finalizadoEm': escreverDataHora(a.finalizadoEm),
};

Atendimento atendimentoDeJson(Map<String, dynamic> j) => Atendimento(
  id: j['id'] as String,
  corretorId: lerTexto(j['corretorId']),
  clienteNome: lerTexto(j['clienteNome']),
  origem: lerEnum(
    OrigemAtendimento.values,
    j['origem'],
    OrigemAtendimento.plantao,
  ),
  iniciadoEm: lerData(j['iniciadoEm'])!,
  contatoId: j['contatoId'] as String?,
  observacao: lerTexto(j['observacao']),
  finalizadoEm: lerData(j['finalizadoEm']),
);

// --------------------------------------------------------------- Comissões

Map<String, Object?> regraParaJson(RegraComissao r) => {
  'percentualVenda': r.percentualVenda,
  'percentualLocacao': r.percentualLocacao,
  'percentualCaptacao': r.percentualCaptacao,
  'metaMensal': r.metaMensal,
};

RegraComissao regraDeJson(Map<String, dynamic> j) => RegraComissao(
  usuarioId: lerTexto(j['usuarioId']),
  percentualVenda: lerDouble(j['percentualVenda']) ?? 0,
  percentualLocacao: lerDouble(j['percentualLocacao']) ?? 0,
  percentualCaptacao: lerDouble(j['percentualCaptacao']) ?? 0,
  metaMensal: lerDouble(j['metaMensal']) ?? 0,
);

Map<String, Object?> comissaoParaJson(LancamentoComissao l) => {
  'usuarioId': l.usuarioId,
  'tipo': l.tipo.name,
  'competencia': escreverData(l.competencia),
  'valor': l.valor,
  'referencia': l.referencia,
  'baseValor': l.baseValor,
  'percentual': l.percentual,
  'observacao': l.observacao,
  'status': l.status.name,
  'dataPagamento': escreverData(l.dataPagamento),
};

LancamentoComissao comissaoDeJson(Map<String, dynamic> j) => LancamentoComissao(
  id: j['id'] as String,
  usuarioId: lerTexto(j['usuarioId']),
  tipo: lerEnum(TipoComissao.values, j['tipo'], TipoComissao.ajuste),
  competencia: lerData(j['competencia'])!,
  valor: lerDouble(j['valor']) ?? 0,
  referencia: lerTexto(j['referencia']),
  baseValor: lerDouble(j['baseValor']) ?? 0,
  percentual: lerDouble(j['percentual']) ?? 0,
  observacao: lerTexto(j['observacao']),
  status: lerEnum(StatusComissao.values, j['status'], StatusComissao.pendente),
  dataPagamento: lerData(j['dataPagamento']),
);

// ------------------------------------------------------------------- Chat

Map<String, Object?> mensagemParaJson(Mensagem m) => {
  'conversaId': m.conversaId,
  'remetenteId': m.remetenteId,
  'texto': m.texto,
  'enviadaEm': escreverDataHora(m.enviadaEm),
  'lidaPor': m.lidaPor.toList(),
};

Mensagem mensagemDeJson(Map<String, dynamic> j) => Mensagem(
  id: j['id'] as String,
  conversaId: lerTexto(j['conversaId']),
  remetenteId: lerTexto(j['remetenteId']),
  texto: lerTexto(j['texto']),
  enviadaEm: lerData(j['enviadaEm'])!,
  lidaPor: {...((j['lidaPor'] as List?) ?? const []).cast<String>()},
);
