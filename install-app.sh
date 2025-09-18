#!/bin/bash
set -e

# تحديث النظام
sudo apt-get update -y

# إزالة أي Docker قديم
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

# تثبيت Docker الرسمي
curl -fsSL https://get.docker.com | sh

# إلغاء الـ mask عن الخدمة
sudo systemctl unmask docker.service || true
sudo systemctl unmask docker.socket || true

# إعادة تحميل systemd
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# تفعيل وتشغيل Docker
sudo systemctl enable docker
sudo systemctl start docker

# تثبيت الأدوات
sudo apt-get install -y docker-compose-plugin git curl

# جلب المشروع (عدّل الرابط على حسب الريبو حقك)
APP_DIR="/home/azureuser/ecommerce-app-three-tier-azure-db-ih"
if [ ! -d "$APP_DIR" ]; then
    git clone https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git $APP_DIR
else
    cd $APP_DIR
    git pull origin main
fi

# تشغيل المشروع
cd $APP_DIR
sudo docker compose up -d --build
