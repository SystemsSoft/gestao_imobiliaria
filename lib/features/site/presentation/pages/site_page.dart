import 'package:flutter/material.dart';

import '../../../../core/widgets/visual_marca.dart';
import '../widgets/configuracao_site_tab.dart';
import '../widgets/imoveis_site_tab.dart';
import '../widgets/leads_tab.dart';

/// Módulo "Site e Leads": pedidos de contato do site, imóveis publicados e
/// configurações do site público hospedado no servidor.
class SitePage extends StatelessWidget {
  const SitePage({super.key, this.abaInicial = 0});

  final int abaInicial;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: abaInicial,
      child: const Column(
        children: [
          AbasModulo(
            abas: [
              (Icons.mark_email_unread_outlined, 'Leads'),
              (Icons.home_work_outlined, 'Imóveis no site'),
              (Icons.tune, 'Configurações do site'),
            ],
          ),
          Expanded(
            child: PainelConteudo(
              child: TabBarView(
                children: [LeadsTab(), ImoveisSiteTab(), ConfiguracaoSiteTab()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
