---
code: "09"
title: "Purgar del historial de git los blobs de imagen antiguos"
project: "cer-molina-ser"
status: in-progress
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

**Principio**: se calcula la lista de blobs históricos "grandes" **que ya no están en `HEAD`** y
se le pasa esa lista exacta a `git filter-repo --strip-blobs-with-ids`. Todo lo que exista en
`HEAD` queda intacto por construcción, así que la purga no puede romper el build.

### 0. Redes de seguridad

```bash
mkdir -p docs/cer-molina-cer/.backup
git bundle create docs/cer-molina-cer/.backup/cer-pre-purge-2026-11-17.bundle --all
cp -a .git /tmp/opencode/cer-dotgit-backup
```

### 1. Herramienta

```bash
uv tool install git-filter-repo
git filter-repo --version        # vive en ~/.local/bin, ya en el PATH
```

### 2. Selección quirúrgica de blobs

```bash
# blobs > 100 KB en TODO el historial
git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
  | awk '$1=="blob" && $3>102400 {print $2}' | sort -u > /tmp/big.txt

# blobs vivos en HEAD (se conservan siempre)
git ls-tree -r HEAD | awk '{print $3}' | sort -u > /tmp/head.txt

# diferencia: históricos que ya no existen en el árbol actual
comm -23 /tmp/big.txt /tmp/head.txt > /tmp/purge-blobs.txt
wc -l /tmp/purge-blobs.txt      # esperado: ~110-120
```

Antes de ejecutar se revisa que **ningún** OID de `purge-blobs.txt` esté en `/tmp/head.txt`
(es la propia definición) y que el total a eliminar ronde los 340-400 MB.

### 3. Purga

```bash
git status --porcelain      # debe estar vacío
git filter-repo --strip-blobs-with-ids /tmp/purge-blobs.txt

# filter-repo elimina el remote a propósito
git remote add origin https://github.com/vandalieu06/cer-molina-ser.git
```

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

- Historial de git (`main` y `develop`) — sin cambios de contenido en el árbol.
- `docs/images.md` — nota sobre dónde viven los originales tras la purga.
- `specs/0.1.0/00-changelog.md` — entrada al cerrar.
- `.gitignore` — solo si al revisar se detecta algún patrón de originales sin cubrir.

## Tests

- `git bundle verify docs/cer-molina-cer/.backup/cer-pre-purge-2026-11-17.bundle`.
- `git diff --name-status origin/develop..HEAD` antes y después de la purga: idéntico.
- `git cat-file -e <oid de un jpg antiguo>` falla tras la purga; `git cat-file -e <oid de un
  webp actual>` funciona.
- `git checkout <commit antiguo> -- src/assets/fichas_gatos` falla (los originales ya no están),
  y el `.tar.gz` restaura el material.
- Clon limpio + `pnpm install && pnpm build && pnpm astro check` en verde; `du -sh .git` < 40 MB.
- Comprobación funcional del sitio en `pnpm preview`: galería con 118 fichas y fondos visibles.

## Acceptance criteria

- [ ] Existe el `bundle` completo previo y se ha verificado con `git bundle verify`.
- [ ] `.git` baja de 406 MB a <40 MB sin cambios en `git diff origin/develop..HEAD`.
- [ ] `main` y `develop` reescritos y publicados con `--force`; `git fsck --full` limpio.
- [ ] Un clon nuevo compila (`pnpm build`, `pnpm astro check`) y sirve el sitio completo.
- [ ] Los `.webp` actuales siguen en el historial; los PNG/JPG originales ya no.
- [ ] Queda documentado en `docs/images.md` dónde están los originales y cómo restaurar.
