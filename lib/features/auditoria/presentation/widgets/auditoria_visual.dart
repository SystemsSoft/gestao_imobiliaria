import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auditoria.dart';

extension EstadoItemVisual on EstadoItem {
  Color get cor => switch (this) {
    EstadoItem.pendente => Colors.white38,
    EstadoItem.ok => Colors.greenAccent,
    EstadoItem.atencao => Colors.orangeAccent,
    EstadoItem.problema => Colors.redAccent,
    EstadoItem.naoAplica => Colors.grey,
  };

  IconData get icone => switch (this) {
    EstadoItem.pendente => Icons.radio_button_unchecked,
    EstadoItem.ok => Icons.check_circle_outline,
    EstadoItem.atencao => Icons.error_outline,
    EstadoItem.problema => Icons.cancel_outlined,
    EstadoItem.naoAplica => Icons.remove_circle_outline,
  };
}

extension GravidadeVisual on Gravidade {
  Color get cor => switch (this) {
    Gravidade.critica => Colors.redAccent,
    Gravidade.atencao => Colors.orangeAccent,
    Gravidade.info => Colors.lightBlueAccent,
  };
}

extension AreaPendenciaVisual on AreaPendencia {
  IconData get icone => switch (this) {
    AreaPendencia.financeiro => Icons.attach_money,
    AreaPendencia.contrato => Icons.description_outlined,
    AreaPendencia.imovel => Icons.home_work_outlined,
    AreaPendencia.documentos => Icons.folder_open,
    AreaPendencia.cadastro => Icons.person_outline,
  };
}

extension SaudeVisual on Saude {
  Color get cor => switch (this) {
    Saude.verde => Colors.greenAccent,
    Saude.amarelo => Colors.orangeAccent,
    Saude.vermelho => Colors.redAccent,
  };
}

extension StatusAuditoriaVisual on StatusAuditoria {
  Color get cor => switch (this) {
    StatusAuditoria.agendada => Colors.lightBlueAccent,
    StatusAuditoria.emAndamento => Colors.orangeAccent,
    StatusAuditoria.concluida => Colors.greenAccent,
    StatusAuditoria.cancelada => Colors.grey,
  };
}

/// Situação do acesso do proprietário (rótulo e cor).
(String, Color) situacaoAcessoProprietario(AcessoProprietario? a) =>
    switch (a) {
      null => ('Sem acesso', Colors.white54),
      AcessoProprietario(ativo: false) => ('Desativado', Colors.grey),
      AcessoProprietario(bloqueado: true) => (
        'Bloqueado (tentativas)',
        Colors.redAccent,
      ),
      AcessoProprietario(trocarSenha: true) => (
        'Senha provisória',
        Colors.orangeAccent,
      ),
      _ => ('Acesso ativo', Colors.greenAccent),
    };

/// Estrelas da nota de conservação (1 a 5).
class Estrelas extends StatelessWidget {
  const Estrelas({
    super.key,
    required this.nota,
    this.onChanged,
    this.tamanho = 22,
  });

  final int? nota;
  final ValueChanged<int>? onChanged;
  final double tamanho;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        InkWell(
          onTap: onChanged == null ? null : () => onChanged!(i),
          child: Icon(
            i <= (nota ?? 0) ? Icons.star : Icons.star_border,
            color: AppColors.gold,
            size: tamanho,
          ),
        ),
    ],
  );
}
