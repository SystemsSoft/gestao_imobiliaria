import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../contratos/domain/entities/modelo_contrato.dart';
import '../../../contratos/presentation/widgets/modelos_tab.dart';
import '../../../temporada/presentation/pages/temporada_page.dart';
import '../widgets/cobrancas_tab.dart';
import '../widgets/contratos_tab.dart';
import '../widgets/despesas_tab.dart';
import '../widgets/imposto_renda_tab.dart';
import '../widgets/repasses_tab.dart';

/// Módulo "Administração de Locação".
class AdministracaoLocacaoPage extends StatelessWidget {
  const AdministracaoLocacaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
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
                Tab(icon: Icon(Icons.handshake_outlined), text: 'Contratos'),
                Tab(
                  icon: Icon(Icons.receipt_outlined),
                  text: 'Boletos e recibos',
                ),
                Tab(icon: Icon(Icons.payments_outlined), text: 'Despesas'),
                Tab(
                  icon: Icon(Icons.account_balance_outlined),
                  text: 'Repasses',
                ),
                Tab(
                  icon: Icon(Icons.calculate_outlined),
                  text: 'Imposto de Renda',
                ),
                Tab(icon: Icon(Icons.beach_access_outlined), text: 'Temporada'),
                Tab(
                  icon: Icon(Icons.article_outlined),
                  text: 'Modelos de contrato',
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ContratosTab(),
                CobrancasTab(),
                DespesasTab(),
                RepassesTab(),
                ImpostoRendaTab(),
                TemporadaPage(),
                ModelosTab(tipo: TipoModelo.locacao),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
