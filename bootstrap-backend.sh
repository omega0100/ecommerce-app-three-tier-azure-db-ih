#!/bin/bash
set -euxo pipefail

# 1) تحديث
sudo apt-get update -y

# 2) تصليح/تثبيت Docker
sudo systemctl unmask docker.service || true
sudo systemctl unmask docker.socket || true
sudo apt-get remove -y docker docker-engine docker.io containerd runc containerd.io || true
curl -fsSL https://get.docker.com | sh
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker azureuser || true

# 3) أدوات
sudo apt-get install -y docker-compose-plugin git curl

# 4) جلب/تحديث الكود بدون ما نكسر .env
APP_DIR="/home/azureuser/ecommerce-app-three-tier-azure-db-ih"
REPO_URL="https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git"   # عدّل هذا

# اجعل Git يتجاهل تحذير "unsafe repository" لو تغيرت الملكية
sudo -u azureuser git config --global safe.directory '*'

if [ ! -d "$APP_DIR/.git" ]; then
  sudo rm -rf "$APP_DIR" || true
  sudo -u azureuser git clone "$REPO_URL" "$APP_DIR"
else
  cd "$APP_DIR"
  sudo -u azureuser git fetch --all --prune
  # يمسح تعديلات الملفات المتتبعة فقط ويترك .env (غير متتبعة وموجودة بـ .gitignore)
  sudo -u azureuser git reset --hard origin/main
fi

# 5) تأكد من وجود .env للباك-إند (لا تكتب عليه لو موجود)
cd "$APP_DIR/ecommerce-app-backend"
if [ ! -f ".env" ]; then
  cat > .env <<'EOF'
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
  chown azureuser:azureuser .env
fi

# 6) تشغيل خدمة backend فقط
cd "$APP_DIR"
sudo docker compose pull || true
sudo docker compose up -d --build backend

# 7) فحص صحّة
sleep 5
curl -sf http://localhost:3001/health || exit 1
