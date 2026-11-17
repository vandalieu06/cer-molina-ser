# Imágenes — estándar y pipeline

Todo el material gráfico del sitio se sirve en **WebP optimizado**. Los originales (JPG/PNG/PDF)
no viven en el repo: están en `docs/cer-molina-cer/` (fuera de git) y en el backup de Drive.

## Regla de oro

> `src/assets/` contiene **artefactos generados**, no originales.

Se regeneran en cualquier momento desde `docs/cer-molina-cer/` con:

```bash
pnpm images:optimize            # convierte todo
pnpm images:optimize --dry-run  # ver qué haría
pnpm images:optimize --only fichas
pnpm images:optimize --force    # regenera aunque ya esté al día
pnpm images:optimize --clean    # además borra PNG/JPG/PDF antiguos de src/assets
```

Requiere **ImageMagick 7** (`magick`) y **poppler** (`pdftoppm`, solo para PDFs).

## Estándar de nombres

```
^[a-z0-9]+(-[a-z0-9]+)*\.webp$
```

- Minúsculas, ASCII (sin acentos), sin espacios ni paréntesis.
- Los espacios pasan a `-`: `FOTO 1.jpg` → `foto-1.webp`.
- Fuera los sufijos de estado: el estado lo da la carpeta (`en_adopcion`, `adoptados`,
  `fallecidos_desaparecidos`). `HESTIA ADOPTADA.png` → `hestia.webp`.
- Duplicados de la misma ficha → `-2`, `-3`… (`GRETA(1)` → `greta-2`, `VEGA_v2` → `vega-2`,
  y la colisión `ESTRELLA.png` + `Estrella.jpg` → `estrella.webp` + `estrella-2.webp`).
- Los **originales en `docs/` conservan su nombre original**: es la traza de procedencia.

## Parámetros por grupo

| Grupo | Origen | Destino | Long edge | Calidad |
| --- | --- | --- | --- | --- |
| `fichas` | `original_fichas_gatos/**` | `src/assets/fichas_gatos/**` | 1000 px | 82 |
| `photos` | `original_photos/*.jpg` | `src/assets/photos_cer_molina/` | 1920 px | 80 |
| `assets` | `original_assets/*.{jpg,png}` | `src/assets/` | 1920 px | 80 |
| `web` | `original_assets/web/*.webp` | `src/assets/web/` | 1200–1920 px | 80 |
| `pdf` | `original_fichas_gatos/adoptados/*.pdf` | `…/adoptados/` | 1000 px | 82 |

Comando base (idéntico para todos, cambia `max` y `q`):

```bash
magick "$src" -auto-orient -colorspace sRGB -resize "${max}x${max}>" -strip \
  -quality "$q" -define webp:method=6 -define webp:sharp-yuv=true "$dst"
```

`sharp-yuv` evita el sangrado de color en los bordes del texto de las fichas (son carteles).

Excepciones: `logo.png` → `logo.webp` a 500 px q90 (y `logo.jpg` se ignora, es un duplicado);
`web/404.webp` se deja tal cual (ya estaba optimizado).

## Añadir un gato

1. Copia la ficha original a `docs/cer-molina-cer/original_fichas_gatos/<carpeta>/` con su nombre
   original (vale en mayúsculas y con acentos).
2. `pnpm images:optimize --only fichas --clean`.
3. Si el nombre visible lleva acento, añade una línea al mapa `ACENTOS` de
   `src/pages/adopciones/gatos.astro` (`ambar: "Ámbar"`). Sin eso se muestra capitalizado:
   `akira` → `Akira`.

No hay que tocar nada más: la galería descubre los ficheros con `import.meta.glob` y el estado
sale de la carpeta.

## Cómo se sirven

- **Fichas**: `<Image>` con `widths={[320, 560]}` y `width={560}`; el WebP de 1000 px se usa solo
  en el lightbox (`data-lightbox-src`).
- **Contenido** (`History`, `InfoColonias`, `Equipo`, `FinalesFelices`, logo): `<Image>` con
  `width` + `widths` acordes a su hueco. `width` es importante: sin él Astro genera una variante
  extra al ancho del original.
- **Fondos** (`Hero`, `MetodoCER`, `AdoptarAhora`): `<Picture>` con `formats={["avif","webp"]}`,
  `fallbackFormat="webp"` (sin esto el fallback sale en PNG y pesa MB), `widths={[768,1280,1920]}`
  y `sizes="100vw"`. El hero va `loading="eager"` + `fetchpriority="high"`; el resto, `lazy` y
  `decoding="async"`.

## Candidatos a limpiar

Estos ficheros se optimizaron pero hoy no se referencian desde ninguna página. No se borraron a
propósito; decidir al cerrar el rediseño:

- `src/assets/cat-1.webp`
- `src/assets/bg-home-welcome.webp` (sustituido por `web/home-hero.webp`)
- `src/assets/historia-protectora.webp`
- `src/assets/photos_cer_molina/*` (72 fotos para una futura galería)

## Historial de git

Hasta la spec 09 el historial contenía los PNG/JPG originales. El 2026-11-17 se purgó con
`scripts/purge-history.sh` (204 blobs, 413 MB): `.git` pasó de 428 MB a **21 MB** y solo quedan los
`.webp` actuales. **Los originales viven únicamente en `docs/cer-molina-cer/` y en el backup de
Drive** (`.backup/cer-molina-cer-originales-*.tar.gz`). Restaurar:

```bash
tar -xzf docs/cer-molina-cer/.backup/cer-molina-cer-originales-YYYY-MM-DD.tar.gz -C docs/cer-molina-cer
```
