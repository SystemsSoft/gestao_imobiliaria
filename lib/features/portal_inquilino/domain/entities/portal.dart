/// Login do locatário na Área do inquilino do site.
class AcessoInquilino {
  const AcessoInquilino({
    required this.contatoId,
    required this.login,
    required this.criadoEm,
    this.ativo = true,
    this.trocarSenha = true,
    this.bloqueado = false,
    this.ultimoAcesso,
  });

  final String contatoId;

  /// CPF/CNPJ só com números.
  final String login;
  final bool ativo;

  /// Ainda está com a senha provisória.
  final bool trocarSenha;

  /// Bloqueado por tentativas de senha (libera sozinho em minutos).
  final bool bloqueado;
  final DateTime? ultimoAcesso;
  final DateTime criadoEm;
}

/// Senha provisória gerada pelo servidor: mostrada uma única vez.
class SenhaProvisoria {
  const SenhaProvisoria({required this.login, required this.senha});
  final String login;
  final String senha;
}

enum TipoArquivoContrato {
  contrato('Contrato de locação'),
  vistoria('Laudo de vistoria'),
  documento('Documento'),
  estadoImovel('Estado do imóvel'),
  chamado('Anexo de chamado');

  const TipoArquivoContrato(this.label);
  final String label;

  /// Os que a imobiliária publica (os demais vêm do inquilino).
  static const daImobiliaria = [contrato, vistoria, documento];
}

enum OrigemArquivo { imobiliaria, inquilino }

/// Documento ou mídia ligado ao contrato.
class ArquivoContrato {
  const ArquivoContrato({
    required this.id,
    required this.contratoId,
    required this.tipo,
    required this.titulo,
    required this.referencia,
    required this.criadoEm,
    this.origem = OrigemArquivo.imobiliaria,
    this.manutencaoId,
    this.observacao = '',
    this.visivelInquilino = true,
  });

  final String id;
  final String contratoId;
  final String? manutencaoId;
  final TipoArquivoContrato tipo;
  final OrigemArquivo origem;
  final String titulo;
  final String observacao;

  /// `arquivo:<id>` (abre com link temporário do servidor).
  final String referencia;
  final bool visivelInquilino;
  final DateTime criadoEm;

  bool get doInquilino => origem == OrigemArquivo.inquilino;

  ArquivoContrato comVisibilidade(bool visivel) => ArquivoContrato(
    id: id,
    contratoId: contratoId,
    manutencaoId: manutencaoId,
    tipo: tipo,
    origem: origem,
    titulo: titulo,
    observacao: observacao,
    referencia: referencia,
    visivelInquilino: visivel,
    criadoEm: criadoEm,
  );
}

/// Aviso da imobiliária no portal (sem contrato = todos os inquilinos).
class ComunicadoInquilino {
  const ComunicadoInquilino({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.criadoEm,
    this.contratoId,
    this.automatico = false,
    this.leituras = 0,
  });

  final String id;
  final String? contratoId;
  final String titulo;
  final String mensagem;

  /// Gerado pelo sistema (novo documento, andamento de chamado).
  final bool automatico;
  final DateTime criadoEm;

  /// Quantos inquilinos já leram.
  final int leituras;
}
