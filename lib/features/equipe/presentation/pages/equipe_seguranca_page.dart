import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/atividades_tab.dart';
import '../widgets/chat_tab.dart';
import '../widgets/comissoes_equipe_tab.dart';
import '../widgets/fila_tab.dart';
import '../widgets/permissoes_tab.dart';
import '../widgets/usuarios_tab.dart';

/// Módulo "Equipe e Segurança".
class EquipeSegurancaPage extends StatelessWidget {
  const EquipeSegurancaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
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
              tabs: const [
                Tab(
                  icon: Icon(Icons.groups_outlined),
                  text: 'Usuários e sessões',
                ),
                Tab(icon: Icon(Icons.lock_person_outlined), text: 'Permissões'),
                Tab(icon: Icon(Icons.history), text: 'Atividades'),
                Tab(
                  icon: Icon(Icons.support_agent),
                  text: 'Fila de atendimento',
                ),
                Tab(icon: Icon(Icons.percent), text: 'Comissões'),
                Tab(icon: Icon(Icons.forum_outlined), text: 'Chat interno'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                UsuariosTab(),
                PermissoesTab(),
                AtividadesTab(),
                FilaTab(),
                ComissoesEquipeTab(),
                ChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
