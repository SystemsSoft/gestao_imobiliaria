import 'package:flutter/material.dart';

import '../../../../core/config/empresa_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../viewmodels/home_viewmodel.dart';

/// Cabeçalho da área logada: marca, módulo atual, avisos e usuário.
class CabecalhoModulo extends StatelessWidget {
  const CabecalhoModulo({
    super.key,
    required this.vm,
    required this.onMenu,
    required this.onSair,
  });

  final HomeViewModel vm;
  final VoidCallback onMenu;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final estreito = largura < 760;
    final modulo = vm.selecionado;
    return Container(
      height: estreito ? 76 : 112,
      padding: EdgeInsets.symmetric(horizontal: estreito ? 8 : 28),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            onPressed: onMenu,
            icon: const Icon(Icons.menu, color: Colors.white70),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onMenu,
            child: _Marca(compacta: largura < 1000),
          ),
          if (!estreito) ...[
            const SizedBox(width: 28),
            Container(
              width: 1,
              height: 48,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            const SizedBox(width: 28),
          ] else
            const SizedBox(width: 10),
          if (largura >= 520) ...[
            Container(
              width: estreito ? 38 : 50,
              height: estreito ? 38 : 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                color: Colors.white.withValues(alpha: 0.04),
              ),
              child: Icon(
                modulo.icon,
                color: AppColors.gold,
                size: estreito ? 20 : 26,
              ),
            ),
            SizedBox(width: estreito ? 10 : 18),
          ],
          Expanded(
            child: Text(
              modulo.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: estiloTitulo(
                tamanho: largura < 420 ? 17 : (estreito ? 20 : 30),
              ),
            ),
          ),
          _Avisos(vm: vm),
          SizedBox(width: estreito ? 4 : 20),
          _Usuario(vm: vm, compacto: estreito, onSair: onSair),
        ],
      ),
    );
  }
}

/// Ícone da logo + nome, atividade e CRECI.
class _Marca extends StatelessWidget {
  const _Marca({required this.compacta});

  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final icone = Image.asset(
      'assets/logo_icone.png',
      height: compacta ? 40 : 58,
    );
    if (compacta) return icone;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icone,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              EmpresaInfo.nome.toUpperCase(),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              EmpresaInfo.atividade.toUpperCase(),
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              EmpresaInfo.creci.toUpperCase(),
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sino com os compromissos atrasados ou de hoje da Central de Relacionamento.
class _Avisos extends StatelessWidget {
  const _Avisos({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final pendentes = vm.pendentes;
    return PopupMenuButton<int>(
      tooltip: pendentes.isEmpty
          ? 'Sem pendências na agenda'
          : '${pendentes.length} pendência(s) na agenda',
      color: AppColors.navy,
      offset: const Offset(0, 48),
      onSelected: (_) => vm.abrirCentral(),
      itemBuilder: (_) => [
        if (pendentes.isEmpty)
          const PopupMenuItem(
            enabled: false,
            child: Text('Nenhum compromisso atrasado ou para hoje.'),
          ),
        for (final e in pendentes.take(6))
          PopupMenuItem(
            value: 0,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.event_note_outlined,
                color: AppColors.gold,
              ),
              title: Text(
                e.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(formatDateTime(e.dataHora)),
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 0,
          child: Text(
            'Abrir Central de Relacionamento',
            style: TextStyle(color: AppColors.gold),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none, size: 30, color: Colors.white),
            if (pendentes.isNotEmpty)
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.navyDark, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Usuário atual (de Equipe e Segurança) com o menu de conta.
class _Usuario extends StatelessWidget {
  const _Usuario({
    required this.vm,
    required this.compacto,
    required this.onSair,
  });

  final HomeViewModel vm;
  final bool compacto;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
    final u = vm.usuario;
    return PopupMenuButton<String>(
      tooltip: 'Conta',
      color: AppColors.navy,
      offset: const Offset(0, 56),
      onSelected: (v) =>
          v == 'sair' ? onSair() : vm.selecionar(ModuloMenu.equipeSeguranca),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'equipe',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.admin_panel_settings_outlined),
            title: Text('Equipe e Segurança'),
          ),
        ),
        PopupMenuItem(
          value: 'sair',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Sair'),
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          if (!compacto) ...[
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u?.nome ?? 'Usuário',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  u?.perfil.label ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}
