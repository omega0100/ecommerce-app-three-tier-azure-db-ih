#!/bin/bash
set -euxo pipefail

# ==== 0) ثوابت ====
APP_DIR="/home/azureuser/ecommerce-app-three-tier-azure-db-ih"
REPO_URL="https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git"
BRANCH="main"   # غيّرها لو فرعك غير

# ==== 1) تحديث النظام ====
sudo apt-get update -y

# ==== 2) Docker ====
sudo systemctl unmask docker.service || true
sudo systemctl unmask docker.socket || true
# لا نحذف Docker كل مرة؛ فقط نثبته لو مهو موجود
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker azureuser || true
else
  sudo systemctl enable docker || true
  sudo systemctl start docker || true
fi

# أدوات لازمة
sudo apt-get install -y docker-compose-plugin git curl

# ==== 3) جلب/تحديث الكود كـ azureuser ====
if [ ! -d "$APP_DIR/.git" ]; then
  sudo rm -rf "$APP_DIR" || true
  sudo -H -u azureuser bash -lc "git clone --depth 1 -b $BRANCH '$REPO_URL' '$APP_DIR'"
else
  sudo -H -u azureuser bash -lc "cd '$APP_DIR' && git fetch --all --prune && git reset --hard origin/$BRANCH"
fi

# تأكد الملكية للمجلد
sudo chown -R azureuser:azureuser "$APP_DIR"

# ==== 4) .env للباك اند (لا نكتب لو موجود) ====
BACKEND_ENV="$APP_DIR/ecommerce-app-backend/.env"
if [ ! -f "$BACKEND_ENV" ]; then
  cat > "$BACKEND_ENV" <<'EOF'
PORT=3001
NODE_ENV=production
DB_SERVER=sqlserver-group4.database.windows.net
DB_PORT=1433
DB_NAME=group4db
DB_USER=user-admine-group4
DB_PASSWORD=Gr@123456
DB_ENCRYPT=true
DB_TRUST_SERVER_CERT=false
JWT_SECRET=Group4
JWT_EXPIRES_IN=7d
CORS_ORIGIN=http://4.245.59.253:3000
EOF
  sudo chown azureuser:azureuser "$BACKEND_ENV"
fi

# ==== 5) تشغيل backend فقط ====
cd "$APP_DIR"
# نبقي docker كـ root لضمان الصلاحيات
sudo docker compose pull || true
sudo docker compose up -d --build backend

# ==== 6) فحص الصحة ====
sleep 5
curl -sf http://localhost:3001/health
