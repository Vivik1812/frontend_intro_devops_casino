#ETAPA 1: Builder
FROM node:20-alpine AS builder

WORKDIR /app 

COPY package*.json ./

RUN if [ -f package-lock.json ]; then \
        echo ">>> package-lock.json encontrado: usando npm ci"; \
        npm ci; \
    else \
        echo ">>> AVISO: package-lock.json NO encontrado, usando npm install"; \
        echo ">>> Genera el lockfile con 'npm install' en tu host y commitealo."; \
        npm install; \
        fi

COPY . .

RUN npm run build && \
    mkdir -p /app/build-output && \
    ( cp -r /app/dist/*/browser/* /app/build-output/ 2>/dev/null || \
      cp -r /app/dist/*/* /app/build-output/ )

#ETAPA 2: Runtime
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

LABEL maintainer="Frontend Casino"
LABEL descripcion="Frontend Angular - Casino"

COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder --chown=nginx:nginx /app/build-output /usr/share/nginx/html/

USER nginx 
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/ > /dev/null || exit 1