import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../domain/entities/lead_site.dart';
import '../viewmodels/site_viewmodels.dart';

Color corStatusLead(StatusLead s) => switch (s) {
  StatusLead.novo => AppColors.gold,
  StatusLead.emAtendimento => AppColors.blueGlow,
  StatusLead.convertido => Colors.greenAccent,
  StatusLead.descartado => Colors.grey,
};

IconData iconeTipoLead(TipoLead t) => switch (t) {
  TipoLead.interesse => Icons.favorite_border,
  TipoLead.visita => Icons.event_available_outlined,
  TipoLead.contato => Icons.chat_bubble_outline,
  TipoLead.anunciar => Icons.campaign_outlined,
};

/// Leads que chegaram pelo site. Cada um já virou contato no CRM e tarefa
/// na Central de Relacionamento (e atendimento na fila, se configurado).
class LeadsTab extends StatefulWidget {
  const LeadsTab({super.key});

  @override
  State<LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<LeadsTab> {
  final _vm = sl<LeadsViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _resultado(Future<bool> acao, String sucesso) async {
    final ok = await acao;
    if (mounted) mostrarMensagem(context, ok ? sucesso : (_vm.erro ?? 'Erro.'));
  }

  Future<void> _abrir(Uri uri) async {
    if (!await launchUrl(uri, webOnlyWindowName: '_blank') && mounted) {
      mostrarMensagem(context, 'Não foi possível abrir.');
    }
  }

  Future<void> _anotar(LeadSite l) async {
    final ctrl = TextEditingController(text: l.observacao);
    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: Text('Anotação – ${l.nome}'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: ctrl,
            maxLines: 5,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ex.: Liguei, visita marcada para sábado.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (texto != null) {
      await _resultado(_vm.anotar(l, texto), 'Anotação salva.');
    }
  }

  Future<void> _excluir(LeadSite l) async {
    if (await confirmDelete(
      context,
      'Excluir o lead de ${l.nome}? O contato e a tarefa no CRM continuam.',
    )) {
      await _resultado(_vm.remover(l.id), 'Lead excluído.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final lista = _vm.filtrados;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: CampoBusca(
                hint: 'Buscar por nome, telefone, e-mail ou imóvel...',
                onChanged: _vm.buscar,
              ),
            ),
            FiltroChips<StatusLead>(
              opcoes: StatusLead.values,
              selecionado: _vm.status,
              labelOf: (s) => '${s.label} (${_vm.contar(s)})',
              onChanged: _vm.filtrar,
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            Expanded(
              child: !_vm.carregado
                  ? const SizedBox.shrink()
                  : lista.isEmpty
                  ? EmptyState(
                      icon: Icons.mark_email_unread_outlined,
                      message: _vm.semLeads
                          ? 'Nenhum lead ainda.\nOs pedidos de contato do site aparecem aqui.'
                          : 'Nenhum lead com esse filtro.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: lista.length,
                      itemBuilder: (_, i) => _card(lista[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(LeadSite l) {
    final imovel = _vm.imovel(l.imovelId);
    final responsavel = _vm.usuario(l.corretorId);
    final digitos = l.telefone.replaceAll(RegExp(r'\D'), '');
    return CardPadrao(
      borda: corStatusLead(l.status),
      onTap: () => _anotar(l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconeTipoLead(l.tipo), color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              GoldChip(l.status.label, color: corStatusLead(l.status)),
              _menu(l),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              l.tipo.label,
              formatDateTime(l.criadoEm),
              if (imovel != null) '${imovel.codigo} – ${imovel.titulo}',
            ].join(' • '),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (l.dataVisita != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Visita desejada: ${formatDateTime(l.dataVisita)}',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (l.mensagem.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.mensagem,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (l.observacao.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Anotação: ${l.observacao}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (digitos.length >= 10) ...[
                _acao(
                  Icons.chat_outlined,
                  'WhatsApp',
                  () => _abrir(
                    Uri.parse(
                      'https://wa.me/55$digitos?text=${Uri.encodeComponent('Olá, ${l.nome.split(' ').first}! Recebemos seu contato pelo site.')}',
                    ),
                  ),
                ),
                _acao(
                  Icons.phone_outlined,
                  l.telefone,
                  () => _abrir(Uri(scheme: 'tel', path: digitos)),
                ),
              ],
              if (l.email.isNotEmpty)
                _acao(
                  Icons.mail_outline,
                  l.email,
                  () => _abrir(Uri(scheme: 'mailto', path: l.email)),
                ),
              _responsavel(l, responsavel?.nome),
            ],
          ),
        ],
      ),
    );
  }

  Widget _acao(IconData icone, String texto, VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icone, size: 18),
        label: Text(texto),
        style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
      );

  /// '' = sem responsável (null no menu equivale a fechar sem escolher).
  Widget _responsavel(LeadSite l, String? nome) => PopupMenuButton<String>(
    tooltip: 'Encaminhar',
    color: AppColors.navy,
    onSelected: (id) => _resultado(
      _vm.atribuir(l, id.isEmpty ? null : id),
      id.isEmpty ? 'Lead sem responsável.' : 'Lead encaminhado.',
    ),
    itemBuilder: (_) => [
      for (final u in _vm.responsaveis)
        PopupMenuItem(
          value: u.id,
          child: Text('${u.nome} (${u.perfil.label})'),
        ),
      if (l.corretorId != null)
        const PopupMenuItem(value: '', child: Text('Sem responsável')),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 18, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            nome ?? 'Encaminhar...',
            style: TextStyle(
              color: nome == null ? AppColors.gold : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.white54),
        ],
      ),
    ),
  );

  Widget _menu(LeadSite l) => PopupMenuButton<Object>(
    color: AppColors.navy,
    onSelected: (v) {
      if (v is StatusLead) {
        _resultado(_vm.mudarStatus(l, v), 'Lead: ${v.label.toLowerCase()}.');
      } else if (v == 'anotar') {
        _anotar(l);
      } else if (v == 'excluir') {
        _excluir(l);
      }
    },
    itemBuilder: (_) => [
      for (final s in StatusLead.values)
        if (s != l.status)
          PopupMenuItem(value: s, child: Text('Marcar como "${s.label}"')),
      const PopupMenuDivider(),
      const PopupMenuItem(value: 'anotar', child: Text('Anotação')),
      const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
    ],
  );
}
