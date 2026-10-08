import 'package:flutter/material.dart';

import '../../../../core/widgets/visual_marca.dart';
import '../widgets/central_tab.dart';
import '../widgets/contatos_tab.dart';
import '../widgets/cruzamento_tab.dart';
import '../widgets/imoveis_tab.dart';

/// Módulo "Cadastros e CRM": imóveis, contatos, cruzamento de perfil e
/// central de relacionamento.
class CadastrosCrmPage extends StatelessWidget {
  const CadastrosCrmPage({super.key, this.abaInicial = 0});

  final int abaInicial;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: abaInicial,
      child: const Column(
        children: [
          AbasModulo(
            abas: [
              (Icons.home_outlined, 'Imóveis'),
              (Icons.person_outline, 'Contatos (CRM)'),
              (Icons.auto_awesome_outlined, 'Cruzamento de perfil'),
              (Icons.event_note_outlined, 'Central de Relacionamento'),
            ],
          ),
          Expanded(
            child: PainelConteudo(
              child: TabBarView(
                children: [
                  ImoveisTab(),
                  ContatosTab(),
                  CruzamentoTab(),
                  CentralTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
