/// Módulo em que a manutenção foi aberta.
enum ContextoManutencao {
  locacao('Locação'),
  venda('Venda');

  const ContextoManutencao(this.label);
  final String label;
}

enum TipoManutencao {
  eletrica('Elétrica'),
  alvenaria('Alvenaria'),
  pintura('Pintura'),
  acabamento('Acabamento'),
  outros('Outros');

  const TipoManutencao(this.label);
  final String label;
}

enum StatusManutencao {
  pendente('Pendente'),
  emAndamento('Em andamento'),
  concluida('Concluída');

  const StatusManutencao(this.label);
  final String label;
}

/// Lançamento do diário de uma manutenção: quem fez, o quê e quanto custou.
class RegistroDiario {
  const RegistroDiario({
    required this.id,
    required this.data,
    required this.profissional,
    required this.servico,
    this.material = '',
    this.valorMaterial = 0,
    this.valorMaoDeObra = 0,
    this.valorTaxa = 0,
  });

  final String id;
  final DateTime data;
  final String profissional;

  /// Serviço a ser executado.
  final String servico;

  /// Descrição dos materiais usados.
  final String material;
  final double valorMaterial;
  final double valorMaoDeObra;

  /// Taxa de manutenção cobrada pela imobiliária (valor fixo em R$).
  final double valorTaxa;

  /// Valor total dos serviços (material + mão de obra).
  double get valorServicos => valorMaterial + valorMaoDeObra;

  double get valorTotal => valorServicos + valorTaxa;
}

/// Item da pauta de manutenção de um imóvel, com o seu diário.
class Manutencao {
  const Manutencao({
    required this.id,
    required this.contexto,
    required this.imovelId,
    required this.tipo,
    required this.descricao,
    required this.criadaEm,
    this.tipoOutro = '',
    this.status = StatusManutencao.pendente,
    this.dataPrevista,
    this.diario = const [],
  });

  final String id;
  final ContextoManutencao contexto;
  final String imovelId;
  final TipoManutencao tipo;

  /// Qual o tipo quando [tipo] é "Outros".
  final String tipoOutro;
  final String descricao;
  final StatusManutencao status;
  final DateTime? dataPrevista;
  final DateTime criadaEm;
  final List<RegistroDiario> diario;

  String get tipoLabel =>
      tipo == TipoManutencao.outros && tipoOutro.trim().isNotEmpty
      ? tipoOutro.trim()
      : tipo.label;

  double get totalServicos => diario.fold(0, (s, r) => s + r.valorServicos);
  double get totalTaxas => diario.fold(0, (s, r) => s + r.valorTaxa);
  double get total => totalServicos + totalTaxas;

  /// Diário do lançamento mais recente para o mais antigo.
  List<RegistroDiario> get diarioOrdenado =>
      [...diario]..sort((a, b) => b.data.compareTo(a.data));

  bool atrasadaEm(DateTime hoje) {
    final p = dataPrevista;
    return p != null &&
        status != StatusManutencao.concluida &&
        DateTime(
          p.year,
          p.month,
          p.day,
        ).isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  Manutencao copyWith({
    StatusManutencao? status,
    List<RegistroDiario>? diario,
  }) => Manutencao(
    id: id,
    contexto: contexto,
    imovelId: imovelId,
    tipo: tipo,
    tipoOutro: tipoOutro,
    descricao: descricao,
    criadaEm: criadaEm,
    dataPrevista: dataPrevista,
    status: status ?? this.status,
    diario: diario ?? this.diario,
  );
}
