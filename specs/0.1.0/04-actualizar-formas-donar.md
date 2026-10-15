---
code: "04"
title: "Actualizar formas de donar: quitar Bizum y poner datos reales de transferencia"
project: "cer-molina-ser"
status: completed
version: "0.1.0"
date: 2026-10-15
tags: [spec, sdd]
affected_files:
  - src/components/donaciones/FormasDonar.astro
  - src/components/donaciones/OtrosApoyos.astro
  - docs/structure.md
  - specs/0.1.0/00-changelog.md
---

# Actualizar formas de donar: quitar Bizum y poner datos reales de transferencia

## Purpose

Dejar la página de donaciones con información real y verificada: eliminar la opción Bizum (que la
asociación no ofrece) y publicar el número de cuenta real en la tarjeta de transferencia. Además,
enlazar el apadrinamiento con el correo de contacto real en lugar de la página de contacto.

## Context

Estado actual (verificado):

- `src/components/donaciones/FormasDonar.astro` muestra tres tarjetas en `md:grid-cols-3`:
  - **Bizum** con el número de ejemplo `000000000` (importa el icono `Smartphone`).
  - **Transferencia** con el IBAN de ejemplo `ES00 1234 5678 9012 3456 7890`.
  - **Teaming** con enlace real a `https://www.teaming.net/cermolinadesegura`.
- `src/components/donaciones/OtrosApoyos.astro:51` — "Solicitar información de apadrinamiento"
  apunta a `href="/contacto"` (además sin `getPath()`).
- `docs/structure.md:41` documenta `Formas de donar (Bizum, transferencia, teaming)`.

Datos aportados por la asociación:

- IBAN: `ES27 0049 4677 2128 1617 3399`
- Beneficiario: `ASOCIACION COLONIAS FELINAS CER MOLINA DE SEGURA`
- Correo de contacto único: `cermolinadesegura@gmail.com`

Decisiones confirmadas con la asociación:

- La tarjeta de **Bizum se elimina** por completo (no se sustituye por otro método).
- **Teaming se conserva** tal cual (no se ha solicitado ningún cambio).
- El IBAN y el beneficiario son correctos y se pueden publicar.
- El nombre del beneficiario se muestra visible junto al IBAN.

## Proposed change

### 1. `src/components/donaciones/FormasDonar.astro`

- Eliminar la tarjeta completa de Bizum (bloque `<div>` con icono `Smartphone`).
- Eliminar el importe `Smartphone` de la línea de imports (queda con `Landmark, Heart`).
- Cambiar la cuadrícula de `grid-cols-1 md:grid-cols-3` a `grid-cols-1 md:grid-cols-2`.
- En la tarjeta de **Transferencia**:
  - Sustituir el IBAN de ejemplo por `ES27 0049 4677 2128 1617 3399`.
  - Añadir el nombre del beneficiario (`ASOCIACION COLONIAS FELINAS CER MOLINA DE SEGURA`)
    como línea de texto bajo el IBAN, con `break-all`/`break-words` para que no desborde.
- Mantener la tarjeta de **Teaming** sin cambios.

### 2. `src/components/donaciones/OtrosApoyos.astro`

- Cambiar el `href` de "Solicitar información de apadrinamiento" de `/contacto` a
  `mailto:cermolinadesegura@gmail.com`.
- Mantener el texto del enlace.

### 3. `docs/structure.md`

- Línea 41: actualizar `Formas de donar (Bizum, transferencia, teaming)` →
  `Formas de donar (transferencia, teaming)`.

### 4. Changelog

- Añadir la entrada de la spec `04` en `specs/0.1.0/00-changelog.md` al cerrar.

## Technical decision

- Se elimina Bizum en lugar de ocultarlo para no publicar un método de pago inexistente.
- Con dos tarjetas la rejilla pasa a `md:grid-cols-2` para que ocupen el ancho de forma equilibrada.
- El apadrinamiento usa `mailto:` (no es una ruta interna, por lo que **no** requiere `getPath()`).
- El correo de contacto sigue la decisión global de la spec `05` (correo único
  `cermolinadesegura@gmail.com`).

## Affected files

- `src/components/donaciones/FormasDonar.astro` — quitar Bizum, IBAN/beneficiario reales, rejilla.
- `src/components/donaciones/OtrosApoyos.astro` — enlace de apadrinamiento a `mailto:`.
- `docs/structure.md` — quitar "Bizum" del listado.
- `specs/0.1.0/00-changelog.md` — entrada al cerrar.

## Tests

- `pnpm astro check` sin errores.
- `pnpm build` OK.
- Verificación en navegador (agent-browser) de `/cer-molina-ser/donaciones`:
  - No aparece ninguna tarjeta Bizum.
  - Se ven solo dos tarjetas (Transferencia y Teaming) en escritorio.
  - El IBAN y el beneficiario son legibles y no desbordan.
  - El enlace de apadrinamiento abre un `mailto:` a `cermolinadesegura@gmail.com`.

## Acceptance criteria

- [x] La sección "Formas de Donar" ya no muestra la tarjeta ni el número de Bizum.
- [x] El importe `Smartphone` ya no se usa (sin imports muertos) y `pnpm astro check` pasa.
- [x] La tarjeta de Transferencia muestra `ES27 0049 4677 2128 1617 3399` y el beneficiario.
- [x] La tarjeta de Teaming se mantiene igual.
- [x] "Solicitar información de apadrinamiento" abre `mailto:cermolinadesegura@gmail.com`.
- [x] `docs/structure.md` ya no menciona Bizum.
- [x] `pnpm astro check` y `pnpm build` sin errores.
