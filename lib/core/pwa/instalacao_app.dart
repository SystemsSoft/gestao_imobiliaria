import 'instalacao_app_stub.dart'
    if (dart.library.js_interop) 'instalacao_app_web.dart';

/// Endereço oficial do app web (onde ele pode ser instalado).
const enderecoAppWeb = 'https://api.inovacloud.app/gestao/';

enum ResultadoInstalacao {
  /// O usuário confirmou a instalação.
  instalado,

  /// O usuário fechou a janela de instalação.
  recusado,

  /// O app já está instalado neste aparelho.
  jaInstalado,

  /// O navegador não ofereceu a instalação (precisa seguir as instruções).
  indisponivel,
}

enum Sistema {
  android,
  ios,
  windows,
  mac('macOS'),
  linux('Linux'),
  outro;

  const Sistema([this.label = '']);
  final String label;

  bool get computador => this == windows || this == mac || this == linux;
}

enum Navegador {
  chrome('Chrome'),
  edge('Edge'),
  safari('Safari'),
  firefox('Firefox'),
  outro('navegador');

  const Navegador(this.label);
  final String label;

  /// Instala com a janela própria do navegador (`beforeinstallprompt`).
  bool get instalacaoDireta => this == chrome || this == edge;
}

/// Sistema e navegador a partir do user agent. O iPad com iPadOS se
/// apresenta como Mac, mas tem tela de toque.
(Sistema, Navegador) detectar(String userAgent, {int pontosToque = 0}) {
  final ua = userAgent.toLowerCase();
  final Sistema sistema;
  if (ua.contains('android')) {
    sistema = Sistema.android;
  } else if (RegExp('iphone|ipad|ipod').hasMatch(ua) ||
      (ua.contains('macintosh') && pontosToque > 1)) {
    sistema = Sistema.ios;
  } else if (ua.contains('windows')) {
    sistema = Sistema.windows;
  } else if (ua.contains('macintosh') || ua.contains('mac os x')) {
    sistema = Sistema.mac;
  } else if (ua.contains('linux') || ua.contains('cros')) {
    sistema = Sistema.linux;
  } else {
    sistema = Sistema.outro;
  }
  final Navegador navegador;
  if (ua.contains('edg/')) {
    navegador = Navegador.edge;
  } else if (ua.contains('firefox/') || ua.contains('fxios/')) {
    navegador = Navegador.firefox;
  } else if (ua.contains('opr/')) {
    navegador = Navegador.outro;
  } else if (ua.contains('chrome/') || ua.contains('crios/')) {
    navegador = Navegador.chrome;
  } else if (ua.contains('safari/')) {
    navegador = Navegador.safari;
  } else {
    navegador = Navegador.outro;
  }
  return (sistema, navegador);
}

/// Instalação do app (PWA) pelo navegador: celular Android e computador
/// (Windows, Mac e Linux).
abstract class InstalacaoApp {
  /// Implementação da plataforma (web ou nenhuma).
  factory InstalacaoApp() = InstalacaoAppPlataforma;

  Sistema get sistema;
  Navegador get navegador;

  /// Já está aberto como app instalado (janela própria, sem barra do
  /// navegador).
  bool get instalado;

  /// O navegador já ofereceu a instalação direta (sem passos manuais).
  bool get disponivel;

  /// Este é o endereço oficial, onde a instalação funciona.
  bool get enderecoOficial;

  /// Abre a janela de instalação do navegador. Com [espera], aguarda o
  /// navegador liberar a instalação (logo após abrir a página).
  Future<ResultadoInstalacao> instalar({Duration espera = Duration.zero});

  /// Android: reabre esta página no Google Chrome (que instala o app).
  void abrirNoChrome();
}

extension InstalacaoAppOpcao on InstalacaoApp {
  bool get android => sistema == Sistema.android;
  bool get computador => sistema.computador;

  /// Mostra a opção de baixar no menu (Android ou computador).
  bool get mostrarOpcao => (android || computador) && !instalado;

  String get rotuloOpcao => computador ? 'Baixar para desktop' : 'Baixar app';
}
