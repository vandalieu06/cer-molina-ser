// @ts-check
import { defineConfig } from "astro/config";

import tailwindcss from "@tailwindcss/vite";

// GitHub Pages (por defecto) usa el subpath; en Docker se compila con BASE_PATH="/".
// Se usa `||` y no `??` porque una variable vacía también debe caer al default.
const base = process.env.BASE_PATH || "/cer-molina-ser";
const site = process.env.SITE_URL || "https://vandalieu06.github.io";

// https://<username>.github.io/<my-repo>
// https://astro.build/config
export default defineConfig({
  vite: {
    plugins: [tailwindcss()],
  },
  site,
  base,
});
