# build
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# nginx
FROM nginx:alpine
ARG COMMIT_SHA
COPY --from=build /app/build /usr/share/nginx/html
RUN sh -c 'echo "$COMMIT_SHA" > /usr/share/nginx/html/version.txt'
COPY nginx.default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
