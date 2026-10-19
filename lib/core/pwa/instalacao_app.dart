import 'instalacao_app_stub.dart'
    if (dart.library.js_interop) 'instalacao_app_web.dart';

/// Endereço oficial do app web (onde ele pode ser instalado).
const enderecoAppWeb = 'https://api.inovacloud.app/gestao/';

enum ResultadoInstalacao {
  /// O usuário confirmou a instalação.
  instalado,

  /// O usuário fechou a janela de instalação.
  recusado,

  /// O navegador não ofereceu a instalação (precisa seguir as instruções).
  indisponivel,
}

/// Instalação do app (PWA) pelo navegador do celular Android.
abstract class InstalacaoApp {
  /// Implementação da plataforma (web ou nenhuma).
  factory InstalacaoApp() = InstalacaoAppPlataforma;

  /// Navegador de um aparelho Android.
  bool get android;

  /// Já está aberto como app instalado (tela cheia, sem barra do navegador).
  bool get instalado;

  /// Mostra a opção "Baixar app" no menu.
  bool get mostrarOpcao => android && !instalado;

  /// O navegador já ofereceu a instalação direta (sem passos manuais).
  bool get disponivel;

  /// Este é o endereço oficial, onde a instalação funciona.
  bool get enderecoOficial;

  Future<ResultadoInstalacao> instalar();
}
