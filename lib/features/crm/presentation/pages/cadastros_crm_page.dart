import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/central_tab.dart';
import '../widgets/contatos_tab.dart';
import '../widgets/cruzamento_tab.dart';
import '../widgets/imoveis_tab.dart';

/// Módulo "Cadastros e CRM": imóveis, contatos, cruzamento de perfil e
/// central de relacionamento.
class CadastrosCrmPage extends StatelessWidget {
  const CadastrosCrmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
                Tab(icon: Icon(Icons.apartment), text: 'Imóveis'),
                Tab(
                  icon: Icon(Icons.contacts_outlined),
                  text: 'Contatos (CRM)',
                ),
                Tab(
                  icon: Icon(Icons.auto_awesome),
                  text: 'Cruzamento de perfil',
                ),
                Tab(
                  icon: Icon(Icons.event_note_outlined),
                  text: 'Central de Relacionamento',
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ImoveisTab(),
                ContatosTab(),
                CruzamentoTab(),
                CentralTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
