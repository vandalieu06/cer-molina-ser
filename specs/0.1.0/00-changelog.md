# Changelog — 0.1.0

| Fecha | Spec | Cambio |
| ----- | ---- | ------ |
| 2026-10-10 | 01 | Actualizar Astro 5 → 7, migrar content collections a Content Layer API, subir tooling (`@tailwindcss/vite`/`tailwindcss`, `sharp`, `@lucide/astro`) y CI |
| 2026-10-10 | 02 | Corregir enlaces de la home y enlazar el formulario real de adopción |
| 2026-10-10 | 03 | Página 404 personalizada con imagen de fondo optimizada (webp) |
| 2026-10-15 | 04 | Donaciones: eliminar Bizum, IBAN y beneficiario reales de transferencia y enlace de apadrinamiento por correo |
| 2026-10-15 | 05 | Unificar correo de contacto, enlazar formulario de socio y actualizar texto del footer |
| 2026-10-23 | 06 | Dockerfile multi-stage (Node + pnpm → nginx) y `docker-compose.yml` para desplegar en Dokploy; `BASE_PATH`/`SITE_URL` configurables por entorno |
| 2026-11-17 | 07 | Imágenes a webp con nombres normalizados (slugs ASCII), galería con `<Image>` responsiva, PDF convertido y backup de originales en `docs/cer-molina-cer/`: `src/assets` 414 MB → 21 MB |
| 2026-11-17 | 08 | Fondos de Hero, Método CER y Adoptar ahora con `<Picture>` (AVIF/WebP, 3 anchos) en vez de `background-image` CSS |
| 2026-11-17 | 09 | Purga del historial con `git filter-repo` (204 blobs / 413 MB): `.git` 428 MB → 21 MB, con `git bundle` de seguridad previo |
