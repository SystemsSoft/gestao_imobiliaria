import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ilustração noturna de uma orla com prédios iluminados, morros e reflexo
/// na água. Desenhada em código (sem imagem externa).
class Skyline extends StatelessWidget {
  const Skyline({super.key, this.semente = 3, this.densidade = 1});

  final int semente;

  /// Multiplica a quantidade de prédios (1 = padrão).
  final double densidade;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SkylinePainter(semente, densidade),
    size: Size.infinite,
  );
}

class _SkylinePainter extends CustomPainter {
  _SkylinePainter(this.semente, this.densidade);

  final int semente;
  final double densidade;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final r = Random(semente);
    final horizonte = h * 0.68;

    // Céu.
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1E4F), Color(0xFF1B3C82), Color(0xFF0B214E)],
          stops: [0, 0.6, 1],
        ).createShader(Offset.zero & s),
    );

    // Morros ao fundo.
    final morros = Path()..moveTo(0, horizonte);
    for (var x = 0.0; x <= w; x += w / 14) {
      morros.lineTo(x, horizonte - h * (0.12 + r.nextDouble() * 0.22));
    }
    morros
      ..lineTo(w, horizonte)
      ..close();
    canvas.drawPath(morros, Paint()..color = const Color(0xFF13285E));

    // Prédios.
    final janela = Paint();
    final n = (w / 18 * densidade).round().clamp(6, 200);
    var x = 0.0;
    for (var i = 0; i < n && x < w; i++) {
      final largura = w / n * (0.6 + r.nextDouble() * 0.9);
      final altura =
          h *
          (0.18 + r.nextDouble() * 0.5) *
          (0.6 + 0.6 * (1 - (x / w - 0.5).abs()));
      final topo = horizonte - altura;
      final predio = Rect.fromLTWH(x, topo, largura * 0.92, altura);
      canvas.drawRect(
        predio,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF0C1A3E),
            const Color(0xFF1A2F63),
            r.nextDouble(),
          )!,
      );
      for (var wy = topo + 4; wy < horizonte - 3; wy += 5) {
        for (var wx = x + 2; wx < x + largura * 0.92 - 2; wx += 4) {
          if (r.nextDouble() < 0.42) {
            janela.color =
                (r.nextDouble() < 0.8 ? AppColors.goldLight : Colors.white)
                    .withValues(alpha: 0.35 + r.nextDouble() * 0.55);
            canvas.drawRect(Rect.fromLTWH(wx, wy, 1.6, 1.8), janela);
          }
        }
      }
      x += largura;
    }

    // Água e reflexos.
    final agua = Rect.fromLTWH(0, horizonte, w, h - horizonte);
    canvas.drawRect(
      agua,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E2457), Color(0xFF050F2B)],
        ).createShader(agua),
    );
    final reflexo = Paint()..strokeWidth = 1.2;
    for (var i = 0; i < w / 6; i++) {
      final rx = r.nextDouble() * w;
      final ry = horizonte + 2 + r.nextDouble() * (h - horizonte - 4);
      reflexo.color = AppColors.gold.withValues(
        alpha:
            0.15 +
            r.nextDouble() * 0.35 * (1 - (ry - horizonte) / (h - horizonte)),
      );
      canvas.drawLine(
        Offset(rx, ry),
        Offset(rx + 4 + r.nextDouble() * 10, ry),
        reflexo,
      );
    }
    // Iluminação da orla.
    canvas.drawLine(
      Offset(0, horizonte + 1),
      Offset(w, horizonte + 1),
      Paint()
        ..strokeWidth = 1.6
        ..color = AppColors.gold.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _SkylinePainter old) =>
      old.semente != semente || old.densidade != densidade;
}
