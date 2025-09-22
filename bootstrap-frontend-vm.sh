#!/usr/bin/env bash
set -euxo pipefail

# مطلوب تمريرها من الإكستنشن (v.sh)
APP_DIR="${APP_DIR:?missing APP_DIR}"
ACR_NAME="${ACR_NAME:?missing ACR_NAME}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:?missing ACR_LOGIN_SERVER}"
RAW_URL="${RAW_URL:?missing RAW_URL}"        # رابط compose للفرونت فقط
IMAGE_TAG="${IMAGE_TAG:?missing IMAGE_TAG}"  # تاك موجود في ACR
FE_HEALTH_URL="${FE_HEALTH_URL:?missing FE_HEALTH_URL}"  # مثال: http://127.0.0.1:3000/health

# 0) Docker + Compose
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo systemctl enable --now docker
fi
if ! docker compose version >/dev/null 2>&1; then
  sudo curl -fsSL "https://github.com/docker/compose/releases/download/2.29.7/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose || true
fi

# 1) مجلد التطبيق + تحميل compose
mkdir -p "$APP_DIR" && cd "$APP_DIR"
curl -fsSL "$RAW_URL" -o docker-compose.yml

# 2) ملف nginx (static فقط – بدون أي allowlist أو proxy)
cat > nginx.default.conf <<'CONF'
server {
  listen 80;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;

  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "1; mode=block" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;

  # لا كاش لقالب الـSPA
  location = /index.html {
    add_header Cache-Control "no-store, max-age=0" always;
    try_files $uri =404;
  }

  # الـSPA fallback
  location / {
    add_header Cache-Control "no-store, max-age=0" always;
    try_files $uri $uri/ /index.html;
  }

  # كاش طويل للأصول المجمّلة
  location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    try_files $uri =404;
  }

  # الصحة
  location = /health {
    access_log off;
    default_type text/plain;
    return 200 "healthy\n";
  }
}
CONF

# 3) .env لسحب الصورة من ACR فقط
{
  echo "ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER"
  echo "IMAGE_TAG=$IMAGE_TAG"
} > .env
grep -E '^(ACR_LOGIN_SERVER|IMAGE_TAG)=' .env || true

# 4) az + ACR login بهوية الـVM
if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi
az login --identity >/dev/null
TOKEN=$(az acr login -n "$ACR_NAME" --expose-token --query accessToken -o tsv)
echo "$TOKEN" | docker login "$ACR_LOGIN_SERVER" -u 00000000-0000-0000-0000-000000000000 --password-stdin

# 5) تشغيل خدمة الفرونت فقط
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
docker logs ecommerce-frontend --tail 300 || true
exit 1
