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
  });

  final String id;
  final String nome;

  /// Quantidade de documentos na pasta.
  final int documentos;
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
