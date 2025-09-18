#!/bin/bash
set -euxo pipefail

cd /tmp

APP_DIR="/home/azureuser/ecommerce-app-three-tier-azure-db-ih"
REPO_URL="https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git"
BRANCH="main"

# تأكد من Docker
sudo apt-get update -y
sudo systemctl unmask docker.service || true
sudo systemctl unmask docker.socket || true
command -v docker || { curl -fsSL https://get.docker.com | sh; }
sudo systemctl enable docker
sudo systemctl start docker

# أدوات
sudo apt-get install -y docker-compose-plugin git curl

# جلب/تحديث الكود
if [ ! -d "$APP_DIR/.git" ]; then
  sudo rm -rf "$APP_DIR" || true
  sudo -H -u azureuser git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
else
  sudo -H -u azureuser bash -lc "cd '$APP_DIR' && git fetch --all --prune && git reset --hard origin/$BRANCH"
fi
sudo chown -R azureuser:azureuser "$APP_DIR"

# ====== أهم خطوة: اكتب .env في جذر المشروع (حيث docker-compose.yml) ======
ROOT_ENV="$APP_DIR/.env"
if [ ! -f "$ROOT_ENV" ]; then
  cat > "$ROOT_ENV" <<'EOF'
# Compose .env (يُستخدم لاستبدال ${...} داخل docker-compose.yml)

# Backend ENV
DB_SERVER=sqlserver-group4.database.windows.net
DB_NAME=group4db
DB_USER=user-admine-group4
DB_PASSWORD=Gr@123456
DB_ENCRYPT=true
DB_TRUST_SERVER_CERTIFICATE=false

# بعض التطبيقات تسميه بشكل مختلف، نخلي الاثنين احتياط
DB_TRUST_SERVER_CERT=false

JWT_SECRET=Group4
JWT_EXPIRES_IN=7d
CORS_ORIGIN=http://4.245.59.253:3000
EOF
  chown azureuser:azureuser "$ROOT_ENV"
fi

# (اختياري) لو تبغى نفس القيم داخل backend/.env أيضاً:
BACKEND_ENV="$APP_DIR/ecommerce-app-backend/.env"
if [ ! -f "$BACKEND_ENV" ]; then
  cp "$ROOT_ENV" "$BACKEND_ENV"
  chown azureuser:azureuser "$BACKEND_ENV"
fi

# شغّل الباك-إند فقط
cd "$APP_DIR"
sudo docker compose pull || true
sudo docker compose up -d --build backend

# فحص صحّة مع لوج عند الفشل
sleep 8
if ! curl -sf http://localhost:3001/health >/dev/null; then
  echo "==== docker ps ===="
  docker ps || true
  echo "==== backend logs (last 200) ===="
  docker logs --tail 200 ecommerce-backend || true
  exit 52
fi
