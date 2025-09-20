# ===== Build stage =====
FROM node:18-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ===== Runtime stage =====
FROM nginx:alpine

# ننسخ ملفات البناء
COPY --from=build /app/build /usr/share/nginx/html

# نحقن رقم النسخة (الكومِت) في ملف version.txt
ARG COMMIT_SHA=dev
RUN sh -c 'echo "$COMMIT_SHA" > /usr/share/nginx/html/version.txt'

# Nginx confi
 COPY nginx.default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
