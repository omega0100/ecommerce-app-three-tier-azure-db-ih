#!/usr/bin/env bash
# سكربت ذاتي التشغيل داخل الـVM (عبر Custom Script Extension)
# يجلب docker-compose.yml، يسحب صورة الباكند من ACR، يحقن أسرار DB من Key Vault أو من env، ويشغّل الحاوية.
set -euxo pipefail

# إعدادات عامة (تُمرَّر عبر commandToExecute أو تُترك بالقيم الافتراضية)
APP_DIR="${APP_DIR:-/home/azureuser/ecommerce-app-three-tier-azure-db-ih}"

ACR_NAME="${ACR_NAME:?missing ACR_NAME}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:?missing ACR_LOGIN_SERVER}"
RAW_URL="${RAW_URL:?missing RAW_URL}"               # Raw docker-compose.yml
IMAGE_TAG="${IMAGE_TAG:-latest}"
BE_HEALTH_URL="${BE_HEALTH_URL:-http://127.0.0.1:3001/health}"

# أسرار DB: إمّا موجودة كـ env (DB_HOST/USER/PASSWORD/NAME) أو تُجلب من Key Vault
KV_NAME="${KV_NAME:-}"                               # اسم Key Vault (اختياري)
SECRET_DB_HOST="${SECRET_DB_HOST:-DB-HOST}"          # أسماء الأسرار في KV (لو استخدمت KV)
SECRET_DB_USER="${SECRET_DB_USER:-DB-USER}"
SECRET_DB_PASSWORD="${SECRET_DB_PASSWORD:-DB-PASSWORD}"
SECRET_DB_NAME="${SECRET_DB_NAME:-DB-NAME}"

# 0) docker & compose
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

# 1) أسرار قاعدة البيانات
need_kv_fetch=false
for v in DB_HOST DB_USER DB_PASSWORD DB_NAME; do
  if [ -z "${!v:-}" ]; then need_kv_fetch=true; fi
done

if $need_kv_fetch; then
  # نحتاج نجلبها من Key Vault عبر الـMSI
  if ! command -v az >/dev/null 2>&1; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  fi
  az login --identity >/dev/null

  [ -n "$KV_NAME" ] || { echo "missing KV_NAME for fetching DB secrets"; exit 1; }

  DB_HOST="$(az keyvault secret show -n "$SECRET_DB_HOST" --vault-name "$KV_NAME" --query value -o tsv)"
  DB_USER="$(az keyvault secret show -n "$SECRET_DB_USER" --vault-name "$KV_NAME" --query value -o tsv)"
  DB_PASSWORD="$(az keyvault secret show -n "$SECRET_DB_PASSWORD" --vault-name "$KV_NAME" --query value -o tsv)"
  DB_NAME="$(az keyvault secret show -n "$SECRET_DB_NAME" --vault-name "$KV_NAME" --query value -o tsv)"
fi

# 2) جلب docker-compose.yml
mkdir -p "$APP_DIR" && cd "$APP_DIR"
curl -fsSL "$RAW_URL" -o docker-compose.yml

# 3) كتابة .env (بدون طباعة الباسوورد)
{
  echo "ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER"
  echo "IMAGE_TAG=$IMAGE_TAG"
  echo "DB_HOST=$DB_HOST"
  echo "DB_USER=$DB_USER"
  echo "DB_PASSWORD=$DB_PASSWORD"
  echo "DB_NAME=$DB_NAME"
  [ -n "${CORS_ORIGIN:-}" ] && echo "CORS_ORIGIN=$CORS_ORIGIN" || true
} > .env
echo "--- .env (safe) ---"
grep -E '^(ACR_LOGIN_SERVER|IMAGE_TAG|DB_HOST|DB_NAME|CORS_ORIGIN)=' .env || true

# 4) ACR login (MSI + access token)
if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi
az login --identity >/dev/null
TOKEN=$(az acr login -n "$ACR_NAME" --expose-token --query accessToken -o tsv)
echo "$TOKEN" | docker login "$ACR_LOGIN_SERVER" -u 00000000-0000-0000-0000-000000000000 --password-stdin

# 5) تشغيل backend
docker compose --env-file .env pull backend || docker-compose --env-file .env pull backend
docker rm -f ecommerce-backend 2>/dev/null || true
docker compose --env-file .env up -d --no-deps --force-recreate backend || docker-compose --env-file .env up -d --no-deps --force-recreate backend

# 6) Health gate
for i in $(seq 1 36); do
  if curl -fsS "$BE_HEALTH_URL" >/dev/null; then
    echo "Backend healthy"
    exit 0
  fi
  sleep 5
done

echo "Backend failed healthcheck"
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}' --filter name=ecommerce-backend || true
echo "--- container env (safe) ---"
docker exec ecommerce-backend /bin/sh -lc 'tr "\0" "\n" < /proc/1/environ | grep -E "^(DB_|DATABASE_URL|SQL_|PORT=)" || true' || true
echo "--- logs ---"
docker logs ecommerce-backend --tail 300 || true
exit 1
