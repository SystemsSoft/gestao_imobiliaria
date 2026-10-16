import 'package:flutter/material.dart';

import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/evento.dart';
import '../../../crm/domain/usecases/evento_usecases.dart';
import '../../../equipe/domain/entities/equipe_enums.dart';
import '../../../equipe/domain/entities/usuario_sistema.dart';
import '../../../equipe/domain/usecases/usuario_usecases.dart';

enum ModuloMenu {
  dashboard('Dashboard', Icons.home_outlined),
  cadastrosCrm('Cadastros e CRM', Icons.person_outline),
  locacao('Administração de Locação', Icons.key_outlined),
  vendas('Administração de Vendas', Icons.sell_outlined),
  temporada('Locação por Temporada', Icons.calendar_month_outlined),
  financeiro('Financeiro', Icons.attach_money),
  fiscal('Fiscal', Icons.receipt_long_outlined),
  contratosRelatorios('Contratos e Relatórios', Icons.description_outlined),
  equipeSeguranca('Equipe e Segurança', Icons.shield_outlined),
  site('Site e Leads', Icons.language),
  personalizacao('Personalização', Icons.settings_outlined);

  const ModuloMenu(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Índice da aba "Central de Relacionamento" em Cadastros e CRM.
const abaCentralRelacionamento = 3;

class HomeViewModel extends ViewModel {
  HomeViewModel(
    ObservarEventos observarEventos,
    ObservarUsuarios observarUsuarios,
    ObservarUsuarioAtual observarAtual, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    observar(observarEventos(), (l) => _eventos = l);
    observar(observarUsuarios(), (l) => _usuarios = l);
    observar(observarAtual(), (id) => _usuarioAtualId = id);
  }

  final DateTime Function() _agora;

  DateTime get agora => _agora();
  List<Evento> _eventos = const [];
  List<UsuarioSistema> _usuarios = const [];
  String? _usuarioAtualId;

  ModuloMenu selecionado = ModuloMenu.dashboard;

  /// Aba inicial do módulo aberto e um contador para recriá-lo ao trocar.
  int abaInicial = 0;
  int versao = 0;

  UsuarioSistema? get usuario =>
      _usuarios.where((u) => u.id == _usuarioAtualId).firstOrNull;

  /// Módulos do menu que o usuário pode ver (o servidor também confere).
  List<ModuloMenu> get modulosPermitidos {
    final p = usuario?.permissoes;
    if (p == null) return ModuloMenu.values;
    return ModuloMenu.values.where((m) {
      final s = _permissaoDo(m);
      return s == null || p.pode(s, AcaoPermissao.visualizar);
    }).toList();
  }

  /// Usuários, permissões, atividades e comissões da equipe.
  bool get equipeCompleta =>
      usuario?.permissoes.pode(
        ModuloSistema.equipeSeguranca,
        AcaoPermissao.visualizar,
      ) ??
      true;

  /// Permissão que libera o item do menu (null = sempre visível).
  static ModuloSistema? _permissaoDo(ModuloMenu m) => switch (m) {
    ModuloMenu.dashboard => null,
    ModuloMenu.cadastrosCrm => ModuloSistema.cadastrosCrm,
    // Temporada usa a permissão de Locação.
    ModuloMenu.locacao || ModuloMenu.temporada => ModuloSistema.locacao,
    ModuloMenu.vendas => ModuloSistema.vendas,
    ModuloMenu.financeiro => ModuloSistema.financeiro,
    ModuloMenu.fiscal => ModuloSistema.fiscal,
    ModuloMenu.contratosRelatorios => ModuloSistema.contratosRelatorios,
    // Todos usam a fila e o chat; o restante depende da permissão.
    ModuloMenu.equipeSeguranca => null,
    ModuloMenu.personalizacao => ModuloSistema.personalizacao,
    ModuloMenu.site => ModuloSistema.site,
  };

  /// Compromissos da agenda atrasados ou de hoje, ainda não concluídos.
  List<Evento> get pendentes {
    final h = _agora();
    final fimHoje = DateTime(h.year, h.month, h.day + 1);
    return _eventos
        .where(
          (e) =>
              !e.concluido &&
              e.dataHora != null &&
              e.dataHora!.isBefore(fimHoje),
        )
        .toList()
      ..sort((a, b) => a.dataHora!.compareTo(b.dataHora!));
  }

  void selecionar(ModuloMenu modulo, {int aba = 0}) {
    selecionado = modulo;
    abaInicial = aba;
    versao++;
    notificar();
  }

  void abrirCentral() =>
      selecionar(ModuloMenu.cadastrosCrm, aba: abaCentralRelacionamento);
}
