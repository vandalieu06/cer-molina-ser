# syntax=docker/dockerfile:1

# ---------- build ----------
FROM node:24-bookworm-slim AS build

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

RUN corepack enable && corepack install -g pnpm@12.10.1

WORKDIR /app

# Copiar primero los manifests para cachear la capa de dependencias
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

# BASE_PATH="/" sirve el sitio en la raíz del dominio (Traefik). No es un ARG a propósito:
# un build con subpath generaría rutas /cer-molina-ser/* que este nginx (root plano) no sirve.
# Sin variable, astro.config.mjs mantiene el subpath de GitHub Pages.
ENV BASE_PATH=/
ARG SITE_URL

ENV SITE_URL=$SITE_URL
ENV NODE_ENV=production

RUN pnpm build

# ---------- runtime ----------
FROM nginx:1.29-alpine AS runtime

RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
