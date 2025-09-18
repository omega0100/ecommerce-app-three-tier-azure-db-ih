#!/bin/bash
set -euxo pipefail

# 1) تحديث
sudo apt-get update -y

# 2) تثبيت/تصليح Docker
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

# 4) جلب الكود (عدّل الرابط لريبوك)
APP_DIR="/home/azureuser/ecommerce-app-three-tier-azure-db-ih"
if [ ! -d "$APP_DIR" ]; then
  sudo -u azureuser git clone https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git "$APP_DIR"
else
  cd "$APP_DIR"
  sudo -u azureuser git pull --rebase
fi

# 5) .env للباك-إند (اختياري لو مو موجود)
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

# 6) شغل خدمة الباك-إند فقط من الـ compose
cd "$APP_DIR"
sudo docker compose pull || true
sudo docker compose up -d --build backend

# 7) تأكيد الصحّة
sleep 5
curl -sf http://localhost:3001/health || exit 1
