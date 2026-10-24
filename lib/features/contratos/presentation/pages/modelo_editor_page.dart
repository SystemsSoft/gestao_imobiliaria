import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/clausula_modelo.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../../domain/entities/parametro_modelo.dart';
import '../../domain/services/editor_modelo_service.dart';
import '../viewmodels/modelo_editor_viewmodel.dart';
import '../widgets/inserir_dialog.dart';
import '../widgets/parametro_dialog.dart';
import '../widgets/previa_modelo_dialog.dart';

/// Texto inicial de um modelo novo, por tipo.
String textoInicial(TipoModelo t) => switch (t) {
  TipoModelo.locacao =>
    'CONTRATO DE LOCAÇÃO Nº {{numero_contrato}}\n\nLOCADOR(ES): {{locador_qualificacao}}.\n\nLOCATÁRIO: {{locatario_qualificacao}}.\n\nCLÁUSULA 1ª – DO OBJETO. Imóvel situado em {{imovel_endereco}}.\n\n{{cidade_data}}',
  TipoModelo.venda =>
    'CONTRATO DE COMPRA E VENDA Nº {{numero_contrato}}\n\nVENDEDOR(ES): {{vendedor_qualificacao}}.\n\nCOMPRADOR(ES): {{comprador_qualificacao}}.\n\nCLÁUSULA 1ª – DO OBJETO. Imóvel situado em {{imovel_endereco}}.\n\n{{cidade_data}}',
  TipoModelo.temporada =>
    'CONTRATO DE LOCAÇÃO POR TEMPORADA Nº {{numero_contrato}}\n\nLOCADOR: {{locador_qualificacao}}.\n\nHÓSPEDE: {{hospede_qualificacao}}.\n\nCLÁUSULA 1ª – DO OBJETO. Imóvel situado em {{imovel_endereco}}.\n\n{{cidade_data}}',
  TipoModelo.administracao =>
    'CONTRATO DE ADMINISTRAÇÃO Nº {{numero_contrato}}\n\nPROPRIETÁRIO: {{proprietario_qualificacao}}.\n\nCLÁUSULA 1ª – DO OBJETO. Imóvel situado em {{imovel_endereco}}.\n\n{{cidade_data}}',
  TipoModelo.autorizacao =>
    'AUTORIZAÇÃO DE VENDA Nº {{numero_contrato}}\n\nPROPRIETÁRIO: {{proprietario_qualificacao}}.\n\nCLÁUSULA 1ª – DO IMÓVEL. {{imovel_endereco}}.\n\n{{cidade_data}}',
  TipoModelo.outros =>
    'TÍTULO DO DOCUMENTO\n\nPARTE 1: {{parte_a_qualificacao}}.\n\nPARTE 2: {{parte_b_qualificacao}}.\n\nCLÁUSULA 1ª – DO OBJETO. {{objeto}}.\n\n{{cidade_data}}',
};

/// Editor de modelos de contrato: texto, parâmetros próprios e visualização
/// ao vivo. Um [modelo] com id vazio cria um novo.
class ModeloEditorPage extends StatefulWidget {
  const ModeloEditorPage({super.key, required this.modelo});

  final ModeloContrato modelo;

  @override
  State<ModeloEditorPage> createState() => _ModeloEditorPageState();
}

class _ModeloEditorPageState extends State<ModeloEditorPage> {
  final _vm = sl<ModeloEditorViewModel>();
  late final _nome = TextEditingController(text: widget.modelo.nome);
  late final _descricao = TextEditingController(text: widget.modelo.descricao);
  late final _texto = TextEditingController(text: widget.modelo.texto);
  late TipoModelo _tipo = widget.modelo.tipo;
  late List<ParametroModelo> _parametros = [...widget.modelo.parametros];

  bool get _novo => widget.modelo.id.isEmpty;

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _texto.dispose();
    _vm.dispose();
    super.dispose();
  }

  ModeloContrato _montar({bool comoNovo = false}) => widget.modelo.copyWith(
    id: comoNovo ? '' : widget.modelo.id,
    nome: _nome.text.trim(),
    descricao: _descricao.text.trim(),
    tipo: _tipo,
    texto: _texto.text,
    parametros: _parametros,
  );

  Future<void> _salvar({bool comoNovo = false}) async {
    final ok = await _vm.salvar(_montar(comoNovo: comoNovo));
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível salvar.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          comoNovo
              ? 'Salvo como novo modelo em "Meus modelos".'
              : 'Modelo salvo em "Meus modelos".',
        ),
      ),
    );
  }

  Future<void> _restaurar() async {
    final seguir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: const Text('Restaurar texto original'),
        content: const Text(
          'O texto e os parâmetros voltam ao do modelo pronto de origem. '
          'As alterações não salvas serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (seguir != true) return;
    final ok = await _vm.restaurar(_montar());
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível restaurar.');
      return;
    }
    setState(() {
      _texto.text = _vm.restaurado!.texto;
      _parametros = [..._vm.restaurado!.parametros];
    });
  }

  Future<void> _imprimirExemplo() async {
    if (!await _vm.imprimirExemplo(_montar()) && mounted) {
      mostrarMensagem(context, _vm.erro ?? 'Falha ao gerar o PDF.');
    }
  }

  /// Insere [t] na posição do cursor (ou no fim do texto).
  void _inserir(String t) {
    final sel = _texto.selection;
    final txt = _texto.text;
    final ini = sel.isValid ? sel.start : txt.length;
    final fim = sel.isValid ? sel.end : txt.length;
    _texto.value = TextEditingValue(
      text: txt.replaceRange(ini, fim, t),
      selection: TextSelection.collapsed(offset: ini + t.length),
    );
  }

  Future<void> _abrirInserir(int aba) async {
    final r = await mostrarInserirDialog(
      context,
      campos: _vm.campos(_tipo),
      parametros: _parametros,
      clausulas: _vm.clausulas,
      abaInicial: aba,
    );
    if (r is String) {
      _inserir(r);
    } else if (r is ClausulaModelo) {
      _inserir('\n\n${_vm.clausulaNumerada(r, _texto.text)}');
    }
  }

  Future<void> _editarParametro({
    ParametroModelo? atual,
    String chave = '',
  }) async {
    final p = await mostrarParametroDialog(
      context,
      parametro: atual,
      chaveInicial: chave,
      chaveDoRotulo: _vm.chaveDoRotulo,
      validar: (novo) => _vm.validarParametro(novo, _tipo, [
        for (final o in _parametros)
          if (o != atual) o,
      ]),
    );
    if (p == null) return;
    setState(() {
      final i = atual == null ? -1 : _parametros.indexOf(atual);
      i >= 0 ? _parametros[i] = p : _parametros.add(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final analise = _vm.analisar(_texto.text, _tipo, _parametros);
    final abas = [
      ('Texto', Icons.edit_note, _abaTexto(analise)),
      (
        'Parâmetros (${_parametros.length})',
        Icons.tune,
        _abaParametros(analise),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text(_novo ? 'Novo modelo' : 'Editar modelo'),
        actions: [
          IconButton(
            tooltip: 'Imprimir exemplo (PDF)',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _imprimirExemplo,
          ),
          PopupMenuButton<String>(
            color: AppColors.navy,
            onSelected: (v) =>
                v == 'novo' ? _salvar(comoNovo: true) : _restaurar(),
            itemBuilder: (_) => [
              if (!_novo)
                const PopupMenuItem(
                  value: 'novo',
                  child: Text('Salvar como novo modelo'),
                ),
              if (widget.modelo.derivadoDePronto)
                const PopupMenuItem(
                  value: 'restaurar',
                  child: Text('Restaurar texto original'),
                ),
            ],
          ),
          TextButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: const Text('SALVAR'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final previa = _previa();
          if (c.maxWidth >= 1000) {
            return Row(
              children: [
                Expanded(flex: 5, child: _Abas(abas: abas)),
                const VerticalDivider(width: 1),
                Expanded(flex: 4, child: previa),
              ],
            );
          }
          return _Abas(
            abas: [
              ...abas,
              ('Visualização', Icons.visibility_outlined, previa),
            ],
          );
        },
      ),
    );
  }

  Widget _abaTexto(AnaliseModelo a) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldRow(
            flex: const [3, 2],
            children: [
              AppTextField(label: 'Nome do modelo *', controller: _nome),
              AppDropdown<TipoModelo>(
                label: 'Tipo',
                value: _tipo,
                items: TipoModelo.values,
                labelOf: (e) => e.label,
                onChanged: (v) => setState(() => _tipo = v ?? _tipo),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(label: 'Descrição (opcional)', controller: _descricao),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => _abrirInserir(0),
                icon: const Icon(Icons.data_object, size: 18),
                label: const Text('Inserir campo'),
              ),
              OutlinedButton.icon(
                onPressed: () => _abrirInserir(2),
                icon: const Icon(Icons.library_books_outlined, size: 18),
                label: const Text('Biblioteca de cláusulas'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _inserir('\n\n${_vm.novaClausula(_texto.text)}'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nova cláusula'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _texto.text = _vm.renumerar(_texto.text)),
                icon: const Icon(Icons.format_list_numbered, size: 18),
                label: const Text('Renumerar cláusulas'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _analise(a),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _texto,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(height: 1.5, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Texto do contrato (a 1ª linha é o título)',
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analise(AnaliseModelo a) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${a.palavras} palavras • ${a.clausulas} cláusula(s) • ${a.usados.length} campo(s)',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        for (final k in a.desconhecidos)
          ActionChip(
            avatar: const Icon(
              Icons.error_outline,
              size: 16,
              color: Colors.redAccent,
            ),
            label: Text(
              '{{$k}} desconhecido • criar parâmetro',
              style: const TextStyle(fontSize: 12),
            ),
            side: const BorderSide(color: Colors.redAccent),
            onPressed: () => _editarParametro(chave: k),
          ),
      ],
    );
  }

  Widget _abaParametros(AnaliseModelo a) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Parâmetros são campos que você cria (ex.: cidade do foro, prazo de aviso). '
          'Use {{chave}} no texto: na impressão, o valor padrão é aplicado.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _editarParametro(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navyDark,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Novo parâmetro'),
          ),
        ),
        const SizedBox(height: 12),
        if (_parametros.isEmpty)
          const EmptyState(
            icon: Icons.tune,
            message: 'Nenhum parâmetro neste modelo.',
          ),
        for (final p in _parametros)
          CardPadrao(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.rotulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GoldChip(p.tipo.label),
                          if (a.parametrosNaoUsados.contains(p)) ...const [
                            SizedBox(width: 6),
                            GoldChip(
                              'Não usado no texto',
                              color: Colors.orangeAccent,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        p.marcador,
                        style: TextStyle(
                          color: AppColors.goldLight,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Padrão: ${p.valorPadrao.isEmpty ? '—' : p.valorPadrao}'
                        '${p.descricao.isEmpty ? '' : ' • ${p.descricao}'}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Inserir no texto',
                  icon: Icon(Icons.input, color: AppColors.gold),
                  onPressed: () => _inserir(p.marcador),
                ),
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editarParametro(atual: p),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _parametros.remove(p)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _previa() {
    return Container(
      color: Colors.black.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Visualização com dados de exemplo (campos em vermelho não existem)',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FolhaContrato(
                texto: _vm.previa(_texto.text, _tipo, _parametros),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Abas com cabeçalho e conteúdo.
class _Abas extends StatelessWidget {
  const _Abas({required this.abas});

  final List<(String, IconData, Widget)> abas;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: abas.length,
      child: Column(
        children: [
          Material(
            color: AppColors.navy,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.gold,
              labelColor: AppColors.gold,
              unselectedLabelColor: Colors.white70,
              tabs: [for (final a in abas) Tab(icon: Icon(a.$2), text: a.$1)],
            ),
          ),
          Expanded(child: TabBarView(children: [for (final a in abas) a.$3])),
        ],
      ),
    );
  }
}
