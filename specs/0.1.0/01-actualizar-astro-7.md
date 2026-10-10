---
code: "01"
title: "Actualizar Astro 5 → 7 y alinear tooling/CI"
project: "cer-molina-ser"
status: completed
version: "0.1.0"
date: 2026-10-10
tags: [spec, sdd]
affected_files:
  - package.json
  - pnpm-lock.yaml
  - src/content/config.ts
  - src/content.config.ts
  - src/pages/noticias/[...slug].astro
  - src/pages/noticias/index.astro
  - src/components/home/Notices.astro
  - src/utils/paths.ts
  - astro.config.mjs
  - tsconfig.json
  - .github/workflows/deploy.yml
  - AGENTS.md
---

# Actualizar Astro 5 → 7 y alinear tooling/CI

## Purpose

Migrar el proyecto de Astro `5.16.6` a la última serie `7.3.x`, corrigiendo los cambios de
ruptura acumulados de v6 y v7, y actualizar las dependencias de tooling y el workflow de
despliegue para que sigan siendo compatibles. Objetivo: seguir en una versión soportada, con
builds más rápidos (Vite 8 / Rolldown / compilador Rust) y sin deuda de migración pendiente.

## Context

- Versión instalada: Astro `5.16.6` (Node local `24.19.0`, cumple el mínimo 22.12 de v6/v7).
- La content collection en `src/content/config.ts` usa la **API legacy** (sin `loader` y en la
  ubicación antigua). Astro v6 eliminó el soporte automático de collections legacy; sin migrar,
  el build falla (`LegacyContentConfigError` / `ContentCollectionMissingALoaderError`).
- El proyecto no usa: `ViewTransitions`, `Astro.glob`, `Astro.site`, adaptadores, sesiones,
  actions ni plugins remark/rehype. `src/fetch.ts` no existe (nombre reservado en v7).
- Dependencias con compatibilidad que debe subirse:
  - `@tailwindcss/vite` solo soporta Vite 8 desde `4.2.2`; actual `4.1.18`.
  - `sharp` mínimo `0.35.4` desde Astro `7.2.8`; actual `^0.34.5`.
  - `@lucide/astro` migró a serie `1.x`; actual `^0.562.0`.
- CI usa `withastro/action@v5`; la versión actual es `@v6` (default Node 24).
- Defaults nuevos de v7 a vigilar: compilador Rust (HTML inválido ahora falla) y
  `compressHTML: 'jsx'` (cambia el manejo de espacios entre elementos inline).

## Proposed change

1. **Content collections → Content Layer API**
   - Mover `src/content/config.ts` a `src/content.config.ts`.
   - Añadir `loader: glob({ pattern: "**/*.md", base: "./src/content/blog" })` importado de
     `astro/loaders`.
   - Importar `z` desde `astro/zod` (en v6 se deprecó `z` desde `astro:content`).
   - Mantener `schema: ({ image }) => z.object({ ... })` (el helper `image()` sigue válido con
     el loader built-in).

2. **APIs de entries**
   - `src/pages/noticias/[...slug].astro`: `entry.slug` → `entry.id`; sustituir
     `await entry.render()` por `import { render } from "astro:content"` + `await render(entry)`.
   - `src/components/home/Notices.astro` (`post.slug`) → `post.id`.
   - `src/pages/noticias/index.astro` (`post.slug`) → `post.id`.

3. **Dependencias (`package.json`)**
   - `astro`: `^5.16.6` → `^7.3` (preferible `pnpm dlx @astrojs/upgrade`).
   - `tailwindcss` y `@tailwindcss/vite`: `^4.1.18` → `>=4.2.2` (objetivo `^4.3`).
   - `sharp`: `^0.34.5` → `>=0.35.4`.
   - `@lucide/astro`: `^0.562.0` → `^1.x`.
   - Alinear `packageManager` con el pnpm instalado (field declara `10.27.0`, CLI local
     `12.10.1`) o fijar vía corepack, para evitar drift.

4. **CI / deploy (`.github/workflows/deploy.yml`)**
   - `withastro/action@v5` → `@v6`.
   - `actions/checkout@v5` → `@v7`.
   - `actions/deploy-pages@v4` → `@v5`.

5. **Ajustes derivados de defaults v7 (solo si QA los detecta)**
   - `compressHTML: 'jsx'`: si faltan espacios entre elementos inline, añadir `{" "}` en el
     componente afectado o fijar `compressHTML: true` en `astro.config.mjs`.
   - Compilador Rust: corregir tags sin cerrar / HTML inválido que aparezca al compilar.
   - Verificar que `astro/tsconfigs/strict` sigue existiendo en v7; ajustar si cambió.

## Technical decision

- **Salto directo 5 → 7** en lugar de escalonado: el único bloqueo duro (collections legacy) se
  resuelve una vez, y un salto escalonado duplicaría upgrades de dependencias y reescrituras del
  lockfile sin beneficio en un proyecto de este tamaño.
- **Una sola spec** cubre Astro + tooling + CI porque el upgrade de Astro arrastra la
  compatibilidad de `@tailwindcss/vite` (Vite 8) y `sharp`; separarlos produciría estados
  intermedios no desplegables.
- Se ejecuta en rama (`chore/astro-7`) con `main` intacto para permitir rollback.
- Sin flag temporal `legacy.collectionsBackwardsCompat`: se migra directamente a la Content
  Layer API, que es la única vía soportada a futuro.

## Affected files

- `package.json` — versiones de dependencias y `packageManager`.
- `pnpm-lock.yaml` — reescritura por el upgrade.
- `src/content/config.ts` — eliminado (movido).
- `src/content.config.ts` — nuevo, con `glob()` loader y `z` desde `astro/zod`.
- `src/pages/noticias/[...slug].astro` — `entry.id` + `render(entry)`.
- `src/pages/noticias/index.astro` — `post.id`.
- `src/components/home/Notices.astro` — `post.id`.
- `astro.config.mjs` — solo si QA requiere `compressHTML`.
- `tsconfig.json` — solo si `astro/tsconfigs/strict` cambió.
- `.github/workflows/deploy.yml` — versiones de las actions.
- `AGENTS.md` — actualizar stack (Astro 7, Vite 8) tras el cierre.

## Tests

No hay framework de tests. Verificación de esta spec:

- `pnpm install` sin errores de peer dependencies.
- `pnpm astro check` sin errores de tipos.
- `pnpm build` genera `dist/` sin errores del compilador Rust.
- QA manual: rutas `/`, `/noticias`, `/noticias/<slug>`, `/adopciones/gatos`, `/contacto`,
  `/gracias`; galería de gatos; formularios (Web3Forms + enlaces Google Forms).
- Revisión visual de espacios entre inline elements (riesgo `compressHTML: 'jsx'`).

## Acceptance criteria

- [x] `src/content.config.ts` existe con loader `glob()` y `z` desde `astro/zod`; `src/content/config.ts` ya no existe.
- [x] No queda ninguna referencia a `entry.slug`/`post.slug` ni a `entry.render()`.
- [x] `astro` en `^7.3`, `@tailwindcss/vite` y `tailwindcss` `>=4.2.2`, `sharp` `>=0.35.4`, `@lucide/astro` `^1.x`.
- [x] `pnpm install`, `pnpm astro check` y `pnpm build` terminan sin errores.
- [x] Listado de noticias y página de detalle renderizan contenido y enlaces correctos.
- [x] Espacios entre inline elements correctos en home/noticias (o `compressHTML: true` justificado).
- [x] `.github/workflows/deploy.yml` usa `withastro/action@v6`, `actions/checkout@v7` y `actions/deploy-pages@v5`.
- [ ] Despliegue a GitHub Pages funcional tras merge a `main`.
- [x] `AGENTS.md` refleja el stack actualizado (Astro 7 / Vite 8) y `00-changelog.md` anotado.
