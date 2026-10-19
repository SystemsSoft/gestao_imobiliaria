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
