import '../../../../core/arquivos/arquivo_repository.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/presentation/view_model.dart';
import '../../../../core/utils/id.dart';
import '../../domain/entities/documento.dart';
import '../../domain/usecases/documento_usecases.dart';

/// Gerenciador de documentos: pastas e os PDFs, Words e Excels de cada uma.
class DocumentosViewModel extends ViewModel {
  DocumentosViewModel(
    this._listarPastas,
    this._salvarPasta,
    this._removerPasta,
    this._listarDocumentos,
    this._enviar,
    this._salvar,
    this._substituir,
    this._remover,
    this._endereco,
    this._listarDestinatarios,
    this._compartilhar,
    this._duplicar,
  ) {
    carregar();
  }

  final ListarPastas _listarPastas;
  final SalvarPasta _salvarPasta;
  final RemoverPasta _removerPasta;
  final ListarDocumentos _listarDocumentos;
  final EnviarDocumento _enviar;
  final SalvarDocumento _salvar;
  final SubstituirArquivoDocumento _substituir;
  final RemoverDocumento _remover;
  final EnderecoDocumento _endereco;
  final ListarDestinatarios _listarDestinatarios;
  final CompartilharPasta _compartilhar;
  final DuplicarDocumento _duplicar;

  /// Inquilinos e proprietários, carregados ao abrir o compartilhamento.
  List<Destinatario> destinatarios = const [];

  List<PastaDocumento> pastas = const [];
  List<Documento> _documentos = const [];
  String? pastaId;
  bool carregado = false;
  bool carregandoDocumentos = false;
  String _busca = '';

  PastaDocumento? get pasta => pastas.where((p) => p.id == pastaId).firstOrNull;

  List<Documento> get documentos {
    final b = _busca.toLowerCase();
    if (b.isEmpty) return _documentos;
    return _documentos
        .where(
          (d) =>
              d.nome.toLowerCase().contains(b) ||
              d.arquivoNome.toLowerCase().contains(b),
        )
        .toList();
  }

  Future<void> carregar() async {
    try {
      pastas = await _listarPastas();
      if (pasta == null) pastaId = null;
      if (pastaId != null) await _carregarDocumentos();
    } on DomainException catch (e) {
      erro = e.mensagem;
    }
    carregado = true;
    notificar();
  }

  Future<void> _carregarDocumentos() async {
    final id = pastaId;
    if (id == null) return;
    carregandoDocumentos = true;
    notificar();
    try {
      final lista = await _listarDocumentos(id);
      if (id == pastaId) _documentos = lista;
    } finally {
      carregandoDocumentos = false;
      notificar();
    }
  }

  Future<void> abrirPasta(String? id) async {
    pastaId = id;
    _documentos = const [];
    _busca = '';
    notificar();
    if (id != null) await executar(_carregarDocumentos);
  }

  void buscar(String texto) {
    _busca = texto.trim();
    notificar();
  }

  Future<bool> salvarPasta(String nome, {String? id}) => executar(() async {
    final p = await _salvarPasta(id ?? gerarId(), nome);
    pastas = await _listarPastas();
    if (id == null) await abrirPasta(p.id);
  });

  Future<bool> carregarDestinatarios() =>
      executar(() async => destinatarios = await _listarDestinatarios());

  Future<bool> compartilhar(String pastaId, Set<String> contatoIds) =>
      executar(() async {
        await _compartilhar(pastaId, contatoIds);
        pastas = await _listarPastas();
      });

  /// Nomes de quem vê a pasta (na ordem da lista de destinatários).
  List<Destinatario> compartilhadaCom(PastaDocumento p) => [
    for (final d in destinatarios)
      if (p.compartilhadaCom.contains(d.id)) d,
  ];

  Future<bool> removerPasta(String id) => executar(() async {
    await _removerPasta(id);
    if (pastaId == id) {
      pastaId = null;
      _documentos = const [];
    }
    pastas = await _listarPastas();
  });

  /// Envia os arquivos para a pasta aberta. Os que falham são contados em
  /// [erro] sem impedir os demais.
  Future<int> enviar(List<ArquivoEscolhido> arquivos) async {
    final id = pastaId;
    if (id == null || arquivos.isEmpty) return 0;
    var enviados = 0;
    final falhas = <String>[];
    await executar(() async {
      for (final a in arquivos) {
        try {
          validarArquivoDocumento(a.nome, a.tamanho);
          await _enviar(id, a.nome, await a.ler());
          enviados++;
        } on DomainException catch (e) {
          falhas.add(e.mensagem);
        }
      }
      await _atualizar();
    });
    if (falhas.isNotEmpty) {
      erro = falhas.join('\n');
      notificar();
    }
    return enviados;
  }

  Future<bool> renomear(Documento d, String nome) => executar(() async {
    await _salvar(d, nome: nome);
    await _atualizar();
  });

  Future<bool> mover(Documento d, String pastaDestino) => executar(() async {
    await _salvar(d, pastaId: pastaDestino);
    await _atualizar();
  });

  /// Nome da última cópia criada (para avisar a tela).
  String? ultimaCopia;

  Future<bool> duplicar(Documento d) => executar(() async {
    ultimaCopia = (await _duplicar(d)).nome;
    await _atualizar();
  });

  Future<bool> substituir(Documento d, ArquivoEscolhido a) =>
      executar(() async {
        validarArquivoDocumento(a.nome, a.tamanho);
        await _substituir(d, a.nome, await a.ler());
        await _atualizar();
      });

  Future<bool> remover(Documento d) => executar(() async {
    await _remover(d.id);
    await _atualizar();
  });

  Future<Uri?> endereco(Documento d) => _endereco(d);

  /// Recarrega a pasta aberta e as contagens das pastas.
  Future<void> _atualizar() async {
    pastas = await _listarPastas();
    await _carregarDocumentos();
  }
}
