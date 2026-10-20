/// Formatos aceitos no gerenciador de documentos: PDF, Word e Excel.
const extensoesDocumento = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];

/// Tamanho máximo de cada arquivo (o mesmo do servidor).
const maximoMbDocumento = 30;

/// Pasta do gerenciador de documentos (boletos, relatórios e outros).
class PastaDocumento {
  const PastaDocumento({
    required this.id,
    required this.nome,
    this.documentos = 0,
    this.compartilhadaCom = const [],
  });

  final String id;
  final String nome;

  /// Quantidade de documentos na pasta.
  final int documentos;

  /// Inquilinos e proprietários (ids dos contatos) que veem a pasta na
  /// área deles do portal.
  final List<String> compartilhadaCom;
}

/// Inquilino ou proprietário que pode receber uma pasta.
class Destinatario {
  const Destinatario({
    required this.id,
    required this.nome,
    this.documento = '',
    this.inquilino = false,
    this.proprietario = false,
    this.acessoInquilino = false,
    this.acessoProprietario = false,
  });

  final String id;
  final String nome;
  final String documento;
  final bool inquilino;
  final bool proprietario;

  /// Tem login ativo na área do portal (sem ele, não vê a pasta).
  final bool acessoInquilino;
  final bool acessoProprietario;

  bool get temAcesso => acessoInquilino || acessoProprietario;
}

enum TipoDocumento { pdf, word, excel }

/// Documento guardado numa pasta. [nome] é o título exibido e pode ser
/// trocado sem mexer no arquivo.
class Documento {
  const Documento({
    required this.id,
    required this.pastaId,
    required this.nome,
    required this.arquivoId,
    required this.arquivoNome,
    required this.tamanho,
    required this.atualizadoEm,
  });

  final String id;
  final String pastaId;
  final String nome;
  final String arquivoId;

  /// Nome do arquivo enviado (com a extensão).
  final String arquivoNome;
  final int tamanho;
  final DateTime atualizadoEm;

  String get extensao => arquivoNome.contains('.')
      ? arquivoNome.split('.').last.toLowerCase()
      : '';

  TipoDocumento get tipo => switch (extensao) {
    'doc' || 'docx' => TipoDocumento.word,
    'xls' || 'xlsx' => TipoDocumento.excel,
    _ => TipoDocumento.pdf,
  };
}
