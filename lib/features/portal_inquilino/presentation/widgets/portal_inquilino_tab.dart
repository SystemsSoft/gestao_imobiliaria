import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../domain/entities/portal.dart';
import '../pages/portal_contrato_page.dart';
import '../viewmodels/portal_viewmodels.dart';
import 'portal_dialogs.dart';

/// Situação do acesso (rótulo e cor) para listas e cabeçalhos.
(String, Color) situacaoAcesso(AcessoInquilino? a) => switch (a) {
  null => ('Sem acesso', Colors.white54),
  AcessoInquilino(ativo: false) => ('Desativado', Colors.grey),
  AcessoInquilino(bloqueado: true) => (
    'Bloqueado (tentativas)',
    Colors.redAccent,
  ),
  AcessoInquilino(trocarSenha: true) => (
    'Senha provisória',
    Colors.orangeAccent,
  ),
  _ => ('Acesso ativo', Colors.greenAccent),
};

/// Locação › Portal do inquilino: quem tem acesso à Área do inquilino do site.
class PortalInquilinoTab extends StatefulWidget {
  const PortalInquilinoTab({super.key});

  @override
  State<PortalInquilinoTab> createState() => _PortalInquilinoTabState();
}

class _PortalInquilinoTabState extends State<PortalInquilinoTab> {
  final _vm = sl<PortalInquilinoViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _avisoGeral() async {
    final aviso = await pedirComunicado(
      context,
      titulo: 'Aviso para todos os inquilinos',
    );
    if (aviso == null) return;
    final ok = await _vm.comunicadoGeral(aviso.titulo, aviso.mensagem);
    if (mounted) {
      mostrarMensagem(
        context,
        ok ? 'Aviso publicado no portal.' : (_vm.erro ?? 'Erro.'),
      );
    }
  }

  Future<void> _abrir(ContratoNoPortal l) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PortalContratoPage(
          contrato: l.contrato,
          locatario: l.locatario,
          imovel: l.imovel,
        ),
      ),
    );
    await _vm.recarregarAcessos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.campaign_outlined,
        label: 'Aviso para todos',
        onPressed: _avisoGeral,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final linhas = _vm.linhas;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: CampoBusca(
                  hint: 'Buscar por contrato, inquilino ou imóvel...',
                  onChanged: _vm.buscar,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_vm.comAcesso} inquilino(s) com acesso. '
                        'Boletos, pagamentos, chamados e avisos já vêm do sistema; '
                        'publique aqui o contrato e o laudo de vistoria.',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Text('Encerrados', style: TextStyle(fontSize: 13)),
                    Switch(
                      value: !_vm.somenteAtivos,
                      activeThumbColor: AppColors.gold,
                      onChanged: _vm.mostrarEncerrados,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: !_vm.carregado
                    ? const SizedBox.shrink()
                    : linhas.isEmpty
                    ? const EmptyState(
                        icon: Icons.key_outlined,
                        message: 'Nenhum contrato de locação.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 96),
                        itemCount: linhas.length,
                        itemBuilder: (_, i) => _card(linhas[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(ContratoNoPortal l) {
    final (rotulo, cor) = situacaoAcesso(l.acesso);
    return CardPadrao(
      onTap: () => _abrir(l),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cor.withValues(alpha: 0.15),
            child: Icon(Icons.person_outline, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.locatario?.nome ?? 'Locatário não encontrado',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${l.contrato.numero} • ${l.imovel?.titulo ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (l.acesso?.ultimoAcesso != null)
                  Text(
                    'Último acesso: ${formatDateTime(l.acesso!.ultimoAcesso)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
              ],
            ),
          ),
          GoldChip(rotulo, color: cor),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }
}
