import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'instalacao_app.dart';

/// Funções do `web/index.html`, que guarda o convite de instalação
/// (`beforeinstallprompt`) do Chrome.
@JS('mbInstalacaoDisponivel')
external bool _disponivel();

@JS('mbInstalarApp')
external JSPromise<JSString> _instalar();

class InstalacaoAppPlataforma implements InstalacaoApp {
  @override
  bool get android =>
      web.window.navigator.userAgent.toLowerCase().contains('android');

  @override
  bool get instalado =>
      web.window.matchMedia('(display-mode: standalone)').matches ||
      web.window.matchMedia('(display-mode: fullscreen)').matches;

  @override
  bool get mostrarOpcao => android && !instalado;

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
  Future<ResultadoInstalacao> instalar() async {
    try {
      final r = (await _instalar().toDart).toDart;
      return switch (r) {
        'accepted' => ResultadoInstalacao.instalado,
        'dismissed' => ResultadoInstalacao.recusado,
        _ => ResultadoInstalacao.indisponivel,
      };
    } on Object {
      return ResultadoInstalacao.indisponivel;
    }
  }
}
