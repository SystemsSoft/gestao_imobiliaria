import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/api/sessao_api.dart';
import '../../../../core/di/injector.dart';
import '../../../auth/presentation/widgets/alterar_senha_dialog.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../viewmodels/home_viewmodel.dart';

/// Barra superior da área logada: menu, busca, avisos, data e usuário.
class CabecalhoModulo extends StatelessWidget {
  const CabecalhoModulo({
    super.key,
    required this.vm,
    required this.onMenu,
    required this.onSair,
    required this.onBuscar,
    this.modulo,
    this.onBaixarDesktop,
  });

  final HomeViewModel vm;
  final VoidCallback onMenu;
  final VoidCallback onSair;
  final ValueChanged<String> onBuscar;

  /// No celular, o nome do módulo aberto fica na própria barra (economiza
  /// a faixa de título).
  final ModuloMenu? modulo;

  /// Botão "Baixar para desktop" (só no computador, fora do app instalado).
  final VoidCallback? onBaixarDesktop;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final estreito = largura < 760;
    return Container(
      height: estreito ? 64 : 76,
      padding: EdgeInsets.symmetric(horizontal: estreito ? 6 : 20),
      decoration: BoxDecoration(
        color: AppColors.navyDark.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            onPressed: onMenu,
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
          if (estreito) ...[
            const SizedBox(width: 4),
            if (modulo case final m? when m != ModuloMenu.dashboard) ...[
              Icon(m.icon, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  m.curto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estiloTitulo(tamanho: 19),
                ),
              ),
            ] else ...[
              Image.asset('assets/logo_icone.png', height: 38),
              const Spacer(),
            ],
          ] else ...[
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _Busca(onBuscar: onBuscar),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (onBaixarDesktop case final baixar?) ...[
            _BotaoBaixar(comTexto: largura >= 1500, onTap: baixar),
            const SizedBox(width: 8),
          ],
          _Avisos(vm: vm),
          if (largura >= 1000) ...[
            const SizedBox(width: 18),
            _DataHora(agora: vm.agora),
          ],
          SizedBox(width: estreito ? 4 : 22),
          _Usuario(vm: vm, compacto: estreito, onSair: onSair),
        ],
      ),
    );
  }
}

/// Busca global (por enquanto leva à listagem de cadastros).
class _Busca extends StatelessWidget {
  const _Busca({required this.onBuscar});

  final ValueChanged<String> onBuscar;

  @override
  Widget build(BuildContext context) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
    );
    return SizedBox(
      height: 44,
      child: TextField(
        onSubmitted: onBuscar,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar imóveis, clientes, contratos...',
          hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: AppColors.navyDark.withValues(alpha: 0.5),
          contentPadding: EdgeInsets.zero,
          border: borda,
          enabledBorder: borda,
          focusedBorder: borda.copyWith(
            borderSide: const BorderSide(color: AppColors.gold),
          ),
        ),
      ),
    );
  }
}

/// Data por extenso e hora atual, atualizadas a cada minuto.
class _DataHora extends StatefulWidget {
  const _DataHora({required this.agora});

  final DateTime agora;

  @override
  State<_DataHora> createState() => _DataHoraState();
}

class _DataHoraState extends State<_DataHora> {
  late DateTime _agora = widget.agora;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() => _agora = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hora =
        '${_agora.hour.toString().padLeft(2, '0')}:${_agora.minute.toString().padLeft(2, '0')}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 24,
          color: Colors.white,
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dataPorExtensoCurta(_agora),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              hora,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
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
            const Icon(Icons.notifications_none, size: 28, color: Colors.white),
            if (pendentes.isNotEmpty)
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.navyDark, width: 1.5),
                  ),
                  child: Text(
                    pendentes.length > 9 ? '9+' : '${pendentes.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
      onSelected: (v) => switch (v) {
        'sair' => onSair(),
        'senha' => mostrarAlterarSenhaDialog(context),
        _ => vm.selecionar(ModuloMenu.equipeSeguranca),
      },
      itemBuilder: (_) => [
        if (sl.isRegistered<SessaoApi>())
          const PopupMenuItem(
            value: 'senha',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.key_outlined),
              title: Text('Alterar senha'),
            ),
          ),
        if (vm.modulosPermitidos.contains(ModuloMenu.equipeSeguranca))
          const PopupMenuItem(
            value: 'equipe',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.admin_panel_settings_outlined),
              title: Text('Equipe e Segurança'),
            ),
          ),
        const PopupMenuItem(
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
            width: 42,
            height: 42,
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

/// Atalho para instalar o app no computador.
class _BotaoBaixar extends StatelessWidget {
  const _BotaoBaixar({required this.comTexto, required this.onTap});

  final bool comTexto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!comTexto) {
      return IconButton(
        tooltip: 'Baixar para desktop',
        onPressed: onTap,
        icon: const Icon(Icons.install_desktop, color: AppColors.gold),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      icon: const Icon(Icons.install_desktop, size: 20),
      label: const Text('Baixar para desktop'),
    );
  }
}
