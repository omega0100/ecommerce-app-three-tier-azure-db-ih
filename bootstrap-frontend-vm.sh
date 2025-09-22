#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:?missing APP_DIR}"
ACR_NAME="${ACR_NAME:?missing ACR_NAME}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:?missing ACR_LOGIN_SERVER}"
IMAGE_TAG="${IMAGE_TAG:?missing IMAGE_TAG}"
FE_HEALTH_URL="${FE_HEALTH_URL:?missing FE_HEALTH_URL}"     # مثل: http://127.0.0.1:3000/health
BACKEND_ORIGIN="${BACKEND_ORIGIN:?missing BACKEND_ORIGIN}"   # مثل: http://10.0.4.5:3001

# Docker + Compose
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo systemctl enable --now docker
fi

COMPOSE_BIN=""
if docker compose version >/dev/null 2>&1; then
  COMPOSE_BIN="docker compose"
else
  if ! command -v docker-compose >/dev/null 2>&1; then
    sudo curl -fsSL "https://github.com/docker/compose/releases/download/2.29.7/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  fi
  COMPOSE_BIN="docker-compose"
fi

# تحضير مجلد التطبيق
mkdir -p "$APP_DIR" && cd "$APP_DIR"

# Compose خاص بالفرونت فقط
cat > docker-compose.frontend.yml <<'YML'
name: ecommerce
services:
  frontend:
    image: ${ACR_LOGIN_SERVER}/ecommerce-frontend:${IMAGE_TAG}
    container_name: ecommerce-frontend
    ports:
      - "3000:80"
    restart: unless-stopped
    volumes:
      - ./nginx.default.conf:/etc/nginx/conf.d/default.conf:ro
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost/health || exit 1"]
      interval: 20s
      timeout: 10s
      retries: 5
      start_period: 20s
YML

# NGINX بدون أي allowlist للـIPs
cat > nginx.default.conf <<'CONF'
map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}
server {
  listen 80;
  server_name _;

  # Health مفتوح للجميع
  location = /health {
    default_type application/json;
    add_header Cache-Control "no-store";
    return 200 '{"status":"OK"}';
  }

  # ملفات الواجهة
  root /usr/share/nginx/html;
  try_files $uri $uri/ /index.html;

  # بروكسي للباك إند تحت /api/
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
sed -i "s#__BACKEND_ORIGIN__#${BACKEND_ORIGIN}#g" nginx.default.conf

# .env للسحب من ACR
printf "ACR_LOGIN_SERVER=%s\nIMAGE_TAG=%s\n" "$ACR_LOGIN_SERVER" "$IMAGE_TAG" > .env
echo "--- .env (safe) ---"
grep -E '^(ACR_LOGIN_SERVER|IMAGE_TAG)=' .env || true

# Azure CLI + ACR login بهوية الـVM
if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi
az login --identity >/dev/null
TOKEN=$(az acr login -n "$ACR_NAME" --expose-token --query accessToken -o tsv)
echo "$TOKEN" | docker login "$ACR_LOGIN_SERVER" -u 00000000-0000-0000-0000-000000000000 --password-stdin

# نشر الفرونت فقط (بدون fallback خاطئ)
$COMPOSE_BIN --env-file .env -f docker-compose.frontend.yml pull frontend
docker rm -f ecommerce-frontend 2>/dev/null || true
$COMPOSE_BIN --env-file .env -f docker-compose.frontend.yml up -d --no-deps --force-recreate frontend

# Health gate
for i in $(seq 1 36); do
  if curl -fsS "$FE_HEALTH_URL" >/dev/null; then
    echo "Frontend healthy"; exit 0
  fi
  sleep 5
done

echo "Frontend failed healthcheck"
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}' --filter name=ecommerce-frontend || true
docker logs ecommerce-frontend --tail 300 || true
exit 1
