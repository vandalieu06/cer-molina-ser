---
code: "02"
title: "Corregir enlaces de la home y enlazar formulario de adopción"
project: "cer-molina-ser"
status: completed
version: "0.1.0"
date: 2026-10-10
tags: [spec, sdd]
affected_files:
  - src/data/links.ts
  - src/components/home/Hero.astro
  - src/components/home/Services.astro
  - src/components/adopciones/FormularioAdopcion.astro
  - specs/0.1.0/00-changelog.md
---

# Corregir enlaces de la home y enlazar formulario de adopción

## Purpose

Arreglar los enlaces rotos de la home (`/**`) que no llevan a las páginas correctas y enlazar el
botón "Adoptar" con el formulario real de adopción. También dejar los enlaces internos
compatibles con el subpath `/cer-molina-ser`.

## Context

Estado actual (verificado):

- `src/components/home/Hero.astro:25` — `href="/adopciones"` sin `getPath()`; bajo `base` da 404.
- `src/components/home/Services.astro` — CTAs con rutas absolutas escritas a mano y sin `getPath()`:
  - "Adoptar" → `href="/adopta"` (ruta **inexistente**).
  - "Información para donar" → `href="/donar"` (ruta **inexistente**).
  - "Quiero ser voluntario" → `href="/voluntariado"` (ruta correcta, pero sin base).
- `src/components/adopciones/FormularioAdopcion.astro:12` — `href="GOOGLE_FORM_URL_ADOPCION"` (placeholder).
- `src/components/voluntariado/FormVoluntariados.astro:20` — `href="GOOGLE_FORM_URL_VOLUNTARIADO"` (sigue placeholder; el formulario de voluntariado **no** forma parte de esta spec).

Regla del repo: todo enlace/asset interno debe pasar por `getPath()` de `@utils/paths` (ver `AGENTS.md`).

## Proposed change

1. **Nuevo `src/data/links.ts`** con la URL real del formulario de adopción como fuente única:
   ```ts
   export const ADOPTION_FORM_URL =
     "https://docs.google.com/forms/d/e/1FAIpQLSdki74okfXOeDqiX-YLepdKr16wm3xGk-8C0uN4wyFbni9ymQ/viewform";
   ```

2. **`src/components/home/Hero.astro`** — "Informate ahora" → `href={getPath("/adopciones")}`.

3. **`src/components/home/Services.astro`**
   - Envolver todos los `href` en `getPath()`.
   - Añadir el campo opcional `external?: boolean` a `Service`.
   - "Adoptar" → `href: ADOPTION_FORM_URL`, `external: true` (abre en pestaña nueva).
   - "Información para donar" → `getPath("/donaciones")`.
   - "Quiero ser voluntario" → `getPath("/voluntariado")`.
   - En el `<a>`: `target={service.external ? "_blank" : undefined}` y
     `rel={service.external ? "noopener noreferrer" : undefined}`.

4. **`src/components/adopciones/FormularioAdopcion.astro`** — sustituir el placeholder
   `GOOGLE_FORM_URL_ADOPCION` por `ADOPTION_FORM_URL`.

## Technical decision

- Centralizar las URLs de formularios externos en `src/data/links.ts` (evita duplicar el string
  entre la home y la página de adopciones; espacio natural para el formulario de voluntariado más
  adelante).
- El CTA "Adoptar" de la home abre el formulario externo en pestaña nueva (`target="_blank"` +
  `rel="noopener noreferrer"`), igual que el botón de la página de adopciones.

## Affected files

- `src/data/links.ts` — nuevo.
- `src/components/home/Hero.astro`.
- `src/components/home/Services.astro`.
- `src/components/adopciones/FormularioAdopcion.astro`.
- `specs/0.1.0/00-changelog.md` — entrada al cerrar.

## Tests

- `pnpm astro check` sin errores.
- `pnpm build` OK.
- Verificación en navegador (agent-browser) de los 4 enlaces de la home y del formulario.

## Acceptance criteria

- [x] "Informate ahora" navega a `/cer-molina-ser/adopciones`.
- [x] "Adoptar" abre el formulario de Google (URL real) en pestaña nueva.
- [x] "Información para donar" navega a `/cer-molina-ser/donaciones`.
- [x] "Quiero ser voluntario" navega a `/cer-molina-ser/voluntariado`.
- [x] `FormularioAdopcion.astro` usa `ADOPTION_FORM_URL` (sin placeholder `GOOGLE_FORM_URL_ADOPCION`).
- [x] Todos los enlaces internos pasan por `getPath()`; ningún 404 en la home.
- [x] `pnpm astro check` y `pnpm build` sin errores.
