#!/usr/bin/env bash
set -euxo pipefail

APP_DIR="${APP_DIR:?missing APP_DIR}"
ACR_NAME="${ACR_NAME:?missing ACR_NAME}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:?missing ACR_LOGIN_SERVER}"
RAW_URL="${RAW_URL:?missing RAW_URL}"               # compose URL
IMAGE_TAG="${IMAGE_TAG:-latest}"
FE_HEALTH_URL="${FE_HEALTH_URL:?missing FE_HEALTH_URL}"   # e.g. http://127.0.0.1:3000/health
BACKEND_ORIGIN="${BACKEND_ORIGIN:?missing BACKEND_ORIGIN}" # e.g. http://10.0.4.5:3001

# 0) docker + compose
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo systemctl enable --now docker
fi
if ! docker compose version >/dev/null 2>&1; then
  if ! command -v docker-compose >/dev/null 2>&1; then
    sudo curl -fsSL "https://github.com/docker/compose/releases/download/2.29.7/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose || true
  fi
fi

# 1) جِهّز مجلد التطبيق + حمل compose
mkdir -p "$APP_DIR" && cd "$APP_DIR"
curl -fsSL "$RAW_URL" -o docker-compose.yml

# 2) اكتب ملف NGINX بدون أي allowlist للـIPs
cat > nginx.default.conf <<'CONF'
map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}

server {
  listen 80;
  server_name _;

  # Health: مفتوح للجميع، لا rate-limit ولا allowlist
  location = /health {
    default_type application/json;
    add_header Cache-Control "no-store";
    return 200 '{"status":"OK"}';
  }

  # ملفات الواجهة
  root /usr/share/nginx/html;
  try_files $uri $uri/ /index.html;

  # بروكسي للباك إند تحت /api (غيّر BACKEND_ORIGIN عبر المتغيّر)
  location /api/ {
    proxy_pass __BACKEND_ORIGIN__/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_read_timeout 60s;
  }
}
CONF
# استبدل الـplaceholder بعنوان الباك إند
sed -i "s#__BACKEND_ORIGIN__#${BACKEND_ORIGIN}#g" nginx.default.conf

# 3) .env (للسحب من ACR)
{
  echo "ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER"
  echo "IMAGE_TAG=$IMAGE_TAG"
} > .env
echo "--- .env (safe) ---"
grep -E '^(ACR_LOGIN_SERVER|IMAGE_TAG)=' .env || true

# 4) az + ACR login بهوية الـVM
if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi
az login --identity >/dev/null
TOKEN=$(az acr login -n "$ACR_NAME" --expose-token --query accessToken -o tsv)
echo "$TOKEN" | docker login "$ACR_LOGIN_SERVER" -u 00000000-0000-0000-0000-000000000000 --password-stdin

# 5) تشغيل الـfrontend فقط
docker compose --env-file .env pull frontend || docker-compose --env-file .env pull frontend
docker rm -f ecommerce-frontend 2>/dev/null || true
docker compose --env-file .env up -d --no-deps --force-recreate frontend || docker-compose --env-file .env up -d --no-deps --force-recreate frontend

# 6) Health gate
for i in $(seq 1 36); do
  if curl -fsS "$FE_HEALTH_URL" >/dev/null; then
    echo "Frontend healthy"
    exit 0
  fi
  sleep 5
done

echo "Frontend failed healthcheck"
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}' --filter name=ecommerce-frontend || true
echo "--- logs ---"
docker logs ecommerce-frontend --tail 300 || true
exit 1
