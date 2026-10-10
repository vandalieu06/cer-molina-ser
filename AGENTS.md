# AGENTS.md

Agents working in this repo must follow the SDD workflow at the bottom of this file.

## Project
Static website for **CER Molina Segura**, a Spanish cat-protection nonprofit (colonias felinas,
adopciones, voluntariado, donaciones). Content/copy is in **Spanish**. Site is served from the
GitHub Pages subpath `/cer-molina-ser`.

## Stack
- **Astro 7** (static SSG, Vite 8 / Rolldown) + **TypeScript** (`astro/tsconfigs/strict`; pin
  `typescript@^6` — `astro check` no soporta TS 7 todavía)
- **Tailwind CSS v4.3** via `@tailwindcss/vite` — tokens are defined in `src/styles/global.css`
  under `@theme`; there is **no** `tailwind.config.js`
- **pnpm 12** (`packageManager` field) — use pnpm, not npm/yarn
- `@lucide/astro` 1.x (icons), `sharp` 0.35 + `astro:assets` (image optimization)
- Astro **content collections** in `src/content/blog` (schema + `glob()` loader in
  `src/content.config.ts`)
- Deploy: GitHub Actions (`withastro/action@v6`) → GitHub Pages on push to `main`

## Commands
- `pnpm install` — deps (not committed; `node_modules` absent on fresh checkout)
- `pnpm dev` — dev server at `localhost:4321`
- `pnpm build` — build to `dist/`
- `pnpm preview` — preview the build
- `pnpm astro check` — typecheck (needs `@astrojs/check` + `typescript` devDeps); there is no lint,
  test, or format script

## Critical conventions & gotchas
- **Always route internal links/assets through `getPath()`** from `@utils/paths`. The site uses
  `base: "/cer-molina-ser"`, so hand-written absolute paths (`/foo`) break. Use it for `href`,
  `src`, and `import.meta.env.BASE_URL`-relative references.
- **Pages are thin wrappers**: `src/pages/**/*.astro` compose section components from
  `src/components/<section>/*` (e.g. `home/`, `adopciones/`, `contacto/`).
- **Navigation source of truth** is `src/data/pages.ts` (add/remove pages there, not in `Header`).
- **Cat gallery is folder-driven**: `src/pages/adopciones/gatos.astro` globs images under
  `src/assets/fichas_gatos/{en_adopcion,adoptados,fallecidos_desaparecidos}/`. To add a cat, drop
  an image in the right folder; the filename becomes its display name (the code strips `(n)` and
  `ADOPTADO/A`).
- **Forms**: contact form posts to **Web3Forms** (`access_key` + redirect to `/gracias`).
  Adoption/volunteer forms are **not wired yet** — they use placeholder URLs
  `GOOGLE_FORM_URL_ADOPCION` / `GOOGLE_FORM_URL_VOLUNTARIADO`.
- **Blog posts are files**: add a `.md` under `src/content/blog` with `title`/`date`/`tag`/
  `excerpt`/`image` frontmatter. The collection uses the Content Layer `glob()` loader; use the
  entry `id` (not `slug`) and render with `render(entry)` from `astro:content`.
- **`@lucide/astro` 1.x removed brand icons** (`Facebook`, `Instagram`, …). Social icons are
  hand-rolled SVGs in `src/components/icons/` — extend those instead of importing from lucide.
- **Design system**: `DESIGN.md` is the prose spec; the executable truth is the `@theme` block in
  `src/styles/global.css` (maroon/cream/gold palette; Montserrat is both `--font-sans` and
  `--font-serif`). Edit tokens there.
- `docs/structure.md` is the site's content outline/spec. `.agents/` is gitignored.

## Flujo Spec-Driven Development (SDD) — Obligatorio

1. **Regla de oro:** prohibido crear o modificar código fuente sin una spec APROBADA por el
   usuario. Si llega un cambio sin documentar, el primer paso es escribir/actualizar su spec
   y confirmarla antes de implementar.

2. **Creación de spec:** crea `specs/<version>/NN-tema.md` con este frontmatter YAML (es la
   **fuente de verdad** del estado):

   ```yaml
   ---
   code: "NN"
   title: "Título conciso"
   project: "cer-molina-ser"
   status: proposed          # proposed | approved | in-progress | completed
   version: "<version>"
   date: YYYY-MM-DD
   tags: [spec, sdd]
   affected_files:
     - src/...
   ---
   ```

   `project` debe coincidir con el nombre del proyecto. `<version>` usa **semver**
   (p. ej. `0.1.0`) y es la misma que el nombre de la carpeta `specs/<version>/`.

   El cuerpo usa estas secciones: Purpose / Context / Proposed change / Technical decision /
   Affected files / Tests / Acceptance criteria. La spec describe **un** cambio; si supera
   ~300 líneas, divídela en varias specs. El estado completo del sistema vive en `docs/`.

3. **Pausa dura (human-in-the-loop):** al dejar la spec en `status: proposed`, DETÉN la
   ejecución, muestra un resumen y espera confirmación explícita. No pases a `in-progress`
   ni toques código hasta que el usuario apruebe.

4. **Implementación:** con la aprobación, cambia la spec a `status: in-progress` e implementa
   el código y los tests descritos en ella.

5. **Cierre:** cuando los Acceptance criteria estén cumplidos, cambia la spec a
   `status: completed`, actualiza la documentación viva en `docs/` y anota el cambio en
   `specs/<version>/00-changelog.md`. La spec se commitea junto con el código que describe,
   en el mismo commit.

Los specs se organizan por versión en `specs/<version>/`; los cambios nuevos se registran en
la versión actual (`00-changelog.md`) y al liberar un conjunto se sube la versión de specs
(incrementa el semver). `docs/` es la referencia autoritativa del estado actual; `specs/` es
el contrato/plan por versión.

Plantilla de `specs/<version>/00-changelog.md`:

```markdown
# Changelog — <version>

| Fecha | Spec | Cambio |
| ----- | ---- | ------ |
| YYYY-MM-DD | NN | Resumen del cambio |
```
