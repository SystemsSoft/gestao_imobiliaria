/// Login do internet banking (Sicoobnet).
const linkSicoobPadrao = 'https://ib.sicoob.com.br/sicoobnet/ib/#/login';

/// Configuração da integração (o token nunca volta do servidor).
class ConfiguracaoSicoob {
  const ConfiguracaoSicoob({
    this.ambiente = 'sandbox',
    this.clientId = '',
    this.numeroCliente = '',
    this.codigoModalidade = 1,
    this.numeroContaCorrente = '',
    this.chavePix = '',
    this.contaBancariaId,
    this.tokenConfigurado = false,
    this.linkInternetBanking = linkSicoobPadrao,
  });

  final String ambiente;
  final String clientId;

  /// Código do beneficiário (cooperado) na Cobrança Bancária.
  final String numeroCliente;
  final int codigoModalidade;
  final String numeroContaCorrente;
  final String chavePix;

  /// Conta do Financeiro que recebe o extrato importado.
  final String? contaBancariaId;
  final bool tokenConfigurado;

  /// Endereço aberto pelo botão "Abrir Sicoob" (o internet banking não pode
  /// ser embutido no sistema; abre em outra aba).
  final String linkInternetBanking;

  bool get sandbox => ambiente == 'sandbox';
}

class ResultadoTesteSicoob {
  const ResultadoTesteSicoob({
    required this.api,
    required this.nome,
    required this.ok,
    required this.mensagem,
    this.statusHttp,
  });

  final String api;
  final String nome;
  final bool ok;
  final int? statusHttp;
  final String mensagem;
}

class PagadorSicoob {
  const PagadorSicoob({
    required this.documento,
    required this.nome,
    this.endereco = '',
    this.bairro = '',
    this.cidade = '',
    this.cep = '',
    this.uf = '',
    this.email = '',
  });

  final String documento;
  final String nome;
  final String endereco;
  final String bairro;
  final String cidade;
  final String cep;
  final String uf;
  final String email;
}

class NovoBoletoSicoob {
  const NovoBoletoSicoob({
    required this.valor,
    required this.vencimento,
    required this.pagador,
    this.multaPercentual = 0,
    this.jurosMesPercentual = 0,
    this.mensagem = '',
    this.comPix = true,
    this.cobrancaId,
  });

  final double valor;
  final DateTime vencimento;
  final PagadorSicoob pagador;
  final double multaPercentual;
  final double jurosMesPercentual;
  final String mensagem;
  final bool comPix;
  final String? cobrancaId;
}

class BoletoSicoob {
  const BoletoSicoob({
    required this.id,
    required this.nossoNumero,
    required this.valor,
    required this.vencimento,
    required this.pagadorNome,
    required this.criadoEm,
    this.linhaDigitavel = '',
    this.codigoBarras = '',
    this.situacao = '',
    this.cobrancaId,
  });

  final String id;
  final String nossoNumero;
  final double valor;
  final DateTime vencimento;
  final String pagadorNome;
  final String linhaDigitavel;
  final String codigoBarras;
  final String situacao;
  final String? cobrancaId;
  final DateTime criadoEm;
}

class NovoPixSicoob {
  const NovoPixSicoob({
    required this.valor,
    this.devedorDocumento = '',
    this.devedorNome = '',
    this.descricao = '',
    this.expiracaoHoras = 24,
    this.cobrancaId,
  });

  final double valor;
  final String devedorDocumento;
  final String devedorNome;
  final String descricao;
  final int expiracaoHoras;
  final String? cobrancaId;
}

class PixSicoob {
  const PixSicoob({
    required this.id,
    required this.txid,
    required this.valor,
    required this.status,
    required this.criadoEm,
    this.devedorNome = '',
    this.descricao = '',
    this.copiaECola = '',
    this.qrCodePng = '',
  });

  final String id;
  final String txid;
  final double valor;
  final String devedorNome;
  final String descricao;
  final String status;
  final String copiaECola;

  /// QR code do copia e cola (data URI), quando o servidor envia.
  final String qrCodePng;
  final DateTime criadoEm;
}

class PixRecebido {
  const PixRecebido({
    required this.endToEndId,
    required this.valor,
    required this.horario,
    this.txid = '',
    this.pagador = '',
    this.info = '',
  });

  final String endToEndId;
  final String txid;
  final double valor;
  final String horario;
  final String pagador;
  final String info;
}

class SaldoSicoob {
  const SaldoSicoob({
    required this.saldo,
    required this.saldoLimite,
    required this.saldoBloqueado,
  });

  final double saldo;
  final double saldoLimite;
  final double saldoBloqueado;
}

class TransacaoSicoob {
  const TransacaoSicoob({
    required this.tipo,
    required this.valor,
    required this.data,
    required this.descricao,
    this.documento = '',
    this.complemento = '',
  });

  final String tipo;
  final double valor;
  final DateTime data;
  final String descricao;
  final String documento;
  final String complemento;

  bool get credito => tipo.toUpperCase().startsWith('C');
}

class ExtratoSicoob {
  const ExtratoSicoob({
    required this.saldoAnterior,
    required this.saldoAtual,
    required this.transacoes,
  });

  final double saldoAnterior;
  final double saldoAtual;
  final List<TransacaoSicoob> transacoes;
}

class ChamadaSicoob {
  const ChamadaSicoob({
    required this.id,
    required this.criadoEm,
    required this.api,
    required this.operacao,
    required this.metodo,
    required this.caminho,
    required this.sucesso,
    this.statusHttp,
    this.duracaoMs = 0,
    this.erro = '',
    this.requisicao = '',
    this.resposta = '',
  });

  final String id;
  final DateTime criadoEm;
  final String api;
  final String operacao;
  final String metodo;
  final String caminho;
  final int? statusHttp;
  final int duracaoMs;
  final bool sucesso;
  final String erro;
  final String requisicao;
  final String resposta;
}

/// Cobrança do aluguel em aberto (para preencher boleto ou Pix).
class CobrancaAbertaSicoob {
  const CobrancaAbertaSicoob({
    required this.id,
    required this.descricao,
    required this.locatario,
    required this.valor,
    required this.vencimento,
  });

  final String id;
  final String descricao;
  final String locatario;
  final double valor;
  final DateTime vencimento;
}

class RascunhoSicoob {
  const RascunhoSicoob({
    required this.valor,
    required this.vencimento,
    required this.pagador,
    required this.descricao,
    required this.multaPercentual,
    required this.jurosMesPercentual,
  });

  final double valor;
  final DateTime vencimento;
  final PagadorSicoob pagador;
  final String descricao;
  final double multaPercentual;
  final double jurosMesPercentual;
}

/// Situação de um título do arquivo de retorno: `baixar` (prévia),
/// `aplicada`, `ja_paga`, `divergente`, `sem_boleto`, `sem_cobranca` ou
/// `ignorado` (movimento sem pagamento).
class ItemRetornoSicoob {
  const ItemRetornoSicoob({
    required this.nossoNumero,
    required this.valorPago,
    required this.situacao,
    required this.mensagem,
    this.dataCredito,
    this.descricao = '',
    this.locatario = '',
  });

  final String nossoNumero;
  final double valorPago;
  final DateTime? dataCredito;
  final String situacao;
  final String mensagem;
  final String descricao;
  final String locatario;

  bool get daBaixa => situacao == 'baixar' || situacao == 'aplicada';
  bool get precisaAtencao =>
      situacao == 'divergente' || situacao == 'sem_boleto';
}

class ResultadoRetornoSicoob {
  const ResultadoRetornoSicoob({
    required this.aplicado,
    required this.baixas,
    required this.itens,
  });

  final bool aplicado;
  final int baixas;
  final List<ItemRetornoSicoob> itens;
}
