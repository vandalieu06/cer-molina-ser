---
code: "05"
title: "Unificar correo de contacto, enlazar formulario de socio y actualizar texto del footer"
project: "cer-molina-ser"
status: completed
version: "0.1.0"
date: 2026-10-15
tags: [spec, sdd]
affected_files:
  - src/data/links.ts
  - src/components/socios/Beneficios.astro
  - src/components/voluntariado/FormVoluntariados.astro
  - src/components/contacto/InfoContacto.astro
  - src/components/Footer.astro
  - specs/0.1.0/00-changelog.md
---

# Unificar correo de contacto, enlazar formulario de socio y actualizar texto del footer

## Purpose

Unificar el correo de contacto del sitio en `cermolinadesegura@gmail.com`, conectar el botón
"Hazte socio/a" con el formulario real de alta de socios, sustituir en voluntariado el formulario
roto por el correo de información, y actualizar el texto descriptivo del footer para reflejar la
actividad real (colonias felinas y adopción responsable).

## Context

Estado actual (verificado):

- Correos inconsistentes en el sitio:
  - `src/components/contacto/InfoContacto.astro:58,61` — `info@cermolinasegura.com`.
  - `src/components/Footer.astro:114,116` — `info@cermolina.org`.
- `src/components/socios/Beneficios.astro:69` — el botón "Quiero ser socio ahora" apunta a
  `href="#formulario-socio"`, un ancla que **no existe** en ninguna página (enlace muerto).
- `src/components/voluntariado/FormVoluntariados.astro:20` — CTA con `href="GOOGLE_FORM_URL_VOLUNTARIADO"`
  (placeholder roto) y texto que remite a un Google Forms.
- `src/components/Footer.astro:24-27` — descripción actual:
  "Dedicados al rescate, cuidado y adopción responsable de gatos en Molina de Segura.
  Tu ayuda hace posible su segunda oportunidad."
- Patrón del repo: las URLs de formularios externos viven en `src/data/links.ts`
  (hoy solo `ADOPTION_FORM_URL`).

Decisiones confirmadas con la asociación:

- Correo único en todo el sitio: `cermolinadesegura@gmail.com` (sustituye a los dos anteriores).
- Enlace al formulario de socios:
  `https://docs.google.com/forms/d/e/1FAIpQLSfFOky4AW9BRVEC_NSYWCjLxVYj5qq0slXLZGSXK485q1FhIg/viewform?usp=header`
- En voluntariado se **reemplaza** el formulario por el correo de información.
- Texto nuevo del footer: dedicarse a la **gestión y cuidado de colonias felinas** y a la
  **adopción responsable de gatos en Molina de Segura**.

## Proposed change

### 1. `src/data/links.ts`

- Añadir una segunda constante, en línea con `ADOPTION_FORM_URL`:

  ```ts
  export const MEMBERSHIP_FORM_URL =
    "https://docs.google.com/forms/d/e/1FAIpQLSfFOky4AW9BRVEC_NSYWCjLxVYj5qq0slXLZGSXK485q1FhIg/viewform?usp=header";
  ```

### 2. `src/components/socios/Beneficios.astro`

- Importar `MEMBERSHIP_FORM_URL` desde `@data/links`.
- Cambiar el `href` del botón "Quiero ser socio ahora" a `MEMBERSHIP_FORM_URL`, abriendo en
  pestaña nueva (`target="_blank"` + `rel="noopener noreferrer"`).
- Mantener importes, textos y estilos actuales.

### 3. `src/components/voluntariado/FormVoluntariados.astro`

- Sustituir el CTA de Google Forms por un enlace de correo:
  `mailto:cermolinadesegura@gmail.com`.
- Ajustar el texto de la tarjeta para indicar que se escriba a ese correo para pedir información
  (eliminar la referencia a "Google Forms" y al placeholder `GOOGLE_FORM_URL_VOLUNTARIADO`).
- Mantener el diseño de la tarjeta.

### 4. `src/components/contacto/InfoContacto.astro`

- Sustituir `info@cermolinasegura.com` por `cermolinadesegura@gmail.com` (tanto en el `href`
  `mailto:` como en el texto visible).

### 5. `src/components/Footer.astro`

- Sustituir `info@cermolina.org` por `cermolinadesegura@gmail.com` (en el `href` `mailto:` y en el
  texto).
- Actualizar el párrafo descriptivo a:
  "Nos dedicamos a la gestión y cuidado de colonias felinas y a la adopción responsable de gatos en
  Molina de Segura."

### 6. Changelog

- Añadir la entrada de la spec `05` en `specs/0.1.0/00-changelog.md` al cerrar.

## Technical decision

- Centralizar las URLs de formularios externos en `src/data/links.ts` (mismo patrón que
  `ADOPTION_FORM_URL`), para no dejar strings sueltos en los componentes.
- Unificar el correo en un único valor (`cermolinadesegura@gmail.com`) para evitar divergencias
  entre contacto y footer.
- Los enlaces `mailto:` no son rutas internas, por lo que **no** requieren `getPath()`.
- El botón de socios abrirá el formulario externo en pestaña nueva, igual que el de adopciones.

### Decisiones de redacción

- En el footer se **conserva** la frase de cierre "Tu ayuda hace posible su segunda oportunidad."
  tras el nuevo texto (confirmado por la asociación durante la aprobación).

## Affected files

- `src/data/links.ts` — añadir `MEMBERSHIP_FORM_URL`.
- `src/components/socios/Beneficios.astro` — botón al formulario real.
- `src/components/voluntariado/FormVoluntariados.astro` — correo en lugar del formulario roto.
- `src/components/contacto/InfoContacto.astro` — correo unificado.
- `src/components/Footer.astro` — correo unificado + texto descriptivo.
- `specs/0.1.0/00-changelog.md` — entrada al cerrar.

## Tests

- `pnpm astro check` sin errores.
- `pnpm build` OK.
- Búsqueda en el repo: no deben quedar `info@cermolinasegura.com`, `info@cermolina.org` ni
  `GOOGLE_FORM_URL_VOLUNTARIADO`.
- Verificación en navegador (agent-browser):
  - `/cer-molina-ser/socios` → el botón abre el formulario de socios en pestaña nueva.
  - `/cer-molina-ser/voluntariado` → el CTA abre `mailto:cermolinadesegura@gmail.com`.
  - `/cer-molina-ser/contacto` y el footer muestran `cermolinadesegura@gmail.com`.
  - El footer muestra el texto nuevo.

## Acceptance criteria

- [x] El botón "Quiero ser socio ahora" abre el formulario real de socios (sin `#formulario-socio`).
- [x] `src/data/links.ts` expone `MEMBERSHIP_FORM_URL`.
- [x] El CTA de voluntariado abre `mailto:cermolinadesegura@gmail.com` (sin placeholder).
- [x] `contacto` y `footer` muestran `cermolinadesegura@gmail.com`.
- [x] No quedan referencias a `info@cermolinasegura.com` ni `info@cermolina.org`.
- [x] El footer muestra el nuevo texto sobre colonias felinas y adopción responsable.
- [x] `pnpm astro check` y `pnpm build` sin errores.
