#!/usr/bin/env bash
#
# Purga del historial: elimina los blobs de imagen antiguos que ya no existen en
# ninguna rama local, sin tocar el árbol de trabajo ni los commits actuales.
#
# Uso:
#   bash scripts/purge-history.sh          # analiza y muestra qué haría (no modifica nada)
#   bash scripts/purge-history.sh --run    # crea bundle de seguridad y purga
#
# Qué hace:
#   1. Lista los blobs > 100 KB de todo el historial.
#   2. Se queda solo con los que YA NO están en ninguna rama local (refs/heads).
#   3. Con --run: crea un bundle con toda la historia y ejecuta
#      `git filter-repo --strip-blobs-with-ids`.
#
# Después hay que re-añadir el remote (filter-repo lo quita) y hacer force-push:
#   git remote add origin https://github.com/vandalieu06/cer-molina-ser.git
#   git push --force origin develop main
#
# Requisito: `uv tool install git-filter-repo`.
#
# IMPORTANTE: no incluyas refs/remotes en la lista de ramas "vivas". Las
# referencias de origin/* apuntan a los commits antiguos y mantendrían vivos
# justo los blobs que queremos borrar.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

THRESHOLD=102400 # 100 KB
RUN=0
[[ "${1:-}" == "--run" ]] && RUN=1
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { sed -n '3,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1. Integridad del repo antes de tocar nada
if [[ -n "$(git status --porcelain | grep -v '^??' || true)" ]]; then
  echo "Hay cambios sin commitear. Haz commit o stash antes de purgar." >&2
  exit 1
fi
git fsck --no-progress >/dev/null 2>&1 || { echo "git fsck falla: arregla el repo antes." >&2; exit 1; }

# 2. Blobs vivos en todas las ramas locales (no refs/remotes)
git for-each-ref --format='%(objectname)' refs/heads | sort -u \
  | while read -r c; do git ls-tree -r "$c"; done | awk '{print $3}' | sort -u > "$TMP/keep.txt"

# 3. Blobs > umbral en todo el historial (solo hashes: cat-file no acepta "<sha> <ruta>")
git rev-list --objects --all | awk '{print $1}' \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize)' > "$TMP/info.txt"
awk -v t="$THRESHOLD" '$1 == "blob" && $3 > t {print $2}' "$TMP/info.txt" | sort -u > "$TMP/big.txt"

# 4. Históricos que ya no están vivos
comm -23 "$TMP/big.txt" "$TMP/keep.txt" > "$TMP/purge.txt"

COUNT=$(wc -l < "$TMP/purge.txt")
BYTES=$(grep -Ff "$TMP/purge.txt" "$TMP/info.txt" | awk '{s += $3} END {printf "%d", s}')
MB=$((BYTES / 1048576))

echo "Blobs > $((THRESHOLD / 1024)) KB en el historial : $(wc -l < "$TMP/big.txt")"
echo "De ellos, ya no vivos en ninguna rama    : $COUNT"
echo "Peso a eliminar                          : ${MB} MB"
echo "Peso actual del repo (.git)              : $(du -sh .git | cut -f1)"
echo

if (( COUNT == 0 )); then
  echo "Nada que purgar: todos los blobs grandes siguen referenciados por alguna rama."
  echo "Causa habitual: 'main' aún no tiene el commit que sustituye las imágenes."
  exit 0
fi

if (( RUN == 0 )); then
  echo "Modo análisis. Nada modificado."
  echo "Ejecuta 'bash scripts/purge-history.sh --run' para purgar."
  exit 0
fi

command -v git-filter-repo >/dev/null || {
  echo "Falta git-filter-repo. Instálalo con:  uv tool install git-filter-repo" >&2
  exit 1
}

BUNDLE="docs/cer-molina-cer/.backup/cer-pre-purge-$(date +%F).bundle"
echo "· bundle de seguridad: $BUNDLE"
git bundle create "$BUNDLE" --all >/dev/null
git bundle verify "$BUNDLE" >/dev/null

echo "· purgando…"
git filter-repo --force --strip-blobs-with-ids "$TMP/purge.txt" >/dev/null

echo "· remote (filter-repo lo elimina):"
git remote add origin https://github.com/vandalieu06/cer-molina-ser.git

echo "· verificando"
git fsck --full >/dev/null 2>&1 || true
echo "  .git ahora: $(du -sh .git | cut -f1)"
git count-objects -vH | sed 's/^/  /'

cat <<'EOF'

Hecho. Falta publicar:
  git push --force origin develop main
  git reflog expire --expire=now --all && git gc --prune=now --aggressive

GitHub no libera el espacio del servidor al instante; si en unos días el repo
sigue pesando cientos de MB, pide a soporte que ejecute el GC.
EOF
