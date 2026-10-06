import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'central_tab.dart';
import 'contatos_tab.dart';
import 'cruzamento_tab.dart';
import 'imoveis_tab.dart';

/// Módulo "Cadastros e CRM": imóveis, contatos, cruzamento de perfil e
/// central de relacionamento.
class CadastrosCrmScreen extends StatelessWidget {
  const CadastrosCrmScreen({super.key});

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
