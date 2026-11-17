---
code: "06"
title: "Dockerfile para desplegar en Dokploy (nginx multi-stage)"
project: "cer-molina-ser"
status: completed
version: "0.1.0"
date: 2026-10-23
tags: [spec, sdd, deploy, docker]
affected_files:
  - Dockerfile
  - .dockerignore
  - docker-compose.yml
  - nginx/default.conf
  - astro.config.mjs
  - README.md
  - specs/0.1.0/00-changelog.md
---

# Dockerfile para desplegar en Dokploy (nginx multi-stage)

## Purpose

Poder desplegar el sitio en el VPS del usuario (Dokploy, que pone Traefik delante) con un
contenedor reproducible, manteniendo intacto el despliegue actual a GitHub Pages.

## Context

- El sitio es **estático puro** (`astro build` → `dist/`), sin SSR, ni API routes, ni
  `@astrojs/node`. En producción no necesita Node: solo servir ficheros.
- `dist/` pesa ~112 MB (fotos de gatos y webp del build), por lo que el peso del contenedor lo
  domina el contenido, no el runtime.
- `astro.config.mjs` fija `base: "/cer-molina-ser"` y `site: "https://vandalieu06.github.io"`
  (GitHub Pages). Con ese `base`, si se sirve en la raíz del dominio todos los assets
  (`/_astro/*`, `/logo.jpg`) devuelven 404: el `base` se cuece en el HTML en build time.
- El único punto que depende del `base` es `getPath()` (`src/utils/paths.ts`), que lee
  `import.meta.env.BASE_URL`; no hay rutas absolutas hardcodeadas en `src/`
  (verificado con grep: cero coincidencias de `cer-molina-ser` fuera del config).
- `Astro.site` no se usa en ningún componente (grep: cero coincidencias), así que `site` solo
  afecta a canonical/OG futuros.
- **Prueba de viabilidad ya realizada** (en `/tmp`, sin tocar el repo): `podman build` con
  `node:24-bookworm-slim` + `corepack` + pnpm 12.10.1 + `nginx:1.29-alpine` compila el sitio,
  sirve `/` con 200, los assets `/_astro/*.css` con 200 y devuelve 404 en rutas inexistentes.
  Imagen resultante: **181 MB**.
- Gotcha detectado en esa prueba: si `SITE_URL` llega como cadena vacía, `?? fallback` **no**
  aplica y Astro falla con `Invalid URL`. Hay que usar `||` en el config.
- Dokploy construye el Dockerfile y enruta el dominio con Traefik; el contenedor solo debe
  exponer un puerto HTTP plano (sin TLS, sin labels de Traefik obligatorios).

## Proposed change

1. **`astro.config.mjs`**: parametrizar `base` y `site` por entorno, conservando los valores
   actuales de GitHub Pages como defecto:

   ```js
   const base = process.env.BASE_PATH || "/cer-molina-ser";
   const site = process.env.SITE_URL || "https://vandalieu06.github.io";
   ```

   GitHub Pages no pasa esas variables → sigue compilando en `/cer-molina-ser`.

2. **`Dockerfile`** multi-stage (el validado en la prueba):

   - Etapa `build`: `node:24-bookworm-slim` (glibc, `sharp` sin complicaciones), `corepack` para
     activar `pnpm@12.10.1`, copia de `package.json` + `pnpm-lock.yaml` + `pnpm-workspace.yaml`
     antes del código para cachear capas, `pnpm install --frozen-lockfile`, luego `COPY . .` y
     `pnpm build` con `ENV BASE_PATH=/` (fijo) y `ARG SITE_URL` (opcional).
     `BASE_PATH` **no** es un ARG: con un subpath, Astro emitiría rutas `/cer-molina-ser/*` que
     este nginx (root plano) no sirve, así que el contenedor solo soporta la raíz.
   - Etapa `runtime`: `nginx:1.29-alpine`, copia `dist/` a `/usr/share/nginx/html`,
     `nginx/default.conf`, `EXPOSE 80`, `HEALTHCHECK` con `wget --spider` y
     `CMD ["nginx", "-g", "daemon off;"]`.
   - Nginx corre como root dentro del contenedor (Dokploy no es rootless) y escucha en 80.

3. **`nginx/default.conf`**:

   ```nginx
   server {
     listen 80;
     server_name _;
     root /usr/share/nginx/html;
     index index.html;

     # detras de Traefik (TLS terminado fuera): redirects relativos
     absolute_redirect off;

     gzip on;
     gzip_types text/css application/javascript image/svg+xml application/json;

     # assets con hash: cache agresivo
     location /_astro/ {
       add_header Cache-Control "public, max-age=31536000, immutable";
       try_files $uri =404;
     }

     location / {
       try_files $uri $uri/ $uri.html =404;
       add_header Cache-Control "public, max-age=0, must-revalidate";
     }

     # 404 propia de Astro (dist/404.html)
     error_page 403 404 /404.html;
     location = /404.html {
       internal;
     }
   }
   ```

4. **`.dockerignore`**: `node_modules/`, `dist/`, `.astro/`, `.git/`, `.github/`, `specs/`,
   `docs/`, `.agents/`, `*.md`, `.env*`, `skills-lock.json`, `Dockerfile`, `docker-compose.yml`.
   Reduce el contexto de build y evita que un `node_modules` local contamine la imagen.

5. **`docker-compose.yml`** de ejemplo para Dokploy (proveedor *Docker Compose*). Se usa el
   nombre legacy **a propósito**: el `compose_path` por defecto de Dokploy es
   `./docker-compose.yml`, y su UI tiene un bug conocido (issue #2282) al arrancar/parar el
   servicio cuando se configura una ruta de compose distinta:

   ```yaml
   services:
     web:
       build:
         context: .
         dockerfile: Dockerfile
         # Opcional (build-time): Astro.site. Hoy no se usa en el código.
         # args:
         #   SITE_URL: ${SITE_URL:-}
       expose:
         - "80"
       # Para probar en local sin Dokploy, descomenta:
       # ports:
       #   - "8080:80"
       restart: unless-stopped
       healthcheck:
         test: ["CMD", "wget", "-q", "--spider", "http://127.0.0.1/"]
         interval: 30s
         timeout: 3s
         retries: 3
   ```

   En Dokploy el dominio se asocia desde la pestaña *Domains* del servicio (servicio `web`,
   puerto `80`); Dokploy genera las labels de Traefik y conecta la red, así que no se publican
   puertos al host.

6. **`README.md`**: sección "Despliegue con Docker" con los comandos
   (`docker build -t cer-molina-ser .`, `docker run -p 8080:80 ...`), la nota del `BASE_PATH`
   y los pasos en Dokploy (tipo Dockerfile, puerto `80`, dominio y TLS los gestiona Traefik).

7. **Sección "Dokploy" en `README.md`** con la tabla de variables y los ajustes del panel
   (ver *Configuración en Dokploy*).

## Configuración en Dokploy

Dokploy tiene tres formas de desplegar y aquí solo dos aplican:

| Modo Dokploy | Qué hace | ¿Usa el `Dockerfile`? |
| --- | --- | --- |
| **Application → Dockerfile** | Dokploy hace `docker build` del repo y enruta el puerto | Sí, directamente |
| **Compose → `docker-compose.yml`** | Dokploy hace `docker compose up --build`; el `build: .` del compose invoca el Dockerfile | Sí, indirectamente |
| **Application → Docker image** | Descarga una imagen ya publicada de un registry (Docker Hub, GHCR…) | No (se construye en CI) |

El tercer modo (imagen preconstruida) **no** se usa aquí: obligaría a un CI que publique la imagen
y a gestionar registry/credenciales, sin ventaja para un sitio estático.

El `Dockerfile` es **obligatorio en los dos modos que sí aplican**; el `docker-compose.yml` es
solo la orquestación (servicio, puerto, healthcheck). Con un único servicio, el modo
*Application → Dockerfile* tiene menos piezas; el compose aporta poder reproducir el despliegue en
local con `docker compose up`.

Variables de entorno: **ninguna en runtime**. El contenedor solo sirve ficheros, así que las
variables de la pestaña *Environment* no llegan al build y no afectan en nada.

Solo hay **dos build args**, ambos opcionales porque el `Dockerfile` trae defaults:

| Variable | Obligatoria | Default (Docker) | Default (sin env, GH Pages) | Para qué |
| --- | --- | --- | --- | --- |
| `BASE_PATH` | No (fijada) | `/` (`ENV` en el Dockerfile) | `/cer-molina-ser` | Prefijo de todas las rutas. La imagen solo soporta `/` |
| `SITE_URL` | No | vacío (no usado) | `https://vandalieu06.github.io` | Solo `Astro.site` (canonical/OG si se añaden). Vacío es válido |

`SITE_URL` **no se configura en el despliegue inicial**: Dokploy genera el dominio por su cuenta
(`*.sslip.io` o el que asignes después) y ese valor cambia. Además hoy `Astro.site` no se usa en
ningún componente, así que dejarlo vacío no rompe nada. Solo tiene sentido rellenarlo el día que
se añadan canonical/OG tags y el dominio final sea estable (requiere rebuild, es build-time).

Dónde se ponen en Dokploy:

- **Application → Build Type: Dockerfile** (recomendado): **no hay ningún build arg obligatorio**;
  la imagen compila con `BASE_PATH=/` de serie. Solo si algún día se quiere `SITE_URL`, se pone en
  la pestaña *Environment* → **Build Time Arguments** (nunca en las variables de runtime).
- **Compose**: no requiere `build.args`; el ejemplo los deja comentados.

Ajustes del panel (modo Application / Dockerfile):

- `Dockerfile Path`: `Dockerfile` · `Docker Context Path`: `.`
- **`Docker Build Stage`: dejar VACÍO.** Si se rellena con `build`, la imagen final sería la
  etapa de Node sin nginx.
- **Port** del servicio: `80`. Traefik añade 443/TLS y el dominio.
- El puerto 80 se publica solo en la red interna de Docker (`expose`); no hace falta mapearlo al
  host si Dokploy enruta por Traefik.

## Technical decision

- **nginx estático en vez de `astro preview`**: `preview` no es un servidor de producción
  (sin cache headers, sin 404 configurable) y arrastra Node (~500 MB frente a 181 MB).
- **`node:24-bookworm-slim` y no Alpine** para el build: `sharp` usa binarios nativos; con glibc
  se evita cualquier problema de musl/prebuilds. La imagen final sí es Alpine.
- **Dos destinos con un solo repo**: GitHub Pages compila sin variables y mantiene el subpath
  `/cer-molina-ser`; el contenedor fuerza `BASE_PATH=/` y sirve en la raíz del dominio.
  El contenedor **no** sirve subpaths (el `dist/` no contiene la carpeta del base), así que
  `BASE_PATH` no se expone como build arg para no poder generar una imagen rota.
- **`absolute_redirect off`**: detrás de Traefik el TLS termina fuera; sin esto nginx emitiría
  `Location: http://…` y añadiría un salto/loop. Los 301 de directorio salen relativos.
- **Cache**: `/_astro/` inmutable a 1 año (nombre con hash) y HTML con `must-revalidate`, para que
  un redeploy se vea al instante.
- **`error_page 403 404`**: un directorio sin `index.html` también cae en la 404 propia en vez de
  devolver un 403 de nginx.
- **Sin labels de Traefik** en el compose: Dokploy las inyecta al asociar el dominio, y añadirlas
  a mano chocaría con su configuración.
- **Sin `USER` no-root**: la imagen base `nginx:alpine` necesita root para el master process;
  si en el futuro se quiere rootless, se cambia a `nginxinc/nginx-unprivileged` (puerto 8080).

## Affected files

- `Dockerfile` — nuevo.
- `.dockerignore` — nuevo.
- `nginx/default.conf` — nuevo.
- `docker-compose.yml` — nuevo (ejemplo para Dokploy).
- `astro.config.mjs` — `base`/`site` desde env con fallback a los valores actuales.
- `README.md` — sección de despliegue con Docker.
- `specs/0.1.0/00-changelog.md` — entrada al cerrar.

## Tests

Ejecutados con `podman` (el daemon de Docker no estaba activo en la máquina):

- `podman build --no-cache` de la imagen sin errores (14 pasos de build + 7 de runtime).
- Contenedor arriba: `GET /` → 200, `/adopciones/gatos/` → 200, `/sobre-nosotros/` → 200,
  `/_astro/*.css` → 200 (con `Cache-Control: public, max-age=31536000, immutable` y gzip) y
  `GET /no-existe` → 404 **con la página 404 propia**.
- `GET /adopciones/gatos` → 301 con `Location: /adopciones/gatos/` **relativo** (sin `http://`).
- `pnpm build` sin variables → `dist/index.html` sigue referenciando `/cer-molina-ser/...`
  (GitHub Pages preservado).
- `pnpm astro check` → 0 errores.
- Healthcheck del contenedor: `wget --spider http://127.0.0.1/` → OK.
- Regresión: el workflow `deploy.yml` no se toca.

## Acceptance criteria

- [x] Existe `Dockerfile` multi-stage (build Node/pnpm + runtime nginx) y compila sin errores.
- [x] Existe `.dockerignore` que excluye `node_modules/`, `dist/`, `.git/`, `.astro/` y `specs/`.
- [x] La imagen sirve el sitio en `/` (`BASE_PATH=/`) con assets y páginas internas en 200.
- [x] Una ruta inexistente devuelve 404 con la página `404.html` del proyecto, no la de nginx.
- [x] `pnpm build` sin variables sigue compilando con `/cer-molina-ser` (GitHub Pages intacto).
- [x] `astro.config.mjs` tolera `BASE_PATH`/`SITE_URL` vacíos (fallback con `||`).
- [x] `docker-compose.yml` de ejemplo con puerto 80 del contenedor y healthcheck, listo para Dokploy.
- [x] `README.md` documenta el despliegue con Docker y el paso a paso en Dokploy.
- [x] `pnpm astro check` y `pnpm build` siguen pasando en local.
