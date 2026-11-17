---
code: "08"
title: "Fondos de sección con <Picture> en vez de background-image CSS"
project: "cer-molina-ser"
status: completed
version: "0.1.0"
date: 2026-11-17
tags: [spec, sdd, imagen, rendimiento, lcp]
affected_files:
  - src/components/home/Hero.astro
  - src/components/sobre-nosotros/MetodoCER.astro
  - src/components/adopciones/AdoptarAhora.astro
  - specs/0.1.0/00-changelog.md
---

# Fondos de sección con `<Picture>` en vez de `background-image` CSS

## Purpose

Servir los fondos de tres secciones con `<Picture>` responsiva (AVIF/WebP, 3 anchos) en lugar de
`background-image: url(...)` a resolución completa, para bajar el LCP y cumplir la convención de
`AGENTS.md` ("sírvelas con `<Picture>` de `astro:assets`, no como CSS `background`").

## Context

- Hoy los tres fondos se aplican con `<style define:vars={{ bgUrl: url(...) }}>`:
  se descarga **una sola** imagen (hasta 1920 px tras la spec 07) en todos los dispositivos, sin
  `srcset`, sin AVIF y con `background-attachment: fixed`, que en iOS se ignora y provoca
  repintados en scroll.
- Gradientes actuales (se conservan para no cambiar el diseño):
  - `Hero.astro`: `linear-gradient(to right, rgba(79,0,0,.85), rgba(79,0,0,.4))`, texto blanco.
  - `MetodoCER.astro`: `to right`, `rgba(79,0,0,.95)` → `rgba(79,0,0,.7)`.
  - `AdoptarAhora.astro`: `to bottom`, `rgba(79,0,0,.8)` en ambos extremos.
- Tailwind 4.3 renombró las utilidades: `bg-gradient-*` → `bg-linear-*` (ya se usa
  `bg-linear-to-r` en `recursos/InfoLegal.astro`).
- La spec 07 deja los ficheros en `src/assets/web/home-hero.webp` (1920 px),
  `bg-cer.webp` y `bg-adopta.webp` (1920 px), todos < 300 KB.
- El hero es el elemento LCP de la home: hoy pesa 820 KB (6240×4160) y no puede priorizarse.

## Proposed change

En los tres componentes, sustituir el bloque `<style define:vars>` por una capa de imagen y otra
de degradado, dejando el contenido en `relative z-10`:

```astro
---
import { Picture } from "astro:assets";
import bgImageWelcome from "@assets/web/home-hero.webp";
---

<section class="relative isolate min-h-[60vh] py-12 flex items-center justify-center overflow-hidden">
  <Picture
    src={bgImageWelcome}
    formats={["avif", "webp"]}
    widths={[768, 1280, 1920]}
    sizes="100vw"
    alt=""
    loading="eager"
    fetchpriority="high"
    decoding="async"
    class="absolute inset-0 -z-20 h-full w-full object-cover"
  />
  <div class="absolute inset-0 -z-10 bg-linear-to-r from-[#4f0000]/85 to-[#4f0000]/40"></div>

  <div class="relative z-10 w-full xl:max-w-7xl px-6 ..."><!-- contenido igual --></div>
</section>
```

- `MetodoCER` y `AdoptarAhora` usan `loading="lazy"` y `fetchpriority` por defecto (fuera de la
  primera pantalla), con sus gradientes respectivos (`to-r .95/.7`, `to-b .8/.8`).
- Se elimina `background-attachment: fixed`: el parallax se pierde en escritorio, pero el layout
  queda idéntico y se evita el repintado en móvil/iOS. Si más adelante se quiere parallax, se
  hace con `transform` y `prefers-reduced-motion`.
- `alt=""` + `aria-hidden` implícito: son fondos decorativos; la sección ya tiene su `h1`/`h2`.
- No se toca el resto de estilos (tipografías, espaciados, `max-w`, colores del contenido).

## Technical decision

- **`<Picture>` y no `<Image>`**: se generan AVIF y WebP con el mismo `srcset`; AVIF ahorra
  ~25-30 % sobre WebP en fotografía y Astro lo sirve con fallback automático.
- **3 anchos y `sizes="100vw"`**: el fondo ocupa el ancho completo; 768/1280/1920 cubre móvil,
  tablet y escritorio sin descargar 1920 px en un móvil de 390 px.
- **Capa absoluta en vez de `background`**: permite `fetchpriority="high"` (imposible con CSS),
  y el `object-cover` reproduce el comportamiento de `background-size: cover` +
  `background-position: center`.
- **`isolate` + `-z-20`/`-z-10`**: evita que las capas se escapen del contexto de apilado del
  `<section>` (los `-z-10` sin `isolate` se cuelan detrás del fondo de la página).
- **Colores arbitrarios `[#4f0000]`**: los tokens `maroon-*` no tienen ese valor exacto
  (`maroon-900` es `#4a0404`); se conserva el color actual en vez de aproximarlo.
- **Sin JS**: nada de lazy-load manual ni IntersectionObserver; lo resuelve el navegador.

## Affected files

- `src/components/home/Hero.astro` — `<style define:vars>` fuera; `<Picture>` eager + overlay.
- `src/components/sobre-nosotros/MetodoCER.astro` — idem, lazy.
- `src/components/adopciones/AdoptarAhora.astro` — idem, lazy.
- `specs/0.1.0/00-changelog.md` — entrada al cerrar.

## Tests

- `pnpm build`: en `dist/_astro/` aparecen variantes `.avif` y `.webp` de los tres fondos; el
  HTML de `/`, `/sobre-nosotros/` y `/adopciones/` contiene `<picture>` con `srcset` y no
  contiene `background-image: url(`.
- Home: `<img>` del hero con `fetchpriority="high"`, `loading="eager"` y `srcset` de 3 anchos.
- `/sobre-nosotros/` y `/adopciones/`: los dos fondos salen con `loading="lazy"`.
- Comparación visual antes/después en 390, 768 y 1440 px: mismo encuadre, mismo degradado, texto
  legible; sin franjas ni saltos al hacer scroll.
- Lighthouse móvil en `/`: LCP no incluye una imagen de fondo CSS y el peso de la home baja
  respecto a la medición previa.
- `pnpm astro check` sin errores.

## Acceptance criteria

- [x] Ningún componente de `src/` usa `background-image: url(...)` con una imagen de `@assets`.
- [x] Los tres fondos se sirven con `<Picture>` (`avif` + `webp`, 3 anchos, `sizes="100vw"`).
- [x] El hero lleva `loading="eager"` y `fetchpriority="high"`; los otros dos, `lazy`.
- [x] El diseño se mantiene: mismos degradados, encuadre y legibilidad en móvil y escritorio.
- [x] Sin `background-attachment: fixed` en el código.
- [x] `pnpm build` y `pnpm astro check` en verde.
