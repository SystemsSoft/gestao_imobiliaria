import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';

/// Toca o vídeo de abertura em tela cheia e chama [onFinished] ao terminar.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final VideoPlayerController _controller;
  bool _finished = false;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/splash_marcelo_bonifacio.webm',
    )..addListener(_onTick);
    _start();
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      // Navegadores só permitem autoplay com o áudio mudo.
      await _controller.setVolume(0);
      await _controller.setLooping(false);
      if (!mounted) return;
      setState(() {});
      // Rede de segurança: nunca prende o usuário na splash (autoplay
      // bloqueado, vídeo travado etc.).
      _watchdog = Timer(
        _controller.value.duration + const Duration(seconds: 2),
        _finish,
      );
      await _controller.play();
    } catch (_) {
      // Se o vídeo falhar, não prende o usuário na splash.
      _finish();
    }
  }

  void _onTick() {
    final value = _controller.value;
    if (value.hasError) {
      _finish();
    } else if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration) {
      _finish();
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    _watchdog?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _finish, // atalho para pular a abertura
        child: SizedBox.expand(
          child: value.isInitialized
              ? LayoutBuilder(
                  builder: (context, c) => _VideoAjustado(
                    tela: c.biggest,
                    proporcao: value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Encaixa o vídeo de abertura em qualquer tela sem cortar a marca.
///
/// O vídeo é quadrado, com o logo e o nome ocupando ~94% da largura e ~80%
/// da altura (área segura). Ele cobre a tela quando isso não corta a área
/// segura; senão, é reduzido até ela caber e as bordas se fundem ao fundo.
class _VideoAjustado extends StatelessWidget {
  const _VideoAjustado({
    required this.tela,
    required this.proporcao,
    required this.child,
  });

  final Size tela;
  final double proporcao;
  final Widget child;

  static const _seguraLargura = 0.94;
  static const _seguraAltura = 0.80;

  @override
  Widget build(BuildContext context) {
    // Lado de cobertura limitado para a área segura caber nos dois eixos.
    final cobrir = tela.width / tela.height > proporcao
        ? tela.width
        : tela.height * proporcao;
    final largura = [
      cobrir,
      tela.width / _seguraLargura,
      tela.height * proporcao / _seguraAltura,
    ].reduce((a, b) => a < b ? a : b);
    final altura = largura / proporcao;
    // Faixa de transição: o vídeo fica menor que a tela nesse eixo.
    final fundeLados = largura < tela.width;
    final fundeTopo = altura < tela.height;
    final faixa = largura * 0.16;
    return ClipRect(
      child: Center(
        child: OverflowBox(
          maxWidth: largura,
          maxHeight: altura,
          child: SizedBox(
            width: largura,
            height: altura,
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                // O fundo por cima das bordas (ShaderMask não se aplica ao
                // vídeo no navegador, mas um gradiente sobreposto sim).
                if (fundeTopo) ...[
                  _Fusao(faixa: faixa, inicio: Alignment.topCenter),
                  _Fusao(faixa: faixa, inicio: Alignment.bottomCenter),
                ],
                if (fundeLados) ...[
                  _Fusao(faixa: faixa, inicio: Alignment.centerLeft),
                  _Fusao(faixa: faixa, inicio: Alignment.centerRight),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradiente do fundo para transparente, a partir de uma borda do vídeo.
class _Fusao extends StatelessWidget {
  const _Fusao({required this.faixa, required this.inicio});

  final double faixa;
  final Alignment inicio;

  @override
  Widget build(BuildContext context) {
    final vertical = inicio.x == 0;
    return Align(
      alignment: inicio,
      child: IgnorePointer(
        child: Container(
          width: vertical ? double.infinity : faixa,
          height: vertical ? faixa : double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: inicio,
              end: Alignment(-inicio.x, -inicio.y),
              colors: [
                AppColors.navyDark,
                AppColors.navyDark.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
