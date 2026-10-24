import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/midia_anexo.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../locacao/domain/entities/contrato_locacao.dart';
import '../../../manutencao/domain/entities/manutencao.dart';
import '../../../manutencao/presentation/pages/manutencao_detalhe_page.dart';
import '../../../manutencao/presentation/viewmodels/manutencoes_viewmodel.dart';
import '../../../site/domain/repositories/site_repository.dart';
import '../../domain/entities/portal.dart';
import '../../domain/usecases/portal_usecases.dart';
import '../viewmodels/portal_viewmodels.dart';
import '../widgets/portal_dialogs.dart';
import '../widgets/portal_inquilino_tab.dart';

/// Portal do inquilino de um contrato: acesso, documentos, envios do
/// inquilino, chamados e avisos.
class PortalContratoPage extends StatefulWidget {
  const PortalContratoPage({
    super.key,
    required this.contrato,
    this.locatario,
    this.imovel,
  });

  final ContratoLocacao contrato;
  final Contato? locatario;
  final Imovel? imovel;

  @override
  State<PortalContratoPage> createState() => _PortalContratoPageState();
}

class _PortalContratoPageState extends State<PortalContratoPage> {
  late final _vm = sl<PortalContratoViewModel>(param1: widget.contrato);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _resultado(Future<bool> acao, String sucesso) async {
    final ok = await acao;
    if (mounted) mostrarMensagem(context, ok ? sucesso : (_vm.erro ?? 'Erro.'));
  }

  Future<void> _liberar() async {
    if (_vm.acesso != null &&
        !await _confirmar(
          'Gerar nova senha provisória? A senha atual deixa de funcionar e '
          'o inquilino é desconectado.',
        )) {
      return;
    }
    if (!await _vm.liberarAcesso()) {
      if (mounted) mostrarMensagem(context, _vm.erro ?? 'Erro.');
      return;
    }
    final senha = _vm.senhaGerada!;
    if (!mounted) return;
    await mostrarSenhaProvisoria(
      context,
      senha: senha,
      telefone: widget.locatario?.celular.isNotEmpty ?? false
          ? widget.locatario!.celular
          : widget.locatario?.telefone ?? '',
      mensagem: mensagemDeAcesso(
        nome: widget.locatario?.nome ?? '',
        enderecoSite: sl<SiteRepository>().endereco,
        senha: senha,
      ),
    );
  }

  Future<bool> _confirmar(String texto) async =>
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
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _publicar() async {
    final doc = await pedirDocumento(context);
    if (doc == null) return;
    await _resultado(
      _vm.publicar(tipo: doc.tipo, titulo: doc.titulo, arquivo: doc.arquivo),
      'Documento publicado. O inquilino foi avisado.',
    );
  }

  Future<void> _aviso() async {
    final a = await pedirComunicado(context, titulo: 'Aviso para o inquilino');
    if (a == null) return;
    await _resultado(
      _vm.enviarComunicado(a.titulo, a.mensagem),
      'Aviso publicado no portal.',
    );
  }

  void _abrirChamado(Manutencao m) {
    final vm = sl<ManutencoesViewModel>(param1: ContextoManutencao.locacao);
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ManutencaoDetalhePage(vm: vm, manutencaoId: m.id),
          ),
        )
        .whenComplete(vm.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        title: Text(
          'Portal do inquilino • ${widget.contrato.numero}'
          '${widget.locatario != null ? ' • ${widget.locatario!.nome}' : ''}',
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _vm.recarregar,
          ),
        ],
      ),
      body: FundoMarca(
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            if (!_vm.carregado) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
                  children: [
                    _acesso(),
                    _secao(
                      'Documentos do contrato',
                      Icons.description_outlined,
                      acao: TextButton.icon(
                        onPressed: _vm.ocupado ? null : _publicar,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Publicar documento'),
                      ),
                      filhos: _vm.documentos.isEmpty
                          ? [
                              _vazio(
                                'Publique a via digital do contrato e o laudo '
                                'de vistoria para o inquilino.',
                              ),
                            ]
                          : [for (final a in _vm.documentos) _documento(a)],
                    ),
                    _secao(
                      'Fotos e vídeos enviados pelo inquilino',
                      Icons.photo_library_outlined,
                      filhos: _vm.enviadosPeloInquilino.isEmpty
                          ? [_vazio('Nada enviado ainda.')]
                          : [_midias(_vm.enviadosPeloInquilino)],
                    ),
                    _secao(
                      'Chamados de manutenção',
                      Icons.handyman_outlined,
                      filhos: _vm.chamados.isEmpty
                          ? [_vazio('Nenhum chamado deste contrato.')]
                          : [for (final m in _vm.chamados) _chamado(m)],
                    ),
                    _secao(
                      'Avisos',
                      Icons.campaign_outlined,
                      acao: TextButton.icon(
                        onPressed: _aviso,
                        icon: const Icon(Icons.add_comment_outlined),
                        label: const Text('Novo aviso'),
                      ),
                      filhos: _vm.comunicados.isEmpty
                          ? [_vazio('Nenhum aviso enviado.')]
                          : [for (final c in _vm.comunicados) _comunicado(c)],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _acesso() {
    final a = _vm.acesso;
    final (rotulo, cor) = situacaoAcesso(a);
    final semDocumento = widget.locatario?.documento.trim().isEmpty ?? true;
    return CardPadrao(
      borda: cor,
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.key_outlined, color: cor),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rotulo,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    a == null
                        ? semDocumento
                              ? 'Cadastre o CPF/CNPJ do locatário: ele é o login.'
                              : 'Login será o CPF/CNPJ: ${widget.locatario!.documento}'
                        : 'Login ${a.login}'
                              '${a.ultimoAcesso != null ? ' • último acesso ${formatDateTime(a.ultimoAcesso)}' : ' • ainda não entrou'}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _vm.ocupado ? null : _liberar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                ),
                icon: const Icon(Icons.lock_open, size: 18),
                label: Text(a == null ? 'Liberar acesso' : 'Gerar nova senha'),
              ),
              if (a != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    if (await _confirmar(
                      'Revogar o acesso deste inquilino ao portal?',
                    )) {
                      await _resultado(_vm.revogarAcesso(), 'Acesso revogado.');
                    }
                  },
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Revogar'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secao(
    String titulo,
    IconData icone, {
    Widget? acao,
    required List<Widget> filhos,
  }) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, color: AppColors.gold),
            const SizedBox(width: 10),
            Expanded(child: Text(titulo, style: estiloTitulo(tamanho: 20))),
            ?acao,
          ],
        ),
        const SizedBox(height: 8),
        ...filhos,
      ],
    ),
  );

  Widget _vazio(String texto) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(texto, style: const TextStyle(color: Colors.white54)),
  );

  Widget _documento(ArquivoContrato a) => CardPadrao(
    onTap: () => abrirAnexo(context, a.referencia),
    child: Row(
      children: [
        Icon(Icons.picture_as_pdf_outlined, color: AppColors.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.titulo,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${a.tipo.label} • ${formatDate(a.criadoEm)}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const Text('Visível', style: TextStyle(fontSize: 12)),
        Switch(
          value: a.visivelInquilino,
          activeThumbColor: AppColors.gold,
          onChanged: (_) => _resultado(
            _vm.alternarVisibilidade(a),
            a.visivelInquilino
                ? 'Oculto para o inquilino.'
                : 'Visível para o inquilino.',
          ),
        ),
        IconButton(
          tooltip: 'Excluir',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            if (await confirmDelete(
              context,
              'Excluir "${a.titulo}" do portal?',
            )) {
              await _resultado(_vm.removerArquivo(a), 'Documento excluído.');
            }
          },
        ),
      ],
    ),
  );

  Widget _midias(List<ArquivoContrato> itens) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final a in itens)
        Tooltip(
          message: [
            a.tipo.label,
            formatDateTime(a.criadoEm),
            if (a.observacao.isNotEmpty) a.observacao,
          ].join('\n'),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => abrirAnexo(context, a.referencia),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: 110,
                child: ImagemAnexo(
                  a.referencia,
                  alternativa: ColoredBox(
                    color: AppColors.navy,
                    child: Icon(
                      Icons.play_circle_outline,
                      color: AppColors.gold,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _chamado(Manutencao m) => CardPadrao(
    onTap: () => _abrirChamado(m),
    child: Row(
      children: [
        Icon(Icons.handyman_outlined, color: AppColors.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.tipoLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                m.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${m.origem.label} • ${formatDate(m.criadaEm)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        GoldChip(m.status.label),
      ],
    ),
  );

  Widget _comunicado(ComunicadoInquilino c) => CardPadrao(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          c.automatico ? Icons.smart_toy_outlined : Icons.campaign_outlined,
          color: AppColors.gold,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.titulo,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(c.mensagem, style: const TextStyle(color: Colors.white70)),
              Text(
                [
                  formatDateTime(c.criadoEm),
                  if (c.contratoId == null) 'para todos',
                  if (c.automatico) 'automático',
                  c.leituras > 0 ? 'lido' : 'não lido',
                ].join(' • '),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        if (c.contratoId != null)
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirmDelete(
                context,
                'Excluir o aviso "${c.titulo}"?',
              )) {
                await _resultado(_vm.removerComunicado(c), 'Aviso excluído.');
              }
            },
          ),
      ],
    ),
  );
}
