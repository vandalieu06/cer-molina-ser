# CER Molina Segura

Sitio web estático de **CER Molina Segura**, protectora de gatos sin ánimo de lucro
(colonias felinas, adopciones, voluntariado y donaciones). Todo el contenido está en
**español** y el sitio se publica en GitHub Pages bajo el subpath `/cer-molina-ser`.

- Repositorio: https://github.com/vandalieu06/cer-molina-ser
- Publicación: https://vandalieu06.github.io/cer-molina-ser/

## Stack

- **Astro 7** (SSG estático, Vite 8 / Rolldown) + **TypeScript** (`astro/tsconfigs/strict`)
- **Tailwind CSS v4** vía `@tailwindcss/vite` — los tokens viven en `src/styles/global.css`
  (`@theme`); no hay `tailwind.config.js`
- **pnpm** (ver `packageManager` en `package.json`)
- `@lucide/astro` (iconos) y `sharp` + `astro:assets` (optimización de imágenes)
- **Content collections** en `src/content/blog` (loader `glob()` en `src/content.config.ts`)
- Despliegue: GitHub Actions (`withastro/action`) → GitHub Pages al hacer push a `main`

## Requisitos

- Node `>=22.12`
- pnpm (se recomienda `corepack enable`)

## Comandos

| Comando            | Acción                                                        |
| :----------------- | :------------------------------------------------------------ |
| `pnpm install`     | Instala dependencias                                          |
| `pnpm dev`         | Servidor de desarrollo en `http://localhost:4321/cer-molina-ser` |
| `pnpm build`       | Genera el sitio de producción en `./dist/`                    |
| `pnpm preview`     | Previsualiza el build localmente                              |
| `pnpm astro check` | Comprobación de tipos (requiere `@astrojs/check` + `typescript`) |

No hay script de lint, test ni formato.

## Estructura

```text
/
├── public/                     # assets estáticos servidos tal cual
├── specs/                      # specs del flujo SDD (por versión)
├── src
│   ├── assets/                 # imágenes (galería, heroes, blog...)
│   │   └── fichas_gatos/       # galería de gatos, basada en carpetas
│   ├── components/
│   │   ├── icons/              # iconos de marca propios (SVG)
│   │   └── <seccion>/          # secciones: home, adopciones, contacto...
│   ├── content/blog/           # posts del blog (.md)
│   ├── content.config.ts       # esquema de la colección blog
│   ├── data/pages.ts           # fuente de verdad de la navegación
│   ├── layouts/Layout.astro    # layout base (Header + Footer)
│   ├── pages/                  # páginas (composición de componentes)
│   ├── styles/global.css       # tokens de diseño (@theme)
│   └── utils/paths.ts          # helper getPath() para el subpath base
├── AGENTS.md                   # guía para agentes + flujo SDD
└── package.json
```

## Notas de desarrollo

- **Usa siempre `getPath()`** de `@utils/paths` para enlaces y assets internos: el sitio usa
  `base: "/cer-molina-ser"` y las rutas absolutas escritas a mano (`/foo`) se rompen.
- Las **páginas son envoltorios finos** que componen componentes de `src/components/<seccion>/`.
- La **navegación** se define en `src/data/pages.ts` (no en el `Header`).
- Para **añadir un gato**, suelta una imagen en
  `src/assets/fichas_gatos/{en_adopcion,adoptados,fallecidos_desaparecidos}/`; el nombre del
  archivo se usa como nombre visible.
- Para **publicar una noticia**, añade un `.md` en `src/content/blog` con frontmatter
  `title`/`date`/`tag`/`excerpt`/`image`.

Las convenciones completas y el flujo **Spec-Driven Development (SDD)** obligatorio están en
[`AGENTS.md`](./AGENTS.md).
