import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/dimob_tab.dart';
import '../widgets/ir_fiscal_tab.dart';

/// Módulo "Fiscal": DIMOB e cálculo do Imposto de Renda.
class FiscalPage extends StatelessWidget {
  const FiscalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
                Tab(icon: Icon(Icons.assignment_outlined), text: 'DIMOB'),
                Tab(
                  icon: Icon(Icons.calculate_outlined),
                  text: 'Cálculo de Imposto de Renda',
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [DimobTab(), IrFiscalTab()]),
          ),
        ],
      ),
    );
  }
}
