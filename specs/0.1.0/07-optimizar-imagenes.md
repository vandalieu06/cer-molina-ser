---
code: "07"
title: "Optimizar imágenes a webp, normalizar nombres y galería con astro:assets"
project: "cer-molina-ser"
status: completed
version: "0.1.0"
date: 2026-11-17
tags: [spec, sdd, assets, imagenes, rendimiento]
affected_files:
  - scripts/optimize-images.sh
  - package.json
  - src/pages/adopciones/gatos.astro
  - src/components/adopciones/GaleriaGatos.astro
  - src/components/Header.astro
  - src/components/sobre-nosotros/MetodoCER.astro
  - src/components/adopciones/AdoptarAhora.astro
  - src/components/home/Hero.astro
  - src/components/sobre-nosotros/History.astro
  - src/components/colonias-felinas/InfoColonias.astro
  - src/components/sobre-nosotros/Equipo.astro
  - src/components/adopciones/FinalesFelices.astro
  - src/content/blog/*.md
  - docs/images.md
  - src/assets/**/*.webp
  - specs/0.1.0/00-changelog.md
---

# Optimizar imágenes a webp, normalizar nombres y galería con astro:assets

## Purpose

Reducir el peso del material gráfico de `src/assets` de **414 MB a 21 MB** (−95 %), servir a la
galería de gatos imágenes dimensionadas a su hueco real en pantalla (hoy se descarga ~1 MB por
ficha) y fijar un estándar de nombres estable para añadir gatos sin tocar código.

## Context

- `src/assets` pesa **414 MB**: 297 MB en 72 fotos de `photos_cer_molina/` (ninguna referenciada
  hoy), 99 MB en 118 fichas de `fichas_gatos/`, 4,2 MB en `web/` y ~15 MB sueltos.
- La galería usa `import.meta.glob(..., { eager: true })` y pasa el `.src` a un `<img>`. Con esa
  ruta, Astro **no** procesa la imagen: copia el PNG original (≈850 KB, 1080×1080) al `dist/`.
  El resultado es un `dist/` de ~112 MB (ver spec 06).
- `TRUE. EN ACOGIDA.pdf` (1,9 MB) está en `fichas_gatos/adoptados/` pero el glob solo admite
  `png|jpg|jpeg`, así que esa ficha **no se muestra** en la web.
- Nombres actuales: mayúsculas, acentos (`ÁMBAR`, `FÉLIX`, `LÍA`, `LULÚ`, `PRÍNCIPE`, `Tarzán`),
  sufijos de estado (`HESTIA ADOPTADA`, `MANGO ADOPTADO`…), duplicados (`GRETA(1)`, `LEO(1)`,
  `LIRA(1)`, `VEGA_v2`) y una colisión real (`ESTRELLA.png` + `Estrella.jpg`).
  Las mayúsculas y los espacios obligan a percent-encoding en las URLs y son frágiles entre
  Linux y macOS (NFC/NFD).
- Los originales están en `docs/cer-molina-cer/` (verificados por md5), **no versionados**, con
  un `tar.gz` en `.backup/`. La conversión es, por tanto, reversible.
- Medidas reales con ImageMagick 7.1.2 / libwebp 1.6 en esta máquina: ficha 825 KB → **74 KB**
  (900 px, q80); `bg-cer` 2349 KB → **236 KB** (1920 px, q80); foto 12 MB → **329 KB**
  (1920 px, q80); PDF renderizado a 150 dpi → **57 KB**.
- Fuera de alcance: `prototypes/`, `anti-slop/` y el backoffice. El rediseño y el backoffice
  siguen pendientes de decisión y no se tocan aquí.

## Proposed change

1. **`scripts/optimize-images.sh`** (bash + `magick` + `pdftoppm`), invocable como
   `pnpm images:optimize`. Lee siempre de `docs/cer-molina-cer/` y escribe en `src/assets/`.
   - Idempotente: salta si el `.webp` de destino es más nuevo que el origen (`--force` lo ignora).
   - `--dry-run` (lista lo que haría) y `--only fichas|photos|assets|web|pdf`.
   - `slugify()`: quita extensión → `iconv ASCII//TRANSLIT` → minúsculas → `(n)`/`_vN` a sufijo
     `-dup` → quita ` ADOPTADO|ADOPTADA` final → espacios a `-` → fuera `[^a-z0-9-]` →
     colapsa guiones.
   - Resolución de duplicados: si el slug ya existe en la misma carpeta, añade `-2`, `-3`…
     (determinista porque el orden de origen es alfabético). Así `GRETA(1)`→`greta-2`,
     `VEGA_v2`→`vega-2`, `LEO(1)`→`leo-2`, `LIRA(1)`→`lira-2` y `Estrella.jpg`→`estrella-2`
     (mientras `ESTRELLA.png`→`estrella`).
   - Avisa por stderr si algún slug acaba vacío o si dos orígenes generan el mismo destino.

   Parámetros por grupo:

   | Grupo | Origen | Destino | Long edge | Calidad |
   | --- | --- | --- | --- | --- |
   | `fichas` | `original_fichas_gatos/**` | `src/assets/fichas_gatos/**` | 1000 px | 82 |
   | `photos` | `original_photos/*.jpg` | `src/assets/photos_cer_molina/` | 1920 px | 80 |
   | `assets` | `original_assets/*.{jpg,png}` | `src/assets/` | 1920 px | 80 |
   | `web` | `original_assets/web/*.webp` | `src/assets/web/` | 1200–1920 px | 80 |
   | `pdf` | `original_fichas_gatos/adoptados/*.pdf` | `src/assets/fichas_gatos/adoptados/` | 1000 px | 82 |

   Comando base:

   ```bash
   magick "$src" -auto-orient -colorspace sRGB -resize "${max}x${max}>" -strip \
     -quality "$q" -define webp:method=6 -define webp:sharp-yuv=true "$dst"
   ```

   Para `web/` cada fichero tiene su ancho por uso: `home-hero` 1920, `sobre-nosotros-history`
   1600, `blog-sample-img` 1200 y `404` se deja tal cual (69 KB). El `logo` sale a 500 px, q90.
   Para `pdf`: `pdftoppm -f 1 -l 1 -r 150 -png -singlefile` y luego el mismo `magick`.

2. **Nombres visibles sin metadata**: el estado sigue viniendo de la carpeta. En
   `src/pages/adopciones/gatos.astro` se sustituye el `replace()` actual por:

   ```ts
   const ACENTOS: Record<string, string> = {
     ambar: "Ámbar", felix: "Félix", lia: "Lía", lulu: "Lulú",
     principe: "Príncipe", tarzan: "Tarzán",
   };

   function prettyName(slug: string): string {
     const dup = slug.match(/^(.*)-(\d+)$/);
     const base = dup ? dup[1] : slug;
     const nombre = ACENTOS[base] ?? base.charAt(0).toUpperCase() + base.slice(1);
     return dup ? `${nombre} (${dup[2]})` : nombre;
   }
   ```

   Añadir un gato = soltar el fichero en la carpeta; si el nombre lleva acento en la UI, se
   añade una línea a `ACENTOS`.

3. **Galería con `astro:assets`**: el glob pasa a `.webp` y entrega `ImageMetadata` en vez de
   strings. `GaleriaGatos` tipa `images: { src: ImageMetadata; alt: string }[]` y renderiza
   `<Image widths={[320, 560]} sizes="(min-width:1280px) 300px, (min-width:640px) 45vw, 90vw" />`
   (2 variantes por ficha, no 5). El lightbox conserva el webp de 1000 px vía
   `data-lightbox-src={img.src.src}` para poder ampliar sin pérdida.

4. **Resto de imágenes**: `Header` (logo), `History`, `InfoColonias`, `Equipo` y `FinalesFelices`
   pasan de `<img src={x.src}>` a `<Image>` con `widths` acordes a su hueco. Las cuatro entradas
   de blog apuntan a `blog-sample-img.webp` ya optimizado.

5. **`docs/images.md`**: estándar de nombres, tabla de grupos/parámetros, comandos, convención de
   `docs/cer-molina-cer/` y qué hacer al añadir un gato nuevo.

## Technical decision

- **Script en bash y no Node**: el usuario pidió ImageMagick y así el pipeline no depende de
  `sharp` ni de la versión de Node; se puede ejecutar suelto antes de tocar el proyecto.
- **Se genera desde `docs/`, no leyendo `src/assets`**: los originales son la fuente de verdad y
  así el repo no necesita guardar el PNG/JPG. Tras la spec 09 esa será la única copia local.
- **`-define webp:sharp-yuv=true` y `method=6`**: las fichas son carteles con texto; el YUV
  estándar emborrona los bordes del texto. `method=6` cuesta más en la conversión (una vez) y
  ahorra ~5-10 %.
- **1000 px en fichas**: el lightbox las muestra a `max-h-[95vh]`, o sea ~900 px en un portátil.
  Bajar de 1000 no aporta y subir solo gasta.
- **`ACENTOS` en el código y no un JSON de metadatos**: mantiene el flujo "suelta el fichero",
  que es lo que hace usable la galería para una protectora. Solo ~6 nombres necesitan entrada.
- **Duplicados como fichas separadas** (`greta-2` → "Greta (2)"): decisión del usuario; no se
  descarta material.
- **No se borra nada huérfano** (`cat-1`, `bg-home-welcome`, `historia-protectora`): se optimizan
  igual y se listan en `docs/images.md` como candidatos a eliminar cuando se decida el rediseño.
- **Los `.webp` se commitean** (son el input del build); los originales no.

## Affected files

- `scripts/optimize-images.sh` — nuevo.
- `package.json` — script `images:optimize`.
- `src/assets/**` — PNG/JPG sustituidos por `.webp` optimizados con nombres normalizados.
- `src/pages/adopciones/gatos.astro` — glob `.webp`, `prettyName()`, `ImageMetadata`.
- `src/components/adopciones/GaleriaGatos.astro` — `<Image>` responsiva + lightbox.
- `src/components/Header.astro`, `History.astro`, `InfoColonias.astro`, `Equipo.astro`,
  `FinalesFelices.astro` — `<img>` → `<Image>`.
- `src/components/home/Hero.astro`, `MetodoCER.astro`, `AdoptarAhora.astro` — solo la ruta del
  import cambia a `.webp` (el refactor de fondo es la spec 08).
- `src/content/blog/*.md` — ruta del `image` si cambia el nombre.
- `docs/images.md` — nuevo.
- `specs/0.1.0/00-changelog.md` — entrada al cerrar.

## Tests

- `bash scripts/optimize-images.sh --dry-run` lista 118 fichas, 72 fotos, 10 sueltos, 4 web y
  1 PDF, sin escribir nada.
- `pnpm images:optimize` → 118 `.webp` en `fichas_gatos/` (103/14/1), 72 en `photos_cer_molina/`,
  `true.webp` incluido; `find src/assets -iname '*.png' -o -iname '*.jpg' -o -iname '*.pdf'`
  devuelve vacío.
- Slugs comprobados: `ambar.webp`, `felix.webp`, `lia.webp`, `lulu.webp`, `principe.webp`,
  `tarzan.webp`, `hestia.webp`, `mango.webp`, `marte.webp`, `tiana.webp`, `lauri.webp`,
  `estrella.webp` + `estrella-2.webp`, `greta.webp` + `greta-2.webp`, `vega.webp` + `vega-2.webp`,
  `leo.webp` + `leo-2.webp`, `lira.webp` + `lira-2.webp`.
- `du -sh src/assets` < 25 MB; ningún fichero > 450 KB (el mayor medido es un fondo de
  1920 px sin usar, 415 KB).
- `pnpm build`: el `dist/` baja de ~112 MB a <20 MB; `/adopciones/gatos/` muestra **118** fichas
  y "True (2)"/"True" aparece por primera vez.
- `pnpm astro check` sin errores ni avisos nuevos.
- Revisión visual de 3 fichas (1:1, 1080×1920 y el PDF) a tamaño de tarjeta y en lightbox;
  contraste del texto sin artefactos.
- `pnpm dev`: sin 404 de imágenes en consola.

## Acceptance criteria

- [x] Existe `scripts/optimize-images.sh` idempotente con `--dry-run` y `--only`, documentado.
- [x] `src/assets` queda en 21 MB y sin PNG/JPG/PDF (todo `.webp`).
- [x] Todos los nombres de `src/assets` cumplen `^[a-z0-9]+(-[a-z0-9]+)*\.webp$`.
- [x] La galería sirve variantes de 320/560 px y usa el fichero de 1000 px solo en el lightbox.
- [x] Las 118 fichas se ven, con nombres correctos (acentos incluidos) y la ficha PDF incluida.
- [x] `pnpm build` y `pnpm astro check` en verde; `dist/` < 20 MB.
- [x] `docs/images.md` explica el estándar y el pipeline.
- [x] Sin cambios en `prototypes/`, `anti-slop/` ni backoffice.
