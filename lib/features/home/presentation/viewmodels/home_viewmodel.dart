import 'package:flutter/material.dart';

import '../../../../core/presentation/view_model.dart';

enum ModuloMenu {
  cadastrosCrm('Cadastros e CRM', Icons.contacts_outlined),
  locacao('Administração de Locação', Icons.key_outlined),
  vendas('Administração de Vendas', Icons.sell_outlined),
  financeiro('Financeiro', Icons.account_balance_wallet_outlined),
  fiscal('Fiscal', Icons.receipt_long_outlined),
  contratosRelatorios('Contratos e Relatórios', Icons.description_outlined),
  equipeSeguranca('Equipe e Segurança', Icons.admin_panel_settings_outlined),
  personalizacao('Personalização', Icons.palette_outlined);

  const ModuloMenu(this.label, this.icon);
  final String label;
  final IconData icon;
}

class HomeViewModel extends ViewModel {
  ModuloMenu selecionado = ModuloMenu.cadastrosCrm;

  void selecionar(ModuloMenu modulo) {
    selecionado = modulo;
    notificar();
  }
}
