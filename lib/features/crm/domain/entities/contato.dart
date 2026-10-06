import 'enums.dart';

/// O que o contato procura; usado no cruzamento com os imóveis cadastrados.
class PerfilInteresse {
  const PerfilInteresse({
    this.finalidade = Finalidade.venda,
    this.tipos = const {},
    this.cidade = '',
    this.bairros = '',
    this.valorMin,
    this.valorMax,
    this.quartosMin = 0,
    this.suitesMin = 0,
    this.vagasMin = 0,
    this.areaMin,
    this.comodidades = const {},
    this.observacoes = '',
  });

  final Finalidade finalidade;
  final Set<TipoImovel> tipos;
  final String cidade;

  /// Bairros separados por vírgula.
  final String bairros;
  final double? valorMin;
  final double? valorMax;
  final int quartosMin;
  final int suitesMin;
  final int vagasMin;
  final double? areaMin;
  final Set<String> comodidades;
  final String observacoes;

  List<String> get listaBairros => bairros
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

class Contato {
  Contato({
    required this.id,
    required this.nome,
    required this.criadoEm,
    this.tipoPessoa = TipoPessoa.fisica,
    this.papeis = const {PapelContato.lead},
    this.documento = '',
    this.rg = '',
    this.dataNascimento,
    this.estadoCivil,
    this.profissao = '',
    this.nacionalidade = 'Brasileira',
    this.telefone = '',
    this.celular = '',
    this.email = '',
    this.aceitaContato = true,
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
    this.origem = OrigemContato.site,
    this.etapa = EtapaFunil.novo,
    this.corretorResponsavel = '',
    this.rendaMensal,
    this.observacoes = '',
    this.banco = '',
    this.agencia = '',
    this.conta = '',
    this.pix = '',
    this.perfil,
  });

  final String id;
  final String nome;
  final DateTime criadoEm;
  final TipoPessoa tipoPessoa;
  final Set<PapelContato> papeis;
  final String documento;
  final String rg;
  final DateTime? dataNascimento;
  final String? estadoCivil;
  final String profissao;
  final String nacionalidade;

  final String telefone;
  final String celular;
  final String email;
  final bool aceitaContato;

  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;

  final OrigemContato origem;
  final EtapaFunil etapa;
  final String corretorResponsavel;
  final double? rendaMensal;
  final String observacoes;

  final String banco;
  final String agencia;
  final String conta;
  final String pix;

  final PerfilInteresse? perfil;
}
