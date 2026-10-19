#!/usr/bin/env bash
# Publica o app de gestão (web, instalável como app no Android) em
#   https://api.inovacloud.app/gestao/
# Uso: ./deploy_web.sh [chave.pem] [usuario@host]
# Gera o build, envia os arquivos e garante a rota /gestao/ no nginx.
set -euo pipefail
cd "$(dirname "$0")"
CHAVE=${1:-../marceloimob_servidor/key-aws.pem}
HOST=${2:-ec2-user@18.191.168.173}
SSH="ssh -i $CHAVE -o BatchMode=yes"
DESTINO=/var/www/marceloimob-gestao

flutter build web --release --base-href /gestao/

$SSH "$HOST" "sudo install -d -m 755 /var/www && sudo install -d -o \$(id -un) -g \$(id -gn) -m 755 $DESTINO"
rsync -az --delete -e "$SSH" build/web/ "$HOST:$DESTINO/"

$SSH "$HOST" 'bash -s' <<'REMOTO'
set -e
SNIPPET=/etc/nginx/snippets/marceloimob-gestao.conf
sudo tee "$SNIPPET" >/dev/null <<'NGINX'
# App de gestão (Flutter web / PWA) publicado pelo deploy_web.sh.
location = /gestao { return 301 /gestao/; }
location ^~ /gestao/ {
    alias /var/www/marceloimob-gestao/;
    index index.html;
    try_files $uri $uri/ /gestao/index.html;
    # Sempre confere a versão nova (os nomes dos arquivos não mudam).
    add_header Cache-Control "no-cache" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Robots-Tag "noindex, nofollow" always;
}
location ^~ /gestao/assets/ {
    alias /var/www/marceloimob-gestao/assets/;
    add_header Cache-Control "public, max-age=86400" always;
}
NGINX
CONF=/etc/nginx/conf.d/inovacloud.conf
if ! sudo grep -q "marceloimob-gestao.conf" "$CONF"; then
  sudo sed -i "0,/include \/etc\/nginx\/snippets\/marceloimob-proxy.conf;/s//include \/etc\/nginx\/snippets\/marceloimob-gestao.conf;\n    include \/etc\/nginx\/snippets\/marceloimob-proxy.conf;/" "$CONF"
fi
sudo nginx -t -q && sudo systemctl reload nginx
REMOTO
curl -fsS -o /dev/null -w "https://api.inovacloud.app/gestao/ -> %{http_code}\n" https://api.inovacloud.app/gestao/
