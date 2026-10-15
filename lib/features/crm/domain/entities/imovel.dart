import 'enums.dart';

class Anexo {
  const Anexo({required this.tipo, required this.titulo, required this.url});

  final AnexoTipo tipo;
  final String titulo;
  final String url;
}

/// Característica criada pelo usuário além das padrão (ex.: "Pé-direito": "4 m").
class CaracteristicaPersonalizada {
  const CaracteristicaPersonalizada({required this.nome, this.valor = ''});

  final String nome;
  final String valor;
}

class Imovel {
  Imovel({
    required this.id,
    required this.codigo,
    required this.titulo,
    this.finalidades = const {Finalidade.venda},
    this.tipo = TipoImovel.apartamento,
    this.status = StatusImovel.disponivel,
    this.proprietarioId,
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
    this.referencia = '',
    this.condominioNome = '',
    this.exibirEnderecoSite = true,
    this.valorVenda,
    this.valorLocacao,
    this.valorTemporada,
    this.valorCondominio,
    this.valorIptu,
    this.comissao,
    this.aceitaFinanciamento = false,
    this.aceitaPermuta = false,
    this.quartos = 0,
    this.suites = 0,
    this.banheiros = 0,
    this.vagas = 0,
    this.andar,
    this.anoConstrucao,
    this.areaUtil,
    this.areaTotal,
    this.areaTerreno,
    this.mobiliado = Mobiliado.nao,
    this.comodidades = const {},
    this.personalizadas = const [],
    this.descricao = '',
    this.observacoesInternas = '',
    this.captador = '',
    this.dataCaptacao,
    this.matricula = '',
    this.inscricaoMunicipal = '',
    this.localChaves = '',
    this.exclusividade = false,
    this.anexos = const [],
    this.criadoEm,
  });

  final String id;
  final String codigo;
  final String titulo;
  final Set<Finalidade> finalidades;
  final TipoImovel tipo;
  final StatusImovel status;
  final String? proprietarioId;

  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String referencia;
  final String condominioNome;
  final bool exibirEnderecoSite;

  final double? valorVenda;
  final double? valorLocacao;
  final double? valorTemporada;
  final double? valorCondominio;
  final double? valorIptu;
  final double? comissao;
  final bool aceitaFinanciamento;
  final bool aceitaPermuta;

  final int quartos;
  final int suites;
  final int banheiros;
  final int vagas;
  final int? andar;
  final int? anoConstrucao;
  final double? areaUtil;
  final double? areaTotal;
  final double? areaTerreno;
  final Mobiliado mobiliado;

  final Set<String> comodidades;
  final List<CaracteristicaPersonalizada> personalizadas;

  final String descricao;
  final String observacoesInternas;

  final String captador;
  final DateTime? dataCaptacao;
  final String matricula;
  final String inscricaoMunicipal;
  final String localChaves;
  final bool exclusividade;

  final List<Anexo> anexos;

  /// Data do cadastro no sistema.
  final DateTime? criadoEm;

  Imovel copyWith({
    String? codigo,
    DateTime? criadoEm,
    bool semProprietario = false,
  }) => Imovel(
    id: id,
    codigo: codigo ?? this.codigo,
    titulo: titulo,
    finalidades: finalidades,
    tipo: tipo,
    status: status,
    proprietarioId: semProprietario ? null : proprietarioId,
    cep: cep,
    logradouro: logradouro,
    numero: numero,
    complemento: complemento,
    bairro: bairro,
    cidade: cidade,
    uf: uf,
    referencia: referencia,
    condominioNome: condominioNome,
    exibirEnderecoSite: exibirEnderecoSite,
    valorVenda: valorVenda,
    valorLocacao: valorLocacao,
    valorTemporada: valorTemporada,
    valorCondominio: valorCondominio,
    valorIptu: valorIptu,
    comissao: comissao,
    aceitaFinanciamento: aceitaFinanciamento,
    aceitaPermuta: aceitaPermuta,
    quartos: quartos,
    suites: suites,
    banheiros: banheiros,
    vagas: vagas,
    andar: andar,
    anoConstrucao: anoConstrucao,
    areaUtil: areaUtil,
    areaTotal: areaTotal,
    areaTerreno: areaTerreno,
    mobiliado: mobiliado,
    comodidades: comodidades,
    personalizadas: personalizadas,
    descricao: descricao,
    observacoesInternas: observacoesInternas,
    captador: captador,
    dataCaptacao: dataCaptacao,
    matricula: matricula,
    inscricaoMunicipal: inscricaoMunicipal,
    localChaves: localChaves,
    exclusividade: exclusividade,
    anexos: anexos,
    criadoEm: criadoEm ?? this.criadoEm,
  );

  /// Cópia sem o vínculo com o proprietário (contato excluído).
  Imovel semProprietario() => copyWith(semProprietario: true);

  double? valorPara(Finalidade f) => switch (f) {
    Finalidade.venda => valorVenda,
    Finalidade.locacao => valorLocacao,
    Finalidade.temporada => valorTemporada,
  };

  String get enderecoResumo {
    final rua = [logradouro, numero].where((e) => e.isNotEmpty).join(', ');
    final cidadeUf = [cidade, uf].where((e) => e.isNotEmpty).join(' - ');
    return [rua, bairro, cidadeUf].where((e) => e.isNotEmpty).join(' • ');
  }

  String? get primeiraFoto {
    for (final a in anexos) {
      if (a.tipo == AnexoTipo.foto) return a.url;
    }
    return null;
  }
}
