import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard.dart';

/// Barras de vendas (dourado) e locações (azul) com a linha do total.
class GraficoDesempenho extends StatelessWidget {
  const GraficoDesempenho({super.key, required this.pontos});

  final List<PontoDesempenho> pontos;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DesempenhoPainter(pontos), size: Size.infinite);
}

class _DesempenhoPainter extends CustomPainter {
  _DesempenhoPainter(this.pontos);

  final List<PontoDesempenho> pontos;

  static const _eixoY = 30.0;
  static const _eixoX = 24.0;

  double _teto(int max) {
    if (max <= 4) return 4;
    final passo = max <= 20 ? 5 : (max <= 40 ? 10 : 20);
    return (max / passo).ceil() * passo.toDouble();
  }

  @override
  void paint(Canvas canvas, Size s) {
    if (pontos.isEmpty) return;
    final area = Rect.fromLTRB(_eixoY, 6, s.width, s.height - _eixoX);
    final teto = _teto(
      pontos.map((p) => max(p.total, max(p.vendas, p.locacoes))).reduce(max),
    );
    final texto = TextPainter(textDirection: TextDirection.ltr);
    void escrever(
      String t,
      Offset o, {
      bool centro = false,
      bool direita = false,
    }) {
      texto.text = TextSpan(
        text: t,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      );
      texto.layout();
      var dx = o.dx;
      if (centro) dx -= texto.width / 2;
      if (direita) dx -= texto.width;
      texto.paint(canvas, Offset(dx, o.dy - texto.height / 2));
    }

    // Grade e eixo Y.
    final grade = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = area.bottom - area.height * i / 4;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), grade);
      escrever(
        (teto * i / 4).round().toString(),
        Offset(area.left - 8, y),
        direita: true,
      );
    }

    final passo = area.width / pontos.length;
    final barra = min(passo * 0.32, 12.0);
    double y(num v) => area.bottom - area.height * v / teto;
    final linha = Path();
    for (var i = 0; i < pontos.length; i++) {
      final p = pontos[i];
      final cx = area.left + passo * (i + 0.5);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(cx - barra - 1, y(p.vendas), cx - 1, area.bottom),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        Paint()..color = AppColors.gold,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(cx + 1, y(p.locacoes), cx + barra + 1, area.bottom),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        Paint()..color = AppColors.blueGlow,
      );
      // Linha: média das duas séries, para acompanhar o topo das barras.
      final ly = y((p.vendas + p.locacoes) / 2 + 2);
      i == 0 ? linha.moveTo(cx, ly) : linha.lineTo(cx, ly);

      final cadaQuantos = max(1, (pontos.length / 6).ceil());
      if (i % cadaQuantos == 0) {
        escrever(p.rotulo, Offset(cx, area.bottom + 14), centro: true);
      }
    }
    canvas.drawPath(
      linha,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.goldLight,
    );
  }

  @override
  bool shouldRepaint(covariant _DesempenhoPainter old) => old.pontos != pontos;
}

/// Rosca da taxa de conversão com o ícone da casa ao centro.
class RoscaConversao extends StatelessWidget {
  const RoscaConversao({super.key, required this.taxa, this.tamanho = 96});

  final double taxa;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(
        painter: _RoscaPainter(taxa),
        child: Center(
          child: Container(
            width: tamanho * 0.52,
            height: tamanho * 0.52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navyDark,
            ),
            child: Icon(
              Icons.home_work,
              color: AppColors.gold,
              size: tamanho * 0.26,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoscaPainter extends CustomPainter {
  _RoscaPainter(this.taxa);

  final double taxa;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final raio = s.shortestSide / 2 - 7;
    final rect = Rect.fromCircle(center: c, radius: raio);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(c, raio, base);
    // Arco dourado proporcional à taxa (ampliado para leitura) e o restante em azul.
    final fracao = (0.25 + taxa / 100 * 3).clamp(0.05, 0.95);
    final arco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * fracao,
      false,
      arco..color = AppColors.gold,
    );
    canvas.drawArc(
      rect,
      -pi / 2 + 2 * pi * fracao + 0.15,
      2 * pi * (1 - fracao) - 0.3,
      false,
      arco..color = AppColors.blueGlow,
    );
  }

  @override
  bool shouldRepaint(covariant _RoscaPainter old) => old.taxa != taxa;
}

/// Área dourada com a evolução da receita no mês.
class GraficoArea extends StatelessWidget {
  const GraficoArea({super.key, required this.valores});

  final List<double> valores;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _AreaPainter(valores), size: Size.infinite);
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.valores);

  final List<double> valores;

  @override
  void paint(Canvas canvas, Size s) {
    if (valores.length < 2) return;
    final maxV = valores.reduce(max);
    final minV = valores.reduce(min);
    Offset p(int i) => Offset(
      s.width * i / (valores.length - 1),
      s.height -
          (valores[i] - minV) /
              (maxV - minV == 0 ? 1 : maxV - minV) *
              (s.height - 4) -
          2,
    );
    final linha = Path()..moveTo(p(0).dx, p(0).dy);
    for (var i = 1; i < valores.length; i++) {
      linha.lineTo(p(i).dx, p(i).dy);
    }
    final area = Path.from(linha)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gold.withValues(alpha: 0.45),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & s),
    );
    canvas.drawPath(
      linha,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _AreaPainter old) => old.valores != valores;
}
