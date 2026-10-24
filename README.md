# Gestão Imobiliária

App de gestão (Flutter) do sistema multi-imobiliária. A API fica em
`https://api.xn--associaoconectabci-7sb3f.com.br` (`lib/core/api/api_config.dart`).

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

Por padrão o app usa o servidor de produção na AWS
(`https://api.xn--associaoconectabci-7sb3f.com.br`, definido em
`lib/core/api/api_config.dart`):

```bash
flutter run -d chrome
```

Para usar o servidor local (`python main.py` no `servidor`, repositório `SystemsSoft/conectabco-servidor-`):

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:8000
```

Para publicar o app web em outro endereço (ex.: `https://gestao.associaçãoconectabci.com.br`),
inclua esse endereço em `CORS_ORIGINS` no `.env` do servidor.

## Imobiliária em uso

O mesmo app atende todas as imobiliárias da plataforma; cada uma tem o seu
banco. Ao abrir, ele não mostra nome nem logotipo até descobrir qual é:

1. **Pelo domínio**: publicado pelo servidor em `/gestao` de cada domínio
   (ex.: `https://joaoimoveis.com.br/gestao/`), pergunta a `/api/v1/marca`
   do próprio endereço e o servidor reconhece a imobiliária;
2. **Pelo código**: fora do domínio de uma (endereço do servidor, Netlify,
   desenvolvimento), pede o código dela (ex.: `joao`) e o guarda no aparelho
   ("Trocar de imobiliária" no login esquece o código).

Identificada, o app aplica o nome, a paleta e o logotipo cadastrados no
painel da plataforma (`lib/core/marca/`) e manda `X-Imobiliaria` em todas as
chamadas à API.

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
