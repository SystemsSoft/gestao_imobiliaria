import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/arquivos/arquivo_repository.dart';
import '../../../../core/arquivos/escolher_arquivos.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/midia_anexo.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../equipe/domain/entities/usuario_sistema.dart';
import '../../../locacao/domain/entities/contrato_locacao.dart';
import '../../domain/entities/auditoria.dart';
import '../viewmodels/auditoria_viewmodels.dart';
import '../widgets/auditoria_visual.dart';

/// Auditoria em campo: dados da visita, checklist por área, fotos e vídeos
/// (com transcrição do que foi dito), nota, conclusão e relatório.
class AuditoriaPage extends StatefulWidget {
  const AuditoriaPage({
    super.key,
    required this.auditoria,
    this.modelos = const [],
  });

  final Auditoria auditoria;
  final List<ModeloChecklist> modelos;

  @override
  State<AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends State<AuditoriaPage> {
  late final _vm = sl<AuditoriaFormViewModel>(param1: widget.auditoria);
  late final _resumo = TextEditingController(text: widget.auditoria.resumo);
  late final _recomendacoes = TextEditingController(
    text: widget.auditoria.recomendacoes,
  );

  Auditoria get _a => _vm.auditoria;

  @override
  void dispose() {
    _vm.dispose();
    _resumo.dispose();
    _recomendacoes.dispose();
    super.dispose();
  }

  Future<void> _resultado(Future<bool> acao, String sucesso) async {
    final ok = await acao;
    if (mounted) mostrarMensagem(context, ok ? sucesso : (_vm.erro ?? 'Erro.'));
  }

  Future<bool> _confirmar(String texto, {String botao = 'Confirmar'}) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.navy,
          content: Text(texto),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(botao),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _sair() async {
    if (_vm.enviando &&
        !await _confirmar(
          'Ainda há fotos ou vídeos sendo enviados. Sair agora cancela o '
          'que falta enviar.',
          botao: 'Sair mesmo assim',
        )) {
      return;
    }
    if (_vm.alterada &&
        !await _confirmar(
          'Sair sem salvar as alterações?',
          botao: 'Sair sem salvar',
        )) {
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// Câmera (foto ou vídeo) ou galeria do aparelho; cada arquivo é
  /// anexado como foto ou vídeo conforme o formato.
  Future<void> _escolherMidia(OrigemArquivo origem, {String? itemId}) async {
    final escolhidos = await escolherArquivos(
      origem: origem,
      multiplos: true,
      tipos: const ['image/*', 'video/*'],
      extensoes: [
        ...CategoriaArquivo.foto.extensoes,
        ...CategoriaArquivo.video.extensoes,
      ],
    );
    if (escolhidos.isEmpty || !mounted) return;
    final arquivos = [
      for (final a in escolhidos)
        (
          a,
          CategoriaArquivo.video.extensoes.contains(
                a.nome.split('.').last.toLowerCase(),
              )
              ? TipoMidia.video
              : TipoMidia.foto,
        ),
    ];
    final ok = await _vm.anexar(arquivos, itemId: itemId);
    if (!mounted) return;
    mostrarMensagem(
      context,
      ok
          ? 'Enviando ${arquivos.length} arquivo(s) em segundo plano. '
                'Pode continuar a auditoria.'
          : (_vm.erro ?? 'Erro.'),
    );
  }

  Future<void> _concluir() async {
    final publicar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: const Text('Concluir auditoria'),
        content: const Text(
          'Depois de concluída, a auditoria fica travada (só quem pode excluir '
          'consegue reabrir). Publicar agora na Área do proprietário do site?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Concluir sem publicar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Concluir e publicar'),
          ),
        ],
      ),
    );
    if (publicar == null) return;
    await _resultado(
      _vm.concluir(publicar: publicar),
      publicar
          ? 'Auditoria concluída e publicada para o proprietário.'
          : 'Auditoria concluída.',
    );
  }

  Future<void> _relatorio() async {
    if (!await _vm.abrirRelatorio()) {
      if (mounted) mostrarMensagem(context, _vm.erro ?? 'Erro.');
      return;
    }
    await launchUrl(_vm.relatorio!, webOnlyWindowName: '_blank');
  }

  Future<void> _manutencoes() async {
    if (!await _confirmar(
      'Criar uma pauta de manutenção para cada item com "Problema" '
      '(${_a.problemasSemManutencao})?',
    )) {
      return;
    }
    await _resultado(
      _vm.gerarManutencoes(),
      'Manutenções criadas: ${_vm.manutencoesCriadas}. Acompanhe em '
      'Administração de Locação › Manutenção.',
    );
  }

  Future<void> _excluir() async {
    if (!await confirmDelete(context, 'Excluir a auditoria ${_a.numero}?')) {
      return;
    }
    if (await _vm.excluir()) {
      if (mounted) Navigator.of(context).pop();
    } else if (mounted) {
      mostrarMensagem(context, _vm.erro ?? 'Erro.');
    }
  }

  Future<void> _novoItem() async {
    final area = TextEditingController(text: _vm.areas.keys.lastOrNull ?? '');
    final item = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: const Text('Novo item do checklist'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Área (ex.: Cozinha)', controller: area),
              const SizedBox(height: 12),
              AppTextField(label: 'Item (ex.: Torneiras)', controller: item),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Incluir'),
          ),
        ],
      ),
    );
    if (ok == true &&
        area.text.trim().isNotEmpty &&
        item.text.trim().isNotEmpty) {
      _vm.adicionarItem(area.text, item.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (pop, _) {
        if (!pop) _sair();
      },
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => Scaffold(
          backgroundColor: AppColors.navyDark,
          appBar: AppBar(
            backgroundColor: AppColors.navyDark,
            leading: BackButton(onPressed: _sair),
            title: Text(
              _a.nova
                  ? 'Nova auditoria'
                  : '${_a.numero} • ${_vm.nomeImovel(_a.imovelId)}',
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (_vm.ocupado)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (!_a.nova)
                IconButton(
                  tooltip: 'Relatório (imprimir / PDF)',
                  icon: const Icon(Icons.print_outlined),
                  onPressed: _vm.ocupado ? null : _relatorio,
                ),
              if (!_vm.somenteLeitura)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                    ),
                    onPressed: _vm.ocupado
                        ? null
                        : () => _resultado(_vm.salvar(), 'Auditoria salva.'),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Salvar'),
                  ),
                ),
              if (!_a.nova && !_vm.somenteLeitura)
                IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _vm.ocupado ? null : _excluir,
                ),
            ],
          ),
          body: FundoMarca(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                // Montada sob demanda: cada item do checklist só é
                // construído quando aparece na tela (abre sem travar).
                child: Builder(
                  builder: (context) {
                    final blocos = _blocos();
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        MediaQuery.sizeOf(context).width < 600 ? 10 : 16,
                        16,
                        MediaQuery.sizeOf(context).width < 600 ? 10 : 16,
                        80,
                      ),
                      itemCount: blocos.length,
                      itemBuilder: (_, i) => blocos[i](),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ Faixa

  Widget _faixaConcluida() => CardPadrao(
    borda: Colors.greenAccent,
    child: Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Text(
              'Concluída em ${formatDate(_a.dataRealizada)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Na Área do proprietário'),
            Switch(
              value: _a.publicada,
              activeThumbColor: AppColors.gold,
              onChanged: _vm.ocupado
                  ? null
                  : (v) => _resultado(
                      _vm.publicar(v),
                      v
                          ? 'Publicada: o proprietário já pode ver no site.'
                          : 'Retirada da Área do proprietário.',
                    ),
            ),
            OutlinedButton.icon(
              onPressed: _vm.ocupado
                  ? null
                  : () async {
                      if (await _confirmar(
                        'Reabrir a auditoria para edição? Ela sai da Área do '
                        'proprietário até ser concluída de novo.',
                      )) {
                        await _resultado(_vm.reabrir(), 'Auditoria reaberta.');
                      }
                    },
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text('Reabrir'),
            ),
          ],
        ),
      ],
    ),
  );

  // ------------------------------------------------------------------ Dados

  Widget _dados() {
    final ro = _vm.somenteLeitura;
    final imovel = _vm.imoveis[_a.imovelId];
    final contratos = _vm.contratosDoImovel;
    final contrato = contratos.where((c) => c.id == _a.contratoId).firstOrNull;
    final corretor = _vm.corretores
        .where((u) => u.id == _a.corretorId)
        .firstOrNull;
    final proprietario =
        _vm.contatos[_a.proprietarioId ?? imovel?.proprietarioId];
    return FormSection(
      title: 'Dados da visita',
      icon: Icons.event_note_outlined,
      children: [
        FieldRow(
          children: [
            _a.nova
                ? AppDropdown<Imovel>(
                    label: 'Imóvel',
                    value: imovel,
                    items: _vm.listaImoveis,
                    labelOf: (i) => '${i.codigo} • ${i.titulo}',
                    onChanged: (i) => _vm.editar(
                      (a) => a.copyWith(
                        imovelId: i?.id ?? '',
                        contratoId: () => _vm.contratos.values
                            .where(
                              (c) =>
                                  c.imovelId == i?.id &&
                                  c.status.name == 'ativo',
                            )
                            .firstOrNull
                            ?.id,
                      ),
                    ),
                  )
                : _leitura('Imóvel', _vm.nomeImovel(_a.imovelId)),
            ro
                ? _leitura('Contrato', contrato?.numero ?? '—')
                : AppDropdown<ContratoLocacao?>(
                    label: 'Contrato de locação',
                    value: contrato,
                    items: [null, ...contratos],
                    labelOf: (c) => c == null
                        ? 'Sem contrato'
                        : '${c.numero} • ${c.status.label}',
                    onChanged: (c) =>
                        _vm.editar((a) => a.copyWith(contratoId: () => c?.id)),
                  ),
          ],
        ),
        if (proprietario != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Proprietário: ${proprietario.nome}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        const SizedBox(height: 14),
        FieldRow(
          children: [
            ro
                ? _leitura('Tipo', _a.tipo.label)
                : AppDropdown<TipoAuditoria>(
                    label: 'Tipo',
                    value: _a.tipo,
                    items: TipoAuditoria.values,
                    labelOf: (t) => t.label,
                    onChanged: (t) => _vm.editar((a) => a.copyWith(tipo: t)),
                  ),
            ro
                ? _leitura('Situação', _a.status.label)
                : AppDropdown<StatusAuditoria>(
                    label: 'Situação',
                    value: _a.status,
                    items: StatusAuditoria.editaveis,
                    labelOf: (s) => s.label,
                    onChanged: (s) => _vm.editar((a) => a.copyWith(status: s)),
                  ),
            ro
                ? _leitura('Corretor', corretor?.nome ?? '—')
                : AppDropdown<UsuarioSistema?>(
                    label: 'Corretor responsável',
                    value: corretor,
                    items: [null, ..._vm.corretores],
                    labelOf: (u) => u?.nome ?? 'Ninguém',
                    onChanged: (u) =>
                        _vm.editar((a) => a.copyWith(corretorId: () => u?.id)),
                  ),
          ],
        ),
        const SizedBox(height: 14),
        FieldRow(
          children: [
            ro
                ? _leitura('Agendada para', formatDate(_a.dataAgendada))
                : DateField(
                    label: 'Agendada para',
                    value: _a.dataAgendada,
                    onChanged: (d) =>
                        _vm.editar((a) => a.copyWith(dataAgendada: () => d)),
                  ),
            ro
                ? _leitura('Realizada em', formatDate(_a.dataRealizada))
                : DateField(
                    label: 'Realizada em',
                    value: _a.dataRealizada,
                    onChanged: (d) =>
                        _vm.editar((a) => a.copyWith(dataRealizada: () => d)),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _leitura(String rotulo, String valor) => InputDecorator(
    decoration: InputDecoration(labelText: rotulo),
    child: Text(valor.isEmpty ? '—' : valor),
  );

  // -------------------------------------------------------------- Checklist

  /// Partes da página, construídas uma a uma pela lista.
  List<Widget Function()> _blocos() {
    final ro = _vm.somenteLeitura;
    return [
      if (_a.concluida) _faixaConcluida,
      _dados,
      _checklist,
      for (final e in _vm.areas.entries) ...[
        () => _tituloArea(e.key, e.value, ro),
        for (final i in e.value) () => _item(i, ro),
      ],
      if (!ro) _acoesChecklist else () => const SizedBox(height: 16),
      _midias,
      _conclusao,
    ];
  }

  Widget _checklist() {
    final avaliados = _a.itens.length - _a.contar(EstadoItem.pendente);
    return FormSection(
      title: 'Checklist ($avaliados de ${_a.itens.length} avaliados)',
      icon: Icons.checklist,
      children: [
        Wrap(
          spacing: 14,
          children: [
            for (final e in EstadoItem.values)
              Text(
                '${e.label}: ${_a.contar(e)}',
                style: TextStyle(color: e.cor, fontSize: 12),
              ),
          ],
        ),
        if (_a.itens.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Checklist vazio. Inclua itens ou aplique um modelo.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
      ],
    );
  }

  Widget _tituloArea(String area, List<ItemAuditoria> itens, bool ro) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                area,
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            if (!ro && itens.any((i) => i.estado == EstadoItem.pendente))
              TextButton.icon(
                onPressed: () => _vm.areaOk(area),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Restantes OK'),
              ),
          ],
        ),
      );

  Widget _acoesChecklist() => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Wrap(
      spacing: 8,
      children: [
        TextButton.icon(
          onPressed: _novoItem,
          icon: const Icon(Icons.add),
          label: const Text('Incluir item'),
        ),
        if (widget.modelos.isNotEmpty)
          PopupMenuButton<ModeloChecklist>(
            tooltip: 'Aplicar modelo',
            color: AppColors.navy,
            onSelected: _vm.aplicarModelo,
            itemBuilder: (_) => [
              for (final m in widget.modelos)
                PopupMenuItem(value: m, child: Text(m.nome)),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add, color: AppColors.gold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Aplicar modelo',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _item(ItemAuditoria i, bool ro) {
    final midias = _vm.midiasDo(i.id);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: i.estado.cor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: i.estado.cor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220),
                child: Text(
                  i.item,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final e in EstadoItem.values.skip(1))
                ChoiceChip(
                  label: Text(e.label),
                  avatar: Icon(e.icone, size: 16, color: e.cor),
                  selected: i.estado == e,
                  selectedColor: e.cor.withValues(alpha: 0.3),
                  onSelected: ro ? null : (_) => _vm.avaliar(i, e),
                ),
              if (i.manutencaoId != null)
                Tooltip(
                  message: 'Manutenção criada',
                  child: Icon(Icons.handyman, color: AppColors.gold, size: 18),
                ),
              if (!ro) ...[
                IconButton(
                  tooltip: 'Tirar foto deste item',
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                  onPressed: _vm.ocupado
                      ? null
                      : () => _escolherMidia(OrigemArquivo.foto, itemId: i.id),
                ),
                IconButton(
                  tooltip: 'Gravar vídeo deste item',
                  icon: const Icon(Icons.videocam_outlined, size: 20),
                  onPressed: _vm.ocupado
                      ? null
                      : () => _escolherMidia(OrigemArquivo.video, itemId: i.id),
                ),
                IconButton(
                  tooltip: 'Fotos e vídeos da galeria',
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  onPressed: _vm.ocupado
                      ? null
                      : () => _escolherMidia(
                          OrigemArquivo.arquivos,
                          itemId: i.id,
                        ),
                ),
                IconButton(
                  tooltip: 'Remover item',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _vm.removerItem(i),
                ),
              ],
            ],
          ),
          if (i.estado != EstadoItem.ok || i.observacao.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ro
                  ? Text(
                      i.observacao,
                      style: const TextStyle(color: Colors.white70),
                    )
                  : TextFormField(
                      key: ValueKey('obs-${i.id}'),
                      initialValue: i.observacao,
                      maxLines: null,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Observação (o que foi visto, o que fazer)',
                      ),
                      onChanged: (t) => _vm.observarItem(i, t),
                    ),
            ),
          if (midias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final m in midias) _miniatura(m, 72)],
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- Mídias

  Widget _midias() {
    final ro = _vm.somenteLeitura;
    final fotos = _a.midias.where((m) => !m.video).toList();
    final videos = _a.midias.where((m) => m.video).toList();
    return FormSection(
      title: 'Fotos e vídeos',
      icon: Icons.perm_media_outlined,
      children: [
        if (!ro)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                ),
                onPressed: _vm.ocupado
                    ? null
                    : () => _escolherMidia(OrigemArquivo.foto),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Tirar foto'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                ),
                onPressed: _vm.ocupado
                    ? null
                    : () => _escolherMidia(OrigemArquivo.video),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Gravar vídeo'),
              ),
              OutlinedButton.icon(
                onPressed: _vm.ocupado
                    ? null
                    : () => _escolherMidia(OrigemArquivo.arquivos),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Da galeria'),
              ),
            ],
          ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Grave o vídeo narrando o que vê: o servidor transcreve a fala e o '
            'texto entra no relatório e na Área do proprietário.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        if (_vm.envios.isNotEmpty) _envios(),
        if (fotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final m in fotos) _miniatura(m, 110)],
          ),
        ],
        for (final v in videos) _video(v),
        if (_a.midias.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Nenhuma foto ou vídeo ainda.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
      ],
    );
  }

  /// Arquivos subindo em segundo plano (ou que falharam).
  Widget _envios() => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.gold.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        for (final e in _vm.envios)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                e.falhou
                    ? const Icon(Icons.error_outline, color: Colors.redAccent)
                    : const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.arquivo.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        e.erro ??
                            (e ==
                                    _vm.envios.firstWhere(
                                      (x) => !x.falhou,
                                      orElse: () => e,
                                    )
                                ? 'Enviando ${_tamanho(e.arquivo.tamanho)}...'
                                : 'Na fila'),
                        style: TextStyle(
                          fontSize: 12,
                          color: e.falhou ? Colors.redAccent : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (e.falhou) ...[
                  IconButton(
                    tooltip: 'Tentar de novo',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _vm.tentarDeNovo(e),
                  ),
                  IconButton(
                    tooltip: 'Descartar',
                    icon: const Icon(Icons.close),
                    onPressed: () => _vm.descartarEnvio(e),
                  ),
                ],
              ],
            ),
          ),
      ],
    ),
  );

  static String _tamanho(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).ceil()} KB';

  String _legenda(MidiaAuditoria m) {
    final item = _a.itens.where((i) => i.id == m.itemId).firstOrNull;
    return [
      if (m.titulo.isNotEmpty) m.titulo,
      if (item != null) '${item.area} – ${item.item}',
      formatDateTime(m.criadoEm),
    ].join('\n');
  }

  Widget _miniatura(MidiaAuditoria m, double tamanho) => Tooltip(
    message: _legenda(m),
    child: Stack(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => abrirAnexo(context, m.referencia),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.square(
              dimension: tamanho,
              child: m.video
                  ? ColoredBox(
                      color: AppColors.navy,
                      child: Icon(
                        Icons.play_circle_outline,
                        color: AppColors.gold,
                        size: 32,
                      ),
                    )
                  : ImagemAnexo(
                      m.referencia,
                      largura: 320,
                      alternativa: ColoredBox(
                        color: AppColors.navy,
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.white38,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (!_vm.somenteLeitura)
          Positioned(
            right: 0,
            top: 0,
            child: InkWell(
              onTap: () async {
                if (await confirmDelete(context, 'Remover esta mídia?')) {
                  await _resultado(_vm.removerMidia(m), 'Mídia removida.');
                }
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(Icons.close, size: 14),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _video(MidiaAuditoria v) {
    final s = v.transcricaoStatus;
    final cor = switch (s) {
      StatusTranscricao.concluida => Colors.greenAccent,
      StatusTranscricao.erro => Colors.redAccent,
      StatusTranscricao.pendente ||
      StatusTranscricao.processando => Colors.orangeAccent,
      StatusTranscricao.naoSolicitada => Colors.white54,
    };
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _miniatura(v, 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _legenda(v).replaceAll('\n', ' • '),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (s.emAndamento)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox.square(
                              dimension: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        GoldChip(s.label, color: cor),
                      ],
                    ),
                  ],
                ),
              ),
              if (!s.emAndamento)
                TextButton.icon(
                  onPressed: _vm.ocupado
                      ? null
                      : () => _resultado(
                          _vm.transcrever(v),
                          'Vídeo na fila de transcrição. O texto aparece aqui '
                          'quando ficar pronto.',
                        ),
                  icon: const Icon(Icons.record_voice_over_outlined, size: 18),
                  label: Text(
                    s == StatusTranscricao.naoSolicitada
                        ? 'Transcrever'
                        : 'Transcrever de novo',
                  ),
                ),
            ],
          ),
          if (s == StatusTranscricao.erro && v.transcricaoErro.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                v.transcricaoErro,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          if (v.transcricaoTexto.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.7),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'O que foi dito no vídeo',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    v.transcricaoTexto,
                    style: const TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- Conclusão

  Widget _conclusao() {
    final ro = _vm.somenteLeitura;
    final problemas = _a.problemasSemManutencao;
    return FormSection(
      title: 'Conclusão',
      icon: Icons.assignment_turned_in_outlined,
      children: [
        Row(
          children: [
            const Text('Conservação do imóvel: '),
            Estrelas(
              nota: _a.nota,
              tamanho: 28,
              onChanged: ro
                  ? null
                  : (n) => _vm.editar((a) => a.copyWith(nota: () => n)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Resumo para o proprietário',
          controller: _resumo,
          maxLines: 4,
          readOnly: ro,
          onChanged: (t) => _vm.editar((a) => a.copyWith(resumo: t)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Recomendações',
          controller: _recomendacoes,
          maxLines: 3,
          readOnly: ro,
          onChanged: (t) => _vm.editar((a) => a.copyWith(recomendacoes: t)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: [
            if (problemas > 0)
              OutlinedButton.icon(
                onPressed: _vm.ocupado ? null : _manutencoes,
                icon: const Icon(Icons.handyman_outlined),
                label: Text('Gerar manutenções ($problemas)'),
              ),
            if (!ro)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _vm.ocupado ? null : _concluir,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Concluir auditoria'),
              ),
          ],
        ),
      ],
    );
  }
}
