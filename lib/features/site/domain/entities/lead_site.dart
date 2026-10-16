enum TipoLead {
  interesse('Interesse em imóvel'),
  visita('Agendar visita'),
  contato('Fale conosco'),
  anunciar('Anunciar imóvel');

  const TipoLead(this.label);
  final String label;
}

enum StatusLead {
  novo('Novo'),
  emAtendimento('Em atendimento'),
  convertido('Convertido'),
  descartado('Descartado');

  const StatusLead(this.label);
  final String label;

  bool get aberto => this == novo || this == emAtendimento;
}

/// Pedido enviado pelo site. O servidor já criou (ou atualizou) o contato no
/// CRM, a tarefa na Central e, se configurado, o atendimento na fila.
class LeadSite {
  const LeadSite({
    required this.id,
    required this.tipo,
    required this.nome,
    required this.criadoEm,
    this.status = StatusLead.novo,
    this.email = '',
    this.telefone = '',
    this.mensagem = '',
    this.dataVisita,
    this.imovelId,
    this.contatoId,
    this.corretorId,
    this.observacao = '',
  });

  final String id;
  final TipoLead tipo;
  final StatusLead status;
  final String nome;
  final String email;
  final String telefone;
  final String mensagem;
  final DateTime? dataVisita;
  final String? imovelId;
  final String? contatoId;
  final String? corretorId;

  /// Anotação interna da equipe.
  final String observacao;
  final DateTime criadoEm;

  LeadSite copyWith({
    StatusLead? status,
    String? corretorId,
    bool semCorretor = false,
    String? observacao,
  }) => LeadSite(
    id: id,
    tipo: tipo,
    nome: nome,
    criadoEm: criadoEm,
    status: status ?? this.status,
    email: email,
    telefone: telefone,
    mensagem: mensagem,
    dataVisita: dataVisita,
    imovelId: imovelId,
    contatoId: contatoId,
    corretorId: semCorretor ? null : (corretorId ?? this.corretorId),
    observacao: observacao ?? this.observacao,
  );
}
