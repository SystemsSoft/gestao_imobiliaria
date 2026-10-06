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
              ? FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: value.size.width,
                    height: value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
