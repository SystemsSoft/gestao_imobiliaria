import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Cartão padrão do dashboard: título com ícone, link opcional e conteúdo.
class DashCard extends StatelessWidget {
  const DashCard({
    super.key,
    required this.child,
    this.titulo,
    this.icone,
    this.acao,
    this.onAcao,
    this.padding = const EdgeInsets.all(18),
    this.trailing,
  });

  final Widget child;
  final String? titulo;
  final IconData? icone;
  final String? acao;
  final VoidCallback? onAcao;
  final EdgeInsets padding;

  /// Widget no lugar do link (ex.: seletor de período).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blueGlow.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy.withValues(alpha: 0.55),
            AppColors.navyDark.withValues(alpha: 0.55),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titulo != null) ...[
            Row(
              children: [
                if (icone != null) ...[
                  Icon(icone, color: AppColors.gold, size: 26),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    titulo!,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
                if (acao != null) LinkAcao(texto: acao!, onTap: onAcao),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

/// "Ver todos →".
class LinkAcao extends StatelessWidget {
  const LinkAcao({
    super.key,
    required this.texto,
    this.onTap,
    this.cor = Colors.white,
  });

  final String texto;
  final VoidCallback? onTap;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(texto, style: TextStyle(color: cor, fontSize: 12)),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward, size: 14, color: cor),
          ],
        ),
      ),
    );
  }
}

/// Ícone dourado dentro de um círculo com borda.
class IconeCirculo extends StatelessWidget {
  const IconeCirculo(
    this.icone, {
    super.key,
    this.tamanho = 44,
    this.cor = AppColors.gold,
  });

  final IconData icone;
  final double tamanho;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cor.withValues(alpha: 0.7), width: 1.5),
        color: cor.withValues(alpha: 0.06),
      ),
      child: Icon(icone, color: cor, size: tamanho * 0.52),
    );
  }
}

/// Variação percentual com seta (verde para alta, vermelha para queda).
class Variacao extends StatelessWidget {
  const Variacao(this.valor, {super.key, this.sufixo = '%', this.tamanho = 16});

  final double valor;
  final String sufixo;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final alta = valor >= 0;
    final cor = alta ? const Color(0xFF3DDC84) : Colors.redAccent;
    final numero = valor.abs() == valor.abs().roundToDouble()
        ? valor.abs().toStringAsFixed(0)
        : valor.abs().toStringAsFixed(1).replaceAll('.', ',');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          alta ? Icons.arrow_upward : Icons.arrow_downward,
          size: tamanho + 2,
          color: cor,
        ),
        const SizedBox(width: 2),
        Text(
          '$numero$sufixo',
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.w800,
            fontSize: tamanho,
          ),
        ),
      ],
    );
  }
}
