# marceloimob_gestao

Marcelo imóveis

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Servidor

Por padrão o app usa o servidor de produção na AWS (`https://api.inovacloud.app`,
definido em `lib/core/api/api_config.dart`):

```bash
flutter run -d chrome
```

Para usar o servidor local (`python main.py` no `marceloimob_servidor`):

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:8000
```

Para publicar o app web em outro endereço (ex.: `https://gestao.inovacloud.app`),
inclua esse endereço em `CORS_ORIGINS` no `.env` do servidor.

## App web e instalação no Android

O app fica publicado em `https://api.inovacloud.app/gestao/`:

```bash
./deploy_web.sh
```

O script gera o build (`--base-href /gestao/`), envia para o servidor e
configura a rota no nginx. O app pode ser instalado (PWA: abre em janela
própria e sempre na versão mais nova):

- **Android**: opção **Baixar app** no menu (instala na tela inicial).
- **Computador** (Windows, Mac e Linux): botão **Baixar para desktop** no
  topo e no menu. Chrome e Edge instalam direto; no Safari do Mac (Sonoma
  ou mais novo) o app mostra como usar Arquivo › Adicionar ao Dock; o
  Firefox não instala apps, então ele indica o Chrome ou o Edge.

As opções somem quando o app já está instalado (e no iPhone/iPad).
