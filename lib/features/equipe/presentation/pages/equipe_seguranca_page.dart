import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/atividades_tab.dart';
import '../widgets/chat_tab.dart';
import '../widgets/comissoes_equipe_tab.dart';
import '../widgets/fila_tab.dart';
import '../widgets/permissoes_tab.dart';
import '../widgets/usuarios_tab.dart';

/// Módulo "Equipe e Segurança". Sem a permissão do módulo, o usuário
/// (ex.: corretor) vê só a fila de atendimento e o chat interno.
class EquipeSegurancaPage extends StatelessWidget {
  const EquipeSegurancaPage({
    super.key,
    this.abaInicial = 0,
    this.completo = true,
  });

  /// Índice na lista completa de abas.
  final int abaInicial;
  final bool completo;

  static const _abas = <(Tab, Widget, bool)>[
    (
      Tab(icon: Icon(Icons.groups_outlined), text: 'Usuários e sessões'),
      UsuariosTab(),
      false,
    ),
    (
      Tab(icon: Icon(Icons.lock_person_outlined), text: 'Permissões'),
      PermissoesTab(),
      false,
    ),
    (
      Tab(icon: Icon(Icons.history), text: 'Atividades'),
      AtividadesTab(),
      false,
    ),
    (
      Tab(icon: Icon(Icons.support_agent), text: 'Fila de atendimento'),
      FilaTab(),
      true,
    ),
    (
      Tab(icon: Icon(Icons.percent), text: 'Comissões'),
      ComissoesEquipeTab(),
      false,
    ),
    (
      Tab(icon: Icon(Icons.forum_outlined), text: 'Chat interno'),
      ChatTab(),
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final abas = [
      for (final a in _abas)
        if (completo || a.$3) a,
    ];
    final inicial = abas.indexOf(_abas[abaInicial.clamp(0, _abas.length - 1)]);
    return DefaultTabController(
      initialIndex: inicial < 0 ? 0 : inicial,
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
              tabs: [for (final a in abas) a.$1],
            ),
          ),
          Expanded(child: TabBarView(children: [for (final a in abas) a.$2])),
        ],
      ),
    );
  }
}
