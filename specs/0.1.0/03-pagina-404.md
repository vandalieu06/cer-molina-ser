---
code: "03"
title: "Página 404 personalizada"
project: "cer-molina-ser"
status: completed
version: "0.1.0"
date: 2026-10-10
tags: [spec, sdd]
affected_files:
  - src/assets/web/404.webp
  - src/pages/404.astro
  - src/layouts/Layout.astro
  - specs/0.1.0/00-changelog.md
---

# Página 404 personalizada

## Purpose

Sustituir la página 404 por defecto por una 404 propia, acorde al sistema de diseño del sitio
(maroon/cream/gold), con la foto `IMG_5259.jpg` de fondo y accesos rápidos de vuelta.

## Context

- No existe `src/pages/404.astro` ni `public/404.*`; al no encontrarse una ruta, GitHub Pages
  muestra su 404 genérica.
- Astro genera `dist/404.html` a partir de `src/pages/404.astro`; GitHub Pages la usa como página
  de error para rutas desconocidas del subpath `/cer-molina-ser`.
- Imagen de fondo disponible: `src/assets/photos_cer_molina/IMG_5259.jpg` (JPEG 6240×4160, ~2.1 MB).
- `src/layouts/Layout.astro` **no** acepta un prop `title`: tiene `<title>` fijo. Algunas páginas
  ya intentan pasar `title` (p. ej. `src/pages/noticias/[...slug].astro`) y se ignora.
- Convención: enlaces/assets internos vía `getPath()` (`@utils/paths`); assets web en
  `src/assets/web/`; imágenes optimizadas con `astro:assets`.

## Proposed change

1. **Optimizar la imagen con ImageMagick** (no copiar el original de 2.1 MB): generar
   `src/assets/web/404.webp` redimensionada a 1920 px de ancho, calidad 80 y sin metadatos:
   ```sh
   magick src/assets/photos_cer_molina/IMG_5259.jpg \
     -resize 1920x -strip -quality 80 src/assets/web/404.webp
   ```
   El original `photos_cer_molina/IMG_5259.jpg` se conserva intacto.

2. **Nueva página `src/pages/404.astro`** que:
   - Usa `Layout` (por defecto Header + Footer).
   - Renderiza el fondo con `<Picture>` de `astro:assets` (no CSS background), posicionado
     `absolute inset-0 object-cover`, con `widths` responsive, `sizes="100vw"`, `format` avif/webp
     y `loading="eager"` + `fetchpriority="high"` (está above-the-fold). Encima, un degradado
     maroon para legibilidad.
   - Muestra: kicker "Error 404", titular en español (p. ej. "Esta página se ha escapado"),
     texto de apoyo, y dos CTAs: "Volver al inicio" (`getPath("/")`) y "Ver gatos en adopción"
     (`getPath("/adopciones/gatos")`).
   - Un icono `Cat` de `@lucide/astro` como detalle decorativo.
   - En modo estático se prerenderiza como `dist/404.html`.

3. **`src/layouts/Layout.astro`**: aceptar un prop opcional `title` y usarlo en `<title>`
   (`{title ?? "CER Molina Segura"}`). Cambio retrocompatible que además hace efectivos los
   `title` ya pasados por otras páginas.

## Technical decision

- Página estática `404.astro` (patrón idiomático de Astro para SSG); sin configuración extra ni
  cambios en `astro.config.mjs`.
- **Optimización de imagen (carga rápida):** generar el asset con ImageMagick a webp q80 y
  1920 px de ancho. El JPEG original es 6240×4160 / ~2.1 MB; el webp resultante baja a un orden de
  cientos de KB y evita servir dimensiones absurdas para un fondo.
- Fondo con `<Picture>` de `astro:assets` (elemento posicionado con `object-cover`) en vez de CSS
  background: habilita `srcset` responsive + formatos modernos (avif/webp) y `loading="eager"`.
- No mover el original de `photos_cer_molina/` (posible galería futura).

## Affected files

- `src/assets/web/404.webp` — nuevo (generado con ImageMagick).
- `src/pages/404.astro` — nuevo.
- `src/layouts/Layout.astro` — prop opcional `title`.
- `specs/0.1.0/00-changelog.md` — entrada al cerrar.

## Tests

- `pnpm astro check` sin errores.
- `pnpm build` genera `dist/404.html` y versiones optimizadas de la imagen.
- Verificación en navegador (agent-browser): abrir una ruta inexistente y comprobar la página; y
  que los CTAs apuntan a `getPath` correctos.

## Acceptance criteria

- [x] Existe `src/assets/web/404.webp` (webp q80, ancho 1920) generado desde `IMG_5259.jpg`; el original sigue intacto.
- [x] El webp pesa claramente menos que el JPEG original (~2.1 MB).
- [x] `src/pages/404.astro` usa `Layout` y muestra el fondo con `<Picture>` responsive + overlay.
- [x] La 404 incluye CTAs a inicio y a adopciones, pasando por `getPath()`.
- [x] `Layout.astro` acepta `title` opcional y lo aplica al `<title>`.
- [x] `pnpm astro check` y `pnpm build` sin errores; `dist/404.html` generado.
- [x] Una URL inexistente muestra la 404 personalizada en el preview.
