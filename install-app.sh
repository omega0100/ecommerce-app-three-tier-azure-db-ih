#!/bin/bash
set -e

# تحديث النظام
sudo apt-get update -y

# إزالة أي Docker قديم
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

# تثبيت Docker الرسمي
curl -fsSL https://get.docker.com | sh

# إصلاح مشكلة الـ masking
sudo systemctl unmask docker || true
sudo systemctl unmask docker.socket || true
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker

# تثبيت الأدوات
sudo apt-get install -y docker-compose-plugin git curl

# جلب الكود (تقدر تغيّر رابط الريبو لرابطك الخاص)
APP_DIR="/home/azureuser/ecommerce-app-three-tier-azure-db-ih"
if [ ! -d "$APP_DIR" ]; then
    git clone https://github.com/<username>/<repo>.git $APP_DIR
else
    cd $APP_DIR
    git pull origin main
fi

# الدخول للمشروع
cd $APP_DIR

# تشغيل المشروع
sudo docker compose up -d --build
