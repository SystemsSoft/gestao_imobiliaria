import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/arquivos/escolher_arquivos.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/documento.dart';
import '../viewmodels/documentos_viewmodel.dart';

/// Gerenciador de documentos: pastas (boletos, relatórios e outros) com os
/// PDFs, Words e Excels baixados no computador e enviados ao sistema.
class DocumentosTab extends StatefulWidget {
  const DocumentosTab({super.key});

  @override
  State<DocumentosTab> createState() => _DocumentosTabState();
}

class _DocumentosTabState extends State<DocumentosTab> {
  final _vm = sl<DocumentosViewModel>();
  final _busca = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _acao(Future<bool> Function() f, [String? sucesso]) async {
    final ok = await f();
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível concluir.');
    } else if (sucesso != null) {
      mostrarMensagem(context, sucesso);
    }
  }

  // -------------------------------------------------------------- Pastas

  Future<void> _novaPasta() async {
    final nome = await _pedirNome(
      context,
      titulo: 'Nova pasta',
      rotulo: 'Nome da pasta',
      dica: 'Ex.: Boletos, Relatórios',
    );
    if (nome != null) await _acao(() => _vm.salvarPasta(nome), 'Pasta criada.');
  }

  Future<void> _renomearPasta(PastaDocumento p) async {
    final nome = await _pedirNome(
      context,
      titulo: 'Renomear pasta',
      rotulo: 'Nome da pasta',
      inicial: p.nome,
    );
    if (nome != null && nome != p.nome) {
      await _acao(() => _vm.salvarPasta(nome, id: p.id), 'Pasta renomeada.');
    }
  }

  Future<void> _excluirPasta(PastaDocumento p) async {
    final docs = switch (p.documentos) {
      0 => '',
      1 => ' e o documento dentro dela',
      final n => ' e os $n documentos dentro dela',
    };
    if (await confirmDelete(context, 'Excluir a pasta "${p.nome}"$docs?')) {
      await _acao(() => _vm.removerPasta(p.id), 'Pasta excluída.');
    }
  }

  Future<void> _abrirPasta(String? id) async {
    _busca.clear();
    await _vm.abrirPasta(id);
    if (_vm.erro != null && mounted) mostrarMensagem(context, _vm.erro!);
  }

  // ---------------------------------------------------------- Documentos

  Future<void> _enviar() async {
    final arquivos = await escolherArquivos(
      extensoes: extensoesDocumento,
      multiplos: true,
    );
    if (arquivos.isEmpty) return;
    final enviados = await _vm.enviar(arquivos);
    if (!mounted) return;
    final falhas = _vm.erro;
    mostrarMensagem(
      context,
      [
        if (enviados > 0)
          enviados == 1
              ? '1 documento enviado.'
              : '$enviados documentos enviados.',
        ?falhas,
      ].join('\n'),
    );
  }

  Future<void> _abrir(Documento d) async {
    final uri = await _vm.endereco(d);
    final ok = uri != null && await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!ok && mounted) {
      mostrarMensagem(context, 'Não foi possível abrir "${d.nome}".');
    }
  }

  Future<void> _renomear(Documento d) async {
    final nome = await _pedirNome(
      context,
      titulo: 'Renomear documento',
      rotulo: 'Nome do documento',
      inicial: d.nome,
    );
    if (nome != null && nome != d.nome) {
      await _acao(() => _vm.renomear(d, nome), 'Documento renomeado.');
    }
  }

  Future<void> _mover(Documento d) async {
    final outras = _vm.pastas.where((p) => p.id != d.pastaId).toList();
    if (outras.isEmpty) {
      mostrarMensagem(context, 'Crie outra pasta para mover o documento.');
      return;
    }
    final destino = await showDialog<PastaDocumento>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.navy,
        title: Text('Mover "${d.nome}" para'),
        children: [
          for (final p in outras)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p.nome)),
                ],
              ),
            ),
        ],
      ),
    );
    if (destino != null) {
      await _acao(
        () => _vm.mover(d, destino.id),
        'Documento movido para "${destino.nome}".',
      );
    }
  }

  Future<void> _substituir(Documento d) async {
    final escolhido = await escolherArquivos(extensoes: extensoesDocumento);
    if (escolhido.isEmpty) return;
    await _acao(
      () => _vm.substituir(d, escolhido.first),
      'Arquivo de "${d.nome}" substituído.',
    );
  }

  Future<void> _excluir(Documento d) async {
    if (await confirmDelete(context, 'Excluir o documento "${d.nome}"?')) {
      await _acao(() => _vm.remover(d), 'Documento excluído.');
    }
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (!_vm.carregado) {
          return const Center(child: CircularProgressIndicator());
        }
        final largo = MediaQuery.sizeOf(context).width >= 900;
        if (largo) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 320, child: _listaPastas()),
              const VerticalDivider(width: 1, color: Colors.white12),
              Expanded(
                child: _vm.pasta == null
                    ? const Center(
                        child: EmptyState(
                          icon: Icons.folder_open_outlined,
                          message:
                              'Escolha uma pasta ao lado ou crie uma nova\n'
                              'para guardar boletos, relatórios e outros documentos.',
                        ),
                      )
                    : _conteudoPasta(voltar: false),
              ),
            ],
          );
        }
        return _vm.pasta == null
            ? _listaPastas()
            : _conteudoPasta(voltar: true);
      },
    );
  }

  Widget _listaPastas() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pastas',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _vm.ocupado ? null : _novaPasta,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navyDark,
              ),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Nova pasta'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_vm.pastas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(
              icon: Icons.create_new_folder_outlined,
              message:
                  'Nenhuma pasta ainda.\nCrie pastas como "Boletos" e "Relatórios".',
            ),
          ),
        for (final p in _vm.pastas) _cartaoPasta(p),
      ],
    );
  }

  Widget _cartaoPasta(PastaDocumento p) {
    final aberta = p.id == _vm.pastaId;
    return CardPadrao(
      borda: aberta ? AppColors.gold : null,
      onTap: () => _abrirPasta(p.id),
      child: Row(
        children: [
          Icon(
            aberta ? Icons.folder_open : Icons.folder,
            color: AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(switch (p.documentos) {
                  0 => 'Vazia',
                  1 => '1 documento',
                  final n => '$n documentos',
                }, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções da pasta',
            color: AppColors.navy,
            onSelected: (v) =>
                v == 'renomear' ? _renomearPasta(p) : _excluirPasta(p),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'renomear', child: Text('Renomear')),
              PopupMenuItem(value: 'excluir', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conteudoPasta({required bool voltar}) {
    final pasta = _vm.pasta!;
    final lista = _vm.documentos;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (voltar)
                  IconButton(
                    tooltip: 'Voltar às pastas',
                    color: AppColors.gold,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => _abrirPasta(null),
                  ),
                const Icon(Icons.folder_open, color: AppColors.gold),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    pasta.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Renomear pasta',
                  color: AppColors.gold,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _renomearPasta(pasta),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: _vm.ocupado ? null : _enviar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navyDark,
              ),
              icon: _vm.ocupado
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: const Text('Enviar documentos'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Busque no computador arquivos PDF, Word ou Excel '
          '(até $maximoMbDocumento MB cada).',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _busca,
          onChanged: _vm.buscar,
          decoration: const InputDecoration(
            hintText: 'Buscar documento nesta pasta...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        if (_vm.carregandoDocumentos && lista.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: EmptyState(
              icon: Icons.upload_file,
              message: pasta.documentos == 0
                  ? 'Nenhum documento nesta pasta.\n'
                        'Use "Enviar documentos" para buscar no computador.'
                  : 'Nenhum documento encontrado com essa busca.',
            ),
          ),
        for (final d in lista) _cartaoDocumento(d),
      ],
    );
  }

  Widget _cartaoDocumento(Documento d) {
    final (icone, cor) = switch (d.tipo) {
      TipoDocumento.pdf => (Icons.picture_as_pdf, Colors.redAccent),
      TipoDocumento.word => (Icons.description, Colors.lightBlueAccent),
      TipoDocumento.excel => (Icons.table_chart, Colors.greenAccent),
    };
    return CardPadrao(
      onTap: () => _abrir(d),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${d.arquivoNome} • ${_tamanho(d.tamanho)} • '
                  'atualizado em ${formatDateTime(d.atualizadoEm)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Abrir',
            color: AppColors.gold,
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _abrir(d),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções do documento',
            color: AppColors.navy,
            onSelected: (v) => switch (v) {
              'renomear' => _renomear(d),
              'mover' => _mover(d),
              'substituir' => _substituir(d),
              _ => _excluir(d),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'renomear', child: Text('Renomear')),
              PopupMenuItem(
                value: 'mover',
                child: Text('Mover para outra pasta'),
              ),
              PopupMenuItem(
                value: 'substituir',
                child: Text('Substituir arquivo'),
              ),
              PopupMenuItem(value: 'excluir', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

String _tamanho(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
}

/// Pede um nome (pasta ou documento). Devolve null ao cancelar.
Future<String?> _pedirNome(
  BuildContext context, {
  required String titulo,
  required String rotulo,
  String inicial = '',
  String? dica,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _NomeDialog(titulo: titulo, rotulo: rotulo, inicial: inicial, dica: dica),
);

class _NomeDialog extends StatefulWidget {
  const _NomeDialog({
    required this.titulo,
    required this.rotulo,
    required this.inicial,
    this.dica,
  });

  final String titulo;
  final String rotulo;
  final String inicial;
  final String? dica;

  @override
  State<_NomeDialog> createState() => _NomeDialogState();
}

class _NomeDialogState extends State<_NomeDialog> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, aparar(_nome.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(widget.titulo),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: TextFormField(
            controller: _nome,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: widget.rotulo,
              hintText: widget.dica,
            ),
            validator: (v) => aparar(v ?? '').isEmpty ? 'Informe o nome' : null,
            onFieldSubmitted: (_) => _salvar(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navyDark,
          ),
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
