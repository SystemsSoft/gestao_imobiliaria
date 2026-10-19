enum TipoAuditoria {
  periodica('Periódica'),
  entrada('Entrada do inquilino'),
  saida('Saída do inquilino'),
  extraordinaria('Extraordinária');

  const TipoAuditoria(this.label);
  final String label;
}

enum StatusAuditoria {
  agendada('Agendada'),
  emAndamento('Em andamento'),
  concluida('Concluída'),
  cancelada('Cancelada');

  const StatusAuditoria(this.label);
  final String label;

  /// Os que podem ser escolhidos no formulário (concluir é uma ação).
  static const editaveis = [agendada, emAndamento, cancelada];
}

enum EstadoItem {
  pendente('Não avaliado'),
  ok('OK'),
  atencao('Atenção'),
  problema('Problema'),
  naoAplica('Não se aplica');

  const EstadoItem(this.label);
  final String label;
}

enum TipoMidia { foto, video }

enum StatusTranscricao {
  naoSolicitada('Não transcrito'),
  pendente('Na fila'),
  processando('Transcrevendo...'),
  concluida('Transcrito'),
  erro('Erro na transcrição');

  const StatusTranscricao(this.label);
  final String label;

  bool get emAndamento => this == pendente || this == processando;
}

enum Gravidade {
  critica('Crítica'),
  atencao('Atenção'),
  info('Informativa');

  const Gravidade(this.label);
  final String label;
}

enum AreaPendencia {
  financeiro('Financeiro'),
  contrato('Contrato'),
  imovel('Imóvel'),
  documentos('Documentos'),
  cadastro('Cadastro');

  const AreaPendencia(this.label);
  final String label;
}

class ItemAuditoria {
  const ItemAuditoria({
    required this.id,
    required this.area,
    required this.item,
    this.estado = EstadoItem.pendente,
    this.observacao = '',
    this.manutencaoId,
  });

  final String id;
  final String area;
  final String item;
  final EstadoItem estado;
  final String observacao;

  /// Pauta de manutenção gerada a partir do item (quando "Problema").
  final String? manutencaoId;

  ItemAuditoria copyWith({EstadoItem? estado, String? observacao}) =>
      ItemAuditoria(
        id: id,
        area: area,
        item: item,
        estado: estado ?? this.estado,
        observacao: observacao ?? this.observacao,
        manutencaoId: manutencaoId,
      );
}

/// Foto ou vídeo da auditoria; o vídeo pode ser transcrito no servidor.
class MidiaAuditoria {
  const MidiaAuditoria({
    required this.id,
    required this.referencia,
    required this.tipo,
    required this.criadoEm,
    this.titulo = '',
    this.itemId,
    this.transcricaoStatus = StatusTranscricao.naoSolicitada,
    this.transcricaoTexto = '',
    this.transcricaoErro = '',
    this.transcricaoEm,
  });

  final String id;

  /// `arquivo:<id>` (abre com link temporário do servidor).
  final String referencia;
  final TipoMidia tipo;
  final String titulo;
  final String? itemId;
  final StatusTranscricao transcricaoStatus;

  /// O que foi dito no vídeo (vai para o relatório).
  final String transcricaoTexto;
  final String transcricaoErro;
  final DateTime? transcricaoEm;
  final DateTime criadoEm;

  bool get video => tipo == TipoMidia.video;
}

class Auditoria {
  const Auditoria({
    required this.id,
    required this.imovelId,
    this.numero = '',
    this.contratoId,
    this.proprietarioId,
    this.corretorId,
    this.tipo = TipoAuditoria.periodica,
    this.status = StatusAuditoria.agendada,
    this.dataAgendada,
    this.dataRealizada,
    this.nota,
    this.resumo = '',
    this.recomendacoes = '',
    this.publicada = false,
    this.concluidaEm,
    this.itens = const [],
    this.midias = const [],
    this.criadoEm,
  });

  final String id;

  /// AUD-0001 (dado pelo servidor; vazio enquanto não salva).
  final String numero;
  final String imovelId;
  final String? contratoId;
  final String? proprietarioId;
  final String? corretorId;
  final TipoAuditoria tipo;
  final StatusAuditoria status;
  final DateTime? dataAgendada;
  final DateTime? dataRealizada;

  /// Conservação de 1 a 5.
  final int? nota;
  final String resumo;
  final String recomendacoes;

  /// Visível na Área do proprietário do site.
  final bool publicada;
  final DateTime? concluidaEm;
  final List<ItemAuditoria> itens;
  final List<MidiaAuditoria> midias;
  final DateTime? criadoEm;

  bool get nova => numero.isEmpty;
  bool get concluida => status == StatusAuditoria.concluida;

  int contar(EstadoItem e) => itens.where((i) => i.estado == e).length;

  /// Problemas que ainda não viraram manutenção.
  int get problemasSemManutencao => itens
      .where((i) => i.estado == EstadoItem.problema && i.manutencaoId == null)
      .length;

  /// Data para listas: a realizada ou a agendada.
  DateTime? get data => dataRealizada ?? dataAgendada;

  Auditoria copyWith({
    String? imovelId,
    String? Function()? contratoId,
    String? Function()? corretorId,
    TipoAuditoria? tipo,
    StatusAuditoria? status,
    DateTime? Function()? dataAgendada,
    DateTime? Function()? dataRealizada,
    int? Function()? nota,
    String? resumo,
    String? recomendacoes,
    List<ItemAuditoria>? itens,
  }) => Auditoria(
    id: id,
    numero: numero,
    imovelId: imovelId ?? this.imovelId,
    contratoId: contratoId != null ? contratoId() : this.contratoId,
    proprietarioId: proprietarioId,
    corretorId: corretorId != null ? corretorId() : this.corretorId,
    tipo: tipo ?? this.tipo,
    status: status ?? this.status,
    dataAgendada: dataAgendada != null ? dataAgendada() : this.dataAgendada,
    dataRealizada: dataRealizada != null ? dataRealizada() : this.dataRealizada,
    nota: nota != null ? nota() : this.nota,
    resumo: resumo ?? this.resumo,
    recomendacoes: recomendacoes ?? this.recomendacoes,
    publicada: publicada,
    concluidaEm: concluidaEm,
    itens: itens ?? this.itens,
    midias: midias,
    criadoEm: criadoEm,
  );
}

/// Item de um modelo de checklist.
typedef ItemModelo = ({String area, String item});

class ModeloChecklist {
  const ModeloChecklist({
    required this.id,
    required this.nome,
    required this.itens,
    this.padrao = false,
  });

  final String id;
  final String nome;
  final List<ItemModelo> itens;

  /// Usado nas novas auditorias.
  final bool padrao;
}

/// Prazos das pendências automáticas.
class ConfiguracaoAuditoria {
  const ConfiguracaoAuditoria({
    this.prazoRepasseDias = 5,
    this.atrasoCriticoDias = 30,
    this.chamadoSemRespostaHoras = 48,
    this.manutencaoParadaDias = 30,
    this.mesesSemAuditoria = 12,
    this.avisoVencimentoContratoDias = 60,
  });

  final int prazoRepasseDias;
  final int atrasoCriticoDias;
  final int chamadoSemRespostaHoras;
  final int manutencaoParadaDias;
  final int mesesSemAuditoria;
  final int avisoVencimentoContratoDias;
}

/// Achado da auditoria automática (calculado pelo servidor na hora).
class Pendencia {
  const Pendencia({
    required this.id,
    required this.gravidade,
    required this.area,
    required this.titulo,
    this.detalhe = '',
    this.contratoId,
    this.imovelId,
    this.proprietarioId,
  });

  final String id;
  final Gravidade gravidade;
  final AreaPendencia area;
  final String titulo;
  final String detalhe;
  final String? contratoId;
  final String? imovelId;
  final String? proprietarioId;
}

enum Saude {
  verde('Em dia'),
  amarelo('Atenção'),
  vermelho('Crítico');

  const Saude(this.label);
  final String label;
}

/// Login do proprietário na Área do proprietário do site.
class AcessoProprietario {
  const AcessoProprietario({
    this.ativo = true,
    this.trocarSenha = true,
    this.bloqueado = false,
    this.ultimoAcesso,
  });

  final bool ativo;
  final bool trocarSenha;
  final bool bloqueado;
  final DateTime? ultimoAcesso;
}

/// Visão do proprietário: carteira, situação e acesso ao portal.
class ResumoProprietario {
  const ResumoProprietario({
    required this.contatoId,
    required this.nome,
    this.documento = '',
    this.imoveis = 0,
    this.contratosAtivos = 0,
    this.aluguelMensal = 0,
    this.emAtraso = 0,
    this.criticas = 0,
    this.atencoes = 0,
    this.ultimaAuditoria,
    this.saude = Saude.verde,
    this.acesso,
  });

  final String contatoId;
  final String nome;
  final String documento;
  final int imoveis;
  final int contratosAtivos;
  final double aluguelMensal;
  final double emAtraso;
  final int criticas;
  final int atencoes;
  final DateTime? ultimaAuditoria;
  final Saude saude;
  final AcessoProprietario? acesso;
}
