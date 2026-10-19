import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'instalacao_app.dart';

/// Funções do `web/index.html`, que guarda o convite de instalação
/// (`beforeinstallprompt`) do Chrome e do Edge.
@JS('mbInstalacaoDisponivel')
external bool _disponivel();

@JS('mbInstalarApp')
external JSPromise<JSString> _instalar(int esperaMs);

class InstalacaoAppPlataforma implements InstalacaoApp {
  late final (Sistema, Navegador) _detectado = detectar(
    web.window.navigator.userAgent,
    pontosToque: web.window.navigator.maxTouchPoints,
  );

  @override
  Sistema get sistema => _detectado.$1;

  @override
  Navegador get navegador => _detectado.$2;

  @override
  bool get instalado =>
      web.window.matchMedia('(display-mode: standalone)').matches ||
      web.window.matchMedia('(display-mode: fullscreen)').matches ||
      web.window.matchMedia('(display-mode: window-controls-overlay)').matches;

  @override
  bool get disponivel {
    try {
      return _disponivel();
    } on Object {
      return false;
    }
  }

  @override
  bool get enderecoOficial =>
      web.window.location.href.startsWith(enderecoAppWeb);

  @override
  Future<ResultadoInstalacao> instalar({
    Duration espera = Duration.zero,
  }) async {
    try {
      final r = (await _instalar(espera.inMilliseconds).toDart).toDart;
      return switch (r) {
        'accepted' => ResultadoInstalacao.instalado,
        'dismissed' => ResultadoInstalacao.recusado,
        'ja-instalado' => ResultadoInstalacao.jaInstalado,
        _ => ResultadoInstalacao.indisponivel,
      };
    } on Object {
      return ResultadoInstalacao.indisponivel;
    }
  }

  /// Link de intenção do Android: abre o endereço atual no Chrome (se ele
  /// não existir, segue no próprio navegador).
  @override
  void abrirNoChrome() {
    final atual = Uri.parse(web.window.location.href);
    final semEsquema = atual.toString().substring('${atual.scheme}://'.length);
    web.window.location.href =
        'intent://$semEsquema#Intent;scheme=${atual.scheme};'
        'package=com.android.chrome;'
        'S.browser_fallback_url=${Uri.encodeComponent(atual.toString())};end';
  }
}
