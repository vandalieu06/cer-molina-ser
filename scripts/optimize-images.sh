#!/usr/bin/env bash
#
# Convierte los originales de docs/cer-molina-cer/ a .webp optimizados en src/assets/.
# Los nombres se normalizan a slug ASCII (minúsculas, sin acentos, sin espacios).
#
# Uso:
#   bash scripts/optimize-images.sh [--dry-run] [--force] [--clean] [--only GRUPO]
#
# Grupos: fichas | photos | assets | web   (por defecto: todos)
#
#   --dry-run  Muestra lo que haría sin escribir nada.
#   --force    Regenera aunque el .webp ya sea más nuevo que el original.
#   --clean    Borra de src/assets los PNG/JPG/PDF antiguos (ya sustituidos por .webp).
#   --only     Limita a un grupo; se puede repetir (--only fichas --only web).
#
# Requiere: ImageMagick 7 (`magick`) y poppler (`pdftoppm`, solo para los PDF).

set -euo pipefail
shopt -s nullglob

# Orden de ficheros estable entre máquinas: locale C solo para `sort`, porque
# iconv necesita el locale UTF-8 del sistema para transliterar los acentos.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="$ROOT/docs/cer-molina-cer"
DST="$ROOT/src/assets"

FICHAS_SRC="$DOCS/original_fichas_gatos"
FICHAS_DST="$DST/fichas_gatos"
PHOTOS_SRC="$DOCS/original_photos"
PHOTOS_DST="$DST/photos_cer_molina"
ASSETS_SRC="$DOCS/original_assets"
WEB_SRC="$ASSETS_SRC/web"
WEB_DST="$DST/web"

DRY_RUN=0
FORCE=0
CLEAN=0
ONLY=()

TOTAL=0
DONE=0
SKIPPED=0
FAILED=0

declare -A USED=()

usage() {
  cat <<'EOF'
Uso: bash scripts/optimize-images.sh [opciones]

  --dry-run, -n   Muestra lo que haría sin escribir nada.
  --force, -f     Regenera aunque el .webp ya sea más nuevo que el original.
  --clean, -c     Borra de src/assets los PNG/JPG/PDF antiguos.
  --only GRUPO    Solo un grupo: fichas | photos | assets | web (repetible).
  --help, -h      Esta ayuda.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    -f|--force)   FORCE=1; shift ;;
    -c|--clean)   CLEAN=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    --only)
      [[ $# -ge 2 ]] || { echo "--only necesita un grupo" >&2; exit 1; }
      ONLY+=("$2")
      shift 2
      ;;
    *)
      echo "Opción desconocida: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for d in "$FICHAS_SRC" "$PHOTOS_SRC" "$ASSETS_SRC" "$WEB_SRC"; do
  [[ -d "$d" ]] || { echo "No existe el directorio de originales: $d" >&2; exit 1; }
done

want() {
  [[ ${#ONLY[@]} -eq 0 ]] && return 0
  local g
  for g in "${ONLY[@]}"; do [[ "$g" == "$1" ]] && return 0; done
  return 1
}

say() { printf '%s\n' "$*"; }
rel() { printf '%s' "${1#"$ROOT"/}"; }

# "ÁMBAR" → ambar, "GRETA(1)" → greta-dup1, "VEGA_v2" → vega-dup2,
# "TRUE. EN ACOGIDA" → true, "HESTIA ADOPTADA" → hestia
slugify() {
  printf '%s' "$1" \
    | iconv -f UTF-8 -t ASCII//TRANSLIT//IGNORE \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[[:space:]]*\(([0-9]+)\)[[:space:]]*$/ -dup\1/' \
    | sed -E 's/_v([0-9]+)$/ -dup\1/' \
    | sed -E 's/[[:space:]]+(adoptado|adoptada|en[[:space:]]+acogida)[[:space:]]*$//' \
    | sed -E 's/[[:space:]]+/-/g' \
    | sed -E 's/[^a-z0-9-]+/-/g' \
    | sed -E 's/-+/-/g' \
    | sed -E 's/^-+//; s/-+$//'
}

# Slug único dentro de un bucket: los duplicados pasan a -2, -3…
# Deja el resultado en $SLUG (no se puede usar $(...) o el array USED se pierde
# en el subshell).
SLUG=""
unique_slug() {
  local bucket="$1" raw="$2" base cand i=2 marker=0
  base="$(slugify "$raw")"
  if [[ "$base" =~ ^(.*)-dup[0-9]+$ ]]; then
    base="${BASH_REMATCH[1]}"
    marker=1
  fi
  if [[ -z "$base" ]]; then
    return 1
  fi
  cand="$base"
  if (( marker )); then cand="$base-2"; i=3; fi
  while [[ -n "${USED["$bucket:$cand"]+x}" ]]; do
    cand="$base-$i"
    i=$((i + 1))
  done
  USED["$bucket:$cand"]=1
  SLUG="$cand"
  return 0
}

convert_image() { # src dst max q
  local src="$1" dst="$2" max="$3" q="$4"
  TOTAL=$((TOTAL + 1))
  if [[ -f "$dst" && $FORCE -eq 0 && "$dst" -nt "$src" ]]; then
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi
  say "  $(rel "$src") → $(rel "$dst") (${max}px q${q})"
  DONE=$((DONE + 1))
  if (( DRY_RUN )); then return 0; fi
  mkdir -p "$(dirname "$dst")"
  magick "$src" -auto-orient -colorspace sRGB -resize "${max}x${max}>" -strip \
    -quality "$q" -define webp:method=6 -define webp:sharp-yuv=true "$dst"
}

convert_pdf() { # src dst max q
  local src="$1" dst="$2" max="$3" q="$4" tmp page
  TOTAL=$((TOTAL + 1))
  if [[ -f "$dst" && $FORCE -eq 0 && "$dst" -nt "$src" ]]; then
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi
  say "  $(rel "$src") → $(rel "$dst") (pdf ${max}px q${q})"
  DONE=$((DONE + 1))
  if (( DRY_RUN )); then return 0; fi
  command -v pdftoppm >/dev/null || { echo "Falta pdftoppm (poppler-utils)" >&2; return 1; }
  mkdir -p "$(dirname "$dst")"
  tmp="$(mktemp -d)"
  pdftoppm -f 1 -l 1 -r 150 -png -singlefile "$src" "$tmp/page"
  page="$tmp/page.png"
  magick "$page" -colorspace sRGB -resize "${max}x${max}>" -strip \
    -quality "$q" -define webp:method=6 -define webp:sharp-yuv=true "$dst"
  rm -rf "$tmp"
}

process_fichas() {
  say "· fichas (1000px q82)"
  local bucket f base slug dst
  local -a files=()
  for bucket in en_adopcion adoptados fallecidos_desaparecidos; do
    files=()
    mapfile -t files < <(find "$FICHAS_SRC/$bucket" -maxdepth 1 -type f \
      \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.pdf' \) \
      -print0 | LC_ALL=C sort -z | tr '\0' '\n')
    for f in "${files[@]}"; do
      [[ -n "$f" ]] || continue
      base="${f##*/}"
      base="${base%.*}"
      if ! unique_slug "fichas/$bucket" "$base"; then
        echo "AVISO: nombre vacío tras normalizar: $f" >&2
        FAILED=$((FAILED + 1))
        continue
      fi
      slug="$SLUG"
      dst="$FICHAS_DST/$bucket/$slug.webp"
      case "${f##*.}" in
        [pP][dD][fF]) convert_pdf "$f" "$dst" 1000 82 ;;
        *)            convert_image "$f" "$dst" 1000 82 ;;
      esac
    done
  done
}

process_photos() {
  say "· photos (1920px q80)"
  local f base slug dst
  local -a files=()
  mapfile -t files < <(find "$PHOTOS_SRC" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0 | LC_ALL=C sort -z | tr '\0' '\n')
  for f in "${files[@]}"; do
    [[ -n "$f" ]] || continue
    base="${f##*/}"
    base="${base%.*}"
    if ! unique_slug "photos" "$base"; then
      echo "AVISO: nombre vacío tras normalizar: $f" >&2
      FAILED=$((FAILED + 1))
      continue
    fi
    slug="$SLUG"
    dst="$PHOTOS_DST/$slug.webp"
    convert_image "$f" "$dst" 1920 80
  done
}

process_assets() {
  say "· assets (1920px q80; logo 500px q90)"
  local f base slug dst max q
  local -a files=()
  mapfile -t files < <(find "$ASSETS_SRC" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0 | LC_ALL=C sort -z | tr '\0' '\n')
  for f in "${files[@]}"; do
    [[ -n "$f" ]] || continue
    base="${f##*/}"
    if [[ "$base" == "logo.jpg" ]]; then
      say "  $(rel "$f") → omitido (duplicado de logo.png)"
      continue
    fi
    max=1920
    q=80
    if [[ "$base" == "logo.png" ]]; then max=500; q=90; fi
    base="${base%.*}"
    if ! unique_slug "assets" "$base"; then
      echo "AVISO: nombre vacío tras normalizar: $f" >&2
      FAILED=$((FAILED + 1))
      continue
    fi
    slug="$SLUG"
    dst="$DST/$slug.webp"
    convert_image "$f" "$dst" "$max" "$q"
  done
}

process_web() {
  say "· web (hero 1920, historia 1600, blog 1200)"
  local f base slug dst max
  local -a files=()
  mapfile -t files < <(find "$WEB_SRC" -maxdepth 1 -type f -iname '*.webp' -print0 | LC_ALL=C sort -z | tr '\0' '\n')
  for f in "${files[@]}"; do
    [[ -n "$f" ]] || continue
    base="${f##*/}"
    if [[ "$base" == "404.webp" ]]; then
      say "  $(rel "$f") → omitido (ya optimizado)"
      continue
    fi
    max=1600
    case "$base" in
      home-hero.webp)               max=1920 ;;
      sobre-nosotros-history.webp)  max=1600 ;;
      blog-sample-img.webp)         max=1200 ;;
    esac
    base="${base%.*}"
    if ! unique_slug "web" "$base"; then
      echo "AVISO: nombre vacío tras normalizar: $f" >&2
      FAILED=$((FAILED + 1))
      continue
    fi
    slug="$SLUG"
    dst="$WEB_DST/$slug.webp"
    convert_image "$f" "$dst" "$max" 80
  done
}

clean_legacy() {
  local -a legacy=()
  mapfile -t legacy < <(find "$DST" -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.pdf' \) -print0 | LC_ALL=C sort -z | tr '\0' '\n')
  if [[ ${#legacy[@]} -eq 0 ]]; then return 0; fi
  say "· limpieza de originales en src/assets"
  local f
  for f in "${legacy[@]}"; do
    [[ -n "$f" ]] || continue
    say "  borrar $(rel "$f")"
    if (( ! DRY_RUN )); then rm -f "$f"; fi
  done
}

say "Origen:  $(rel "$DOCS")"
say "Destino: $(rel "$DST")"
if (( DRY_RUN )); then say "(modo dry-run: no se escribe nada)"; fi

if want fichas; then process_fichas; fi
if want photos; then process_photos; fi
if want assets; then process_assets; fi
if want web;    then process_web;    fi

if (( CLEAN )) && [[ ${#ONLY[@]} -eq 0 ]]; then
  clean_legacy
fi

say ""
say "Convertidas: $DONE · omitidas (ya al día): $SKIPPED · total: $TOTAL · fallos: $FAILED"
if (( FAILED > 0 )); then exit 1; fi
exit 0
