import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../domain/entities/auditoria.dart';
import '../../domain/repositories/auditoria_repository.dart';
import '../../domain/usecases/auditoria_usecases.dart';
import '../widgets/auditorias_tab.dart';
import '../widgets/configuracao_auditoria_tab.dart';
import '../widgets/pendencias_tab.dart';
import '../widgets/proprietarios_auditoria_tab.dart';
import 'auditoria_page.dart';

/// Módulo "Auditorias": acompanhamento dos imóveis administrados para os
/// proprietários (pendências automáticas, vistorias em campo com fotos e
/// vídeos transcritos, saúde da carteira e Área do proprietário no site).
class AuditoriasPage extends StatelessWidget {
  const AuditoriasPage({super.key, this.abaInicial = 0});

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
              (Icons.notification_important_outlined, 'Pendências'),
              (Icons.fact_check_outlined, 'Auditorias'),
              (Icons.supervisor_account_outlined, 'Proprietários'),
              (Icons.tune, 'Configurações'),
            ],
          ),
          Expanded(
            child: PainelConteudo(
              child: TabBarView(
                children: [
                  PendenciasTab(),
                  AuditoriasTab(),
                  ProprietariosAuditoriaTab(),
                  ConfiguracaoAuditoriaTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre uma nova auditoria com o checklist do modelo padrão.
Future<void> abrirNovaAuditoria(
  BuildContext context, {
  String imovelId = '',
  String? contratoId,
  TipoAuditoria tipo = TipoAuditoria.periodica,
}) async {
  List<ModeloChecklist> modelos = const [];
  try {
    modelos = await sl<AuditoriaRepository>().modelos();
  } on Exception {
    // Sem modelos: começa com o checklist vazio.
  }
  if (!context.mounted) return;
  final modelo =
      modelos.where((m) => m.padrao).firstOrNull ?? modelos.firstOrNull;
  await abrirAuditoria(
    context,
    novaAuditoria(
      imovelId: imovelId,
      contratoId: contratoId,
      modelo: modelo,
      tipo: tipo,
      dataAgendada: DateTime.now(),
    ),
    modelos: modelos,
  );
}

Future<void> abrirAuditoria(
  BuildContext context,
  Auditoria a, {
  List<ModeloChecklist> modelos = const [],
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => AuditoriaPage(auditoria: a, modelos: modelos),
  ),
);
