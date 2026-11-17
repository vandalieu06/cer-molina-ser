---
code: "09"
title: "Purgar del historial de git los blobs de imagen antiguos"
project: "cer-molina-ser"
status: completed
version: "0.1.0"
date: 2026-11-17
tags: [spec, sdd, git, mantenimiento]
affected_files:
  - .gitignore
  - docs/images.md
  - specs/0.1.0/00-changelog.md
---

# Purgar del historial de git los blobs de imagen antiguos

## Purpose

Bajar el repositorio de **~430 MB a ~30 MB** eliminando del historial los PNG/JPG/webp antiguos
que ya no existen en el árbol de trabajo, sin tocar ni un fichero del proyecto ni perder
commits: solo se eliminan objetos que ninguna versión actual referencia.

## Context

- `.git` pesa **406 MB** (un único pack de 404,38 MiB) porque las imágenes originales se
  commitearon antes de optimizarlas. No basta con reemplazarlas: git conserva el blob antiguo en
  el commit donde entró.
- Blobs >1 MB en el historial: **106 ficheros, 343 MB**. Por prefijo:

  | Prefijo histórico | Peso |
  | --- | --- |
  | `src/assets/photos_cer_molina` | 295,9 MB |
  | `src/assets/fichas_gatos` | 97,2 MB |
  | `src/assets/web` (webp antiguos) | 4,0 MB |
  | `src/assets/*.jpg` sueltos | ~13,8 MB |

- La spec 07 deja el árbol de trabajo con **~25 MB de `.webp` optimizados**. Esos blobs **sí**
  deben conservarse: son el input del build.
- Consecuencia de diseño: la purga se hace **después** de 07 y 08, y **por id de blob**, no por
  ruta. Filtrar por ruta (`--path src/assets/web`) borraría también los `.webp` nuevos; filtrar
  por extensión (`**/*.jpg`) deja fuera los webp antiguos.
- No hay tags ni releases (`git tag` vacío). Ramas: `main` y `develop`.
- El repositorio tiene un `tar.gz` con todos los originales en
  `docs/cer-molina-cer/.backup/` y un `.git` de 406 MB clonable desde el `bundle` que se crea
  antes de empezar.

## Proposed change

**Prerrequisito (medido, no teórico)**: la purga solo libera espacio cuando **ninguna rama
local** referencia los blobs antiguos. Con `main` todavía sin el commit de optimización, el
análisis da **2 blobs / 0 MB**: los 192 originales siguen vivos en el árbol de `main` y
strippearlos dejaría esa rama sin los ficheros que sus commits necesitan. Por eso el orden es:

```
07 y 08 en develop → PR y merge → release develop → main → purgar
```

**Automatizado**: `scripts/purge-history.sh` analiza y `--run` purga (con bundle previo). Los
pasos manuales quedan documentados para entenderlo.

**Principio**: se calcula la lista de blobs históricos "grandes" que **ya no están en ninguna
rama local** y se le pasa esa lista exacta a `git filter-repo --strip-blobs-with-ids`. Todo lo
que exista en una rama actual queda intacto por construcción, así que la purga no puede romper
el build.

### 0. Redes de seguridad

```bash
mkdir -p docs/cer-molina-cer/.backup
git bundle create docs/cer-molina-cer/.backup/cer-pre-purge-$(date +%F).bundle --all
git bundle verify docs/cer-molina-cer/.backup/cer-pre-purge-$(date +%F).bundle
cp -a .git /tmp/opencode/cer-dotgit-backup     # opcional, 428 MB
```

### 1. Herramienta

```bash
uv tool install git-filter-repo
git-filter-repo --version
```

### 2. Análisis (sin modificar nada)

```bash
bash scripts/purge-history.sh
```

Hace exactamente esto:

```bash
# blobs vivos en TODAS las ramas locales (nunca refs/remotes: origin/* apunta a
# los commits viejos y mantendría vivos justo los blobs a borrar)
git for-each-ref --format='%(objectname)' refs/heads | sort -u \
  | while read -r c; do git ls-tree -r "$c"; done | awk '{print $3}' | sort -u > keep.txt

# blobs > 100 KB de todo el historial (solo hashes: cat-file no acepta "<sha> <ruta>")
git rev-list --objects --all | awk '{print $1}' \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize)' > info.txt
awk '$1 == "blob" && $3 > 102400 {print $2}' info.txt | sort -u > big.txt

# históricos que ya no están vivos
comm -23 big.txt keep.txt > purge.txt
```

Resultado esperado **después del release**: ~250 blobs y **~400 MB** a eliminar.

### 3. Purga

```bash
bash scripts/purge-history.sh --run
```

Internamente: `git filter-repo --force --strip-blobs-with-ids purge.txt` y re-añade el remote
(que filter-repo elimina a propósito).

### 4. Verificación local (antes de publicar)

```bash
git count-objects -vH                 # size-pack esperado: ~25-35 MB
git fsck --full
git log --oneline -8                  # mismos mensajes, hashes nuevos
git diff --stat origin/develop..HEAD  # sin cambios de contenido respecto al remoto
pnpm install && pnpm build            # el árbol intacto compila
```

### 5. Publicación

```bash
# requiere desactivar temporalmente "force push" en branch protection
git push --force origin develop main
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# el resto de clones (incluido el de trabajo, si se hizo sobre una copia) debe re-clonar:
git clone https://github.com/vandalieu06/cer-molina-ser.git cer-molina-ser-nuevo
```

### 6. Cierre

- Comprobar el tamaño del repo en GitHub (Settings → General). Si pasados unos días sigue
  marcando cientos de MB, abrir ticket a soporte de GitHub para que ejecute el GC de objetos
  inalcanzables: GitHub no los libera al instante aunque el push sea correcto.
- Anotar en `docs/images.md` que el historial ya no contiene originales y que estos viven en
  `docs/cer-molina-cer/` + Drive.

## Technical decision

- **`--strip-blobs-with-ids` en vez de `--path`/`--path-glob`**: es el único método que no puede
  tocar el árbol actual, porque la lista se construye excluyendo `HEAD`. Además sobrevive a
  reordenaciones de carpetas o cambios de extensión.
- **Umbral 100 KB**: deja en el historial algún JPG pequeño antiguo (<100 KB, unos pocos MB como
  mucho) a cambio de no arriesgar borrar contenido vivo. Bajar más el umbral no compensa.
- **`git filter-repo` en vez de BFG o `filter-branch`**: es la herramienta mantenida, rápida y
  con `--dry-run`/`--analyze`; `filter-branch` está desaconsejado por git y BFG no permite una
  lista de blobs tan precisa.
- **Sobre el repo de trabajo, no en un espejo**: con la lista de blobs ya calculada y verificada,
  editar en sitio permite comprobar `pnpm build` antes de publicar. Las redes de seguridad
  (`bundle` + copia de `.git` + `tar.gz`) cubren el riesgo.
- **Se publica con `--force`**: la reescritura cambia todos los SHA. Es irreversible para
  terceros: PRs abiertos se cierran y se recrean, los forks quedan obsoletos y cualquier
  colaborador debe re-clonar (un `git pull` normal falla o reintroduce los blobs).
- **Pages no se rompe**: GitHub Actions solo publica si el build pasa; y aquí el árbol es
  idéntico, así que el build pasa igual que antes.

## Affected files

- `scripts/purge-history.sh` — análisis + purga reproducible.
- Historial de git (`main` y `develop`) — sin cambios de contenido en el árbol.
- `docs/images.md` — nota sobre dónde viven los originales tras la purga.
- `specs/0.1.0/00-changelog.md` — entrada al cerrar.
- `.gitignore` — solo si al revisar se detecta algún patrón de originales sin cubrir.

## Tests

- `bash scripts/purge-history.sh` sin `--run` informa del número de blobs y del peso, y no
  escribe nada.
- `git bundle verify docs/cer-molina-cer/.backup/cer-pre-purge-*.bundle`.
- `git diff --name-status origin/develop..HEAD` antes y después de la purga: idéntico.
- `git cat-file -e <oid de un jpg antiguo>` falla tras la purga; `git cat-file -e <oid de un
  webp actual>` funciona.
- `git checkout <commit antiguo> -- src/assets/fichas_gatos` falla (los originales ya no están),
  y el `.tar.gz` restaura el material.
- Clon limpio + `pnpm install && pnpm build && pnpm astro check` en verde; `du -sh .git` < 40 MB.
- Comprobación funcional del sitio en `pnpm preview`: galería con 118 fichas y fondos visibles.

## Acceptance criteria

- [x] Existe el `bundle` completo previo y se ha verificado con `git bundle verify`
  (`docs/cer-molina-cer/.backup/cer-pre-purge-2026-11-17.bundle`).
- [x] `.git` baja de 428 MB a 21 MB sin cambios en el árbol (mismo hash de tree).
- [x] `main` y `develop` reescritos y publicados con `--force`; `git fsck --full` limpio.
- [x] Un clon nuevo compila (`pnpm build`, `pnpm astro check`) y sirve el sitio completo.
- [x] Los `.webp` actuales siguen en el historial; los PNG/JPG originales ya no.
- [x] Queda documentado en `docs/images.md` dónde están los originales y cómo restaurar.

## Resultado (2026-11-17)

Ejecutado con `scripts/purge-history.sh --run` sobre `main` ya actualizado:

| Métrica | Antes | Después |
| --- | --- | --- |
| `.git` local | 428 MB | **21 MB** |
| Blobs >100 KB en el historial | 257 | 53 |
| Objetos en el pack | 484 | 654 (más ficheros actuales, menos historia) |
| Hash del árbol de `main` | — | `e49030a` (idéntico al previo) |

- 204 blobs / 413 MB eliminados. Un blob antiguo (`e27c13ce…`, `IMG_5770.jpg` de 11,8 MB) ya no
  existe en local; los `.webp` actuales siguen íntegros.
- `git fsck --full` limpio y *force push* de `develop` y `main` correcto.
- El deploy de Pages posterior al *force push* terminó en verde (32 s build + 11 s deploy).
- Clon limpio desde GitHub: `.git` 21 MB, `pnpm install` + `astro check` (0 errores) + `build`
  (18 MB de `dist/`, 118 fichas) correctos.
- **Pendiente en GitHub**: la API sigue reportando ~404 MB porque GitHub no ejecuta el GC de
  objetos inalcanzables de inmediato. Hay que abrir ticket a soporte si en unos días no baja.
