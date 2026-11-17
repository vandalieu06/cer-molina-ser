# CER Molina Segura — material original

Repositorio local del material gráfico original de la protectora: fotos de las colonias y de los
eventos, y las fichas de los gatos. **Aquí no se versiona ninguna imagen**: esta carpeta solo
guarda la estructura para que el repo documente dónde vive cada cosa.

## Estructura

```
cer-molina-cer/
├── original_photos/                     # 72 fotos de colonias, eventos y voluntariado (JPG)
├── original_fichas_gatos/
│   ├── en_adopcion/                     # 14 fichas
│   ├── adoptados/                       # 103 fichas
│   └── fallecidos_desaparecidos/        # 1 ficha
├── original_assets/                     # material gráfico suelto de la web (fondos, logo…)
│   └── web/                             # versiones webp antiguas de hero, historia, blog y 404
└── .backup/                             # archivo tar.gz con todo lo anterior (local, ignorado)
```

Los ficheros de `original_fichas_gatos/` **conservan el nombre original** (mayúsculas, acentos,
sufijos `ADOPTADO/ADOPTADA`, duplicados `(1)`). Es la traza de procedencia: los nombres
normalizados solo existen en `src/assets/` tras el pipeline de optimización.

## Backup

```bash
tar -czf .backup/cer-molina-cer-originales-YYYY-MM-DD.tar.gz \
  original_photos original_fichas_gatos original_assets

# comprobación
tar -tzf .backup/cer-molina-cer-originales-YYYY-MM-DD.tar.gz | wc -l
gzip -t .backup/cer-molina-cer-originales-YYYY-MM-DD.tar.gz
```

- Los JPG/PNG ya están comprimidos, así que `tar.gz` apenas reduce tamaño (~405 MB reales).
- El archivo se sube a Drive y **no** se commitea (`.backup/` está ignorado).
- Para restaurar:

```bash
tar -xzf .backup/cer-molina-cer-originales-YYYY-MM-DD.tar.gz -C .
```

## Relación con `src/assets/`

`src/assets/` **no** contiene originales: contiene los `.webp` optimizados que usa Astro. El
pipeline (`pnpm images:optimize`, ver `docs/images.md`) lee de aquí y escribe allí, así que
cualquier imagen se puede regenerar desde estos originales en cualquier momento.
