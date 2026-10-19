import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fundo da marca: degradê azul-marinho com brilhos e linhas douradas finas.
class FundoMarca extends StatelessWidget {
  const FundoMarca({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0B2E73), AppColors.navyDark, Color(0xFF071B4A)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: CustomPaint(painter: _LinhasMarcaPainter(), child: child),
    );
  }
}

class _LinhasMarcaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;

    // Brilhos azuis nos cantos.
    void brilho(Offset c, double raio, double alpha) => canvas.drawCircle(
      c,
      raio,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.blueGlow.withValues(alpha: alpha),
            AppColors.blueGlow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: raio)),
    );
    brilho(Offset(w, 0), math.max(w, h) * 0.45, 0.16);
    brilho(Offset(0, h), math.max(w, h) * 0.35, 0.12);

    // Silhueta da casa, bem discreta, no canto inferior esquerdo.
    final casa = Path()
      ..moveTo(0, h * 0.80)
      ..lineTo(w * 0.07, h * 0.72)
      ..lineTo(w * 0.14, h * 0.80)
      ..lineTo(w * 0.14, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      casa,
      Paint()..color = Colors.white.withValues(alpha: 0.025),
    );

    // Faixa larga e translúcida acompanhando a curva inferior.
    final faixa = Path()
      ..moveTo(0, h * 0.64)
      ..quadraticBezierTo(w * 0.17, h * 0.74, w * 0.27, h);
    canvas.drawPath(
      faixa,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 46
        ..color = AppColors.blue.withValues(alpha: 0.12),
    );

    final ouro = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = LinearGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.05),
          AppColors.gold.withValues(alpha: 0.7),
          AppColors.gold.withValues(alpha: 0.05),
        ],
      ).createShader(Offset.zero & s);

    // Curva inferior esquerda.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.62)
        ..quadraticBezierTo(w * 0.19, h * 0.72, w * 0.29, h),
      ouro,
    );
    // Curva à direita, descendo para o centro.
    canvas.drawPath(
      Path()
        ..moveTo(w, h * 0.50)
        ..quadraticBezierTo(w * 0.86, h * 0.68, w * 0.62, h * 0.80),
      ouro,
    );
    // Curva no canto superior direito.
    canvas.drawPath(
      Path()
        ..moveTo(w * 1.02, h * 0.08)
        ..quadraticBezierTo(w * 0.97, h * 0.18, w * 0.89, h * 0.26),
      ouro,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Barra de abas do módulo: ícone ao lado do texto e sublinhado dourado.
/// Precisa de um [DefaultTabController] acima.
class AbasModulo extends StatelessWidget {
  const AbasModulo({super.key, required this.abas});

  final List<(IconData, String)> abas;

  @override
  Widget build(BuildContext context) {
    // Celular: abas mais baixas e juntas (cabem mais na largura).
    final estreito = MediaQuery.sizeOf(context).width < 700;
    final fonte = estreito ? 14.0 : 15.0;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.symmetric(horizontal: estreito ? 4 : 16),
        labelPadding: EdgeInsets.symmetric(horizontal: estreito ? 14 : 26),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.gold, width: 3),
        ),
        dividerColor: Colors.transparent,
        labelColor: AppColors.gold,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: fonte),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: fonte,
        ),
        overlayColor: WidgetStatePropertyAll(
          AppColors.gold.withValues(alpha: 0.06),
        ),
        tabs: [
          for (final (icone, texto) in abas)
            Tab(
              height: estreito ? 52 : 72,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: estreito ? 20 : 24),
                  SizedBox(width: estreito ? 8 : 12),
                  Text(texto),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Painel translúcido com borda fina onde fica o conteúdo do módulo.
class PainelConteudo extends StatelessWidget {
  const PainelConteudo({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Celular: ocupa a largura toda (sem moldura), sobra mais espaço útil.
    if (MediaQuery.sizeOf(context).width < 700) return child;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blueGlow.withValues(alpha: 0.28)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.navy.withValues(alpha: 0.35),
              AppColors.navyDark.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(17), child: child),
      ),
    );
  }
}

/// Campo de busca arredondado do painel.
class CampoBusca extends StatelessWidget {
  const CampoBusca({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final estreito = MediaQuery.sizeOf(context).width < 700;
    OutlineInputBorder borda(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 16, right: 10),
          child: Icon(
            Icons.search,
            size: estreito ? 22 : 26,
            color: Colors.white,
          ),
        ),
        filled: true,
        fillColor: AppColors.navy.withValues(alpha: 0.55),
        contentPadding: EdgeInsets.symmetric(vertical: estreito ? 13 : 18),
        enabledBorder: borda(Colors.white.withValues(alpha: 0.14)),
        focusedBorder: borda(AppColors.gold.withValues(alpha: 0.8)),
        border: borda(Colors.white.withValues(alpha: 0.14)),
      ),
    );
  }
}
