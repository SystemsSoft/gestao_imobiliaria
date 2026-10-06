import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _MenuItem {
  const _MenuItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _menuItems = [
  _MenuItem('Cadastros e CRM', Icons.contacts_outlined),
  _MenuItem('Administração de Locação', Icons.key_outlined),
  _MenuItem('Administração de Vendas', Icons.sell_outlined),
  _MenuItem('Financeiro', Icons.account_balance_wallet_outlined),
  _MenuItem('Fiscal', Icons.receipt_long_outlined),
  _MenuItem('Contratos e Relatórios', Icons.description_outlined),
  _MenuItem('Equipe e Segurança', Icons.admin_panel_settings_outlined),
  _MenuItem('Personalização', Icons.palette_outlined),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final item = _menuItems[_selected];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text(item.label),
      ),
      drawer: _buildDrawer(context),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 64, color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              item.label,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.navyDark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/logo_marcelo_bonifacio.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Divider(color: AppColors.gold.withValues(alpha: 0.3)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (var i = 0; i < _menuItems.length; i++)
                    ListTile(
                      leading: Icon(_menuItems[i].icon),
                      title: Text(_menuItems[i].label),
                      selected: i == _selected,
                      selectedColor: AppColors.gold,
                      selectedTileColor: AppColors.gold.withValues(alpha: 0.12),
                      iconColor: Colors.white70,
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        setState(() => _selected = i);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
