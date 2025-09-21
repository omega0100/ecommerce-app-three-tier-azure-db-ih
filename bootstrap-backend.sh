#!/usr/bin/env bash
# يوزّع خدمة backend على جميع الـVMs في VMSS عبر az vm run-command
set -euo pipefail

# متغيّرات مطلوبة (تيجي من env أو من v.sh)
: "${RG:?missing RG}"
: "${VMSS_BE:?missing VMSS_BE}"
: "${APP_DIR:?missing APP_DIR}"
: "${ACR_NAME:?missing ACR_NAME}"
: "${ACR_LOGIN_SERVER:?missing ACR_LOGIN_SERVER}"
: "${RAW_URL:?missing RAW_URL}"                # رابط docker-compose.yml (Raw)
: "${IMAGE_TAG:?missing IMAGE_TAG}"            # تاج الصورة (SHA أو latest)
: "${BE_HEALTH_URL:?missing BE_HEALTH_URL}"    # مثال: http://127.0.0.1:3001/health

# أسرار قاعدة البيانات لازم تكون متوفرة بالـenv
for v in DB_HOST DB_USER DB_PASSWORD DB_NAME; do
  [ -n "${!v:-}" ] || { echo "missing secret: $v"; exit 1; }
done

# (اختياري) معلومات للتشخيص
az account show -o table || true
az vmss show -g "$RG" -n "$VMSS_BE" -o table || true
az vmss list-instances -g "$RG" -n "$VMSS_BE" -o table || true

# لستة الـVMs
mapfile -t NAMES < <(az vmss list-instances -g "$RG" -n "$VMSS_BE" --query "[].name" -o tsv)
[ ${#NAMES[@]} -gt 0 ] || { echo "no instances in $VMSS_BE"; exit 1; }

# سكربت يُنفَّذ داخل كل VM
read -r -d '' REMOTE <<'EOS'
set -euxo pipefail
APP_DIR="__APP_DIR__"
ACR_NAME="__ACR_NAME__"
ACR_LOGIN_SERVER="__ACR_LOGIN_SERVER__"
RAW_URL="__RAW_URL__"
IMAGE_TAG="__TAG__"
HEALTH_URL="__HEALTH_URL__"
DB_HOST="__DB_HOST__"
DB_USER="__DB_USER__"
DB_PASSWORD="__DB_PASSWORD__"
DB_NAME="__DB_NAME__"

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

# 1) جلب compose
mkdir -p "$APP_DIR" && cd "$APP_DIR"
curl -fsSL "$RAW_URL" -o docker-compose.yml

# 2) كتابة .env (بدون طباعة الباسوورد)
{
  echo "ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER"
  echo "IMAGE_TAG=$IMAGE_TAG"
  echo "DB_HOST=$DB_HOST"
  echo "DB_USER=$DB_USER"
  echo "DB_PASSWORD=$DB_PASSWORD"
  echo "DB_NAME=$DB_NAME"
} > .env
echo "--- .env (safe) ---"
grep -E '^(ACR_LOGIN_SERVER|IMAGE_TAG|DB_HOST|DB_NAME)=' .env || true

# 3) ACR login عبر MSI
if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi
az login --identity >/dev/null
TOKEN=$(az acr login -n "$ACR_NAME" --expose-token --query accessToken -o tsv)
echo "$TOKEN" | docker login "$ACR_LOGIN_SERVER" -u 00000000-0000-0000-0000-000000000000 --password-stdin

# 4) تشغيل الحاوية
docker compose --env-file .env pull backend || docker-compose --env-file .env pull backend
docker rm -f ecommerce-backend 2>/dev/null || true
docker compose --env-file .env up -d --no-deps --force-recreate backend || docker-compose --env-file .env up -d --no-deps --force-recreate backend

# 5) Health gate
for i in $(seq 1 36); do
  if curl -fsS "$HEALTH_URL" >/dev/null; then
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
EOS

# استبدال القوالب بالقيم الفعلية
REMOTE=${REMOTE//__APP_DIR__/$APP_DIR}
REMOTE=${REMOTE//__ACR_NAME__/$ACR_NAME}
REMOTE=${REMOTE//__ACR_LOGIN_SERVER__/$ACR_LOGIN_SERVER}
REMOTE=${REMOTE//__RAW_URL__/$RAW_URL}
REMOTE=${REMOTE//__TAG__/$IMAGE_TAG}
REMOTE=${REMOTE//__HEALTH_URL__/$BE_HEALTH_URL}
REMOTE=${REMOTE//__DB_HOST__/$DB_HOST}
REMOTE=${REMOTE//__DB_USER__/$DB_USER}
REMOTE=${REMOTE//__DB_PASSWORD__/$DB_PASSWORD}
REMOTE=${REMOTE//__DB_NAME__/$DB_NAME}

B64=$(printf '%s' "$REMOTE" | base64 -w0)

# التنفيذ على كل VM
for VM in "${NAMES[@]}"; do
  echo "::group::BACKEND on $VM"
  az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
    --query "value[0].message" -o tsv \
    --scripts "bash -lc 'echo $B64 | base64 -d > /tmp/run.sh && bash /tmp/run.sh'"
  echo "::endgroup::"
done
