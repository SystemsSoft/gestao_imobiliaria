import 'enums.dart';

/// Item da Central de Relacionamento: anotação, lembrete, recado, visita etc.
class Evento {
  Evento({
    required this.id,
    required this.titulo,
    required this.criadoEm,
    this.tipo = TipoEvento.lembrete,
    this.descricao = '',
    this.dataHora,
    this.prioridade = Prioridade.normal,
    this.contatoId,
    this.imovelId,
    this.concluido = false,
  });

  final String id;
  final String titulo;
  final DateTime criadoEm;
  final TipoEvento tipo;
  final String descricao;
  final DateTime? dataHora;
  final Prioridade prioridade;
  final String? contatoId;
  final String? imovelId;
  final bool concluido;

  Evento copyWith({
    bool? concluido,
    bool semContato = false,
    bool semImovel = false,
  }) => Evento(
    id: id,
    titulo: titulo,
    criadoEm: criadoEm,
    tipo: tipo,
    descricao: descricao,
    dataHora: dataHora,
    prioridade: prioridade,
    contatoId: semContato ? null : contatoId,
    imovelId: semImovel ? null : imovelId,
    concluido: concluido ?? this.concluido,
  );
}
