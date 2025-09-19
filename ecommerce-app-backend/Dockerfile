# --------- build stage ---------
FROM node:20-alpine AS build
WORKDIR /app

# تثبيت كل الحزم (بما فيها dev مثل typescript)
COPY package*.json ./
RUN npm ci

# نسخ السورس وبناء TypeScript
COPY . .
RUN npm run build

# تحضير node_modules للبرودكشن فقط
RUN npm ci --only=production && npm cache clean --force

# --------- runtime stage ---------
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app

# ننسخ فقط ما نحتاجه للتشغيل
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package*.json ./

EXPOSE 3001
# شغّل حسب سكربتاتك (اختَر واحدة حسب package.json لديك)
CMD ["node","dist/server.js"]
# أو:
# CMD ["npm","run","start"]
