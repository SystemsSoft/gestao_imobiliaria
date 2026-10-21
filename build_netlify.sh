#!/usr/bin/env bash
# Gera o build do app de gestão (Flutter web) para publicar na Netlify, na
# raiz do domínio (ex.: https://marcelo-bonifacio-imob.netlify.app/).
# Uso: ./build_netlify.sh [pasta_destino] [api_url]
#   pasta_destino  onde ficam os arquivos (padrão: ../netlify_marceloimob_gestao)
#   api_url        servidor da API (padrão: o de produção, em ApiConfig)
# A pasta sai idêntica a build/web, pronta para arrastar em
# Netlify › Deploy manually. O domínio da Netlify precisa estar em
# CORS_ORIGINS no .env do servidor.
set -euo pipefail
cd "$(dirname "$0")"
DESTINO=${1:-../netlify_marceloimob_gestao}
API_URL=${2:-}

flutter build web --release --base-href / \
  ${API_URL:+--dart-define=API_URL=$API_URL}

# Sem isso, recarregar uma página interna dá 404 na Netlify.
if [ ! -f build/web/_redirects ]; then
  printf '/*    /index.html   200\n' > build/web/_redirects
fi

mkdir -p "$DESTINO"
rsync -a --delete build/web/ "$DESTINO/"

echo
echo "Pasta: $(cd "$DESTINO" && pwd) ($(find "$DESTINO" -type f | wc -l | tr -d ' ') arquivos, $(du -sh "$DESTINO" | cut -f1 | tr -d ' '))"
echo "Publique arrastando essa pasta em Netlify › Deploy manually."
