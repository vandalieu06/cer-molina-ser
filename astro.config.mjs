// @ts-check
import { defineConfig } from "astro/config";

import tailwindcss from "@tailwindcss/vite";
// https://<username>.github.io/<my-repo>
// https://astro.build/config
export default defineConfig({
  vite: {
    plugins: [tailwindcss()],
  },
  site: "https://vandalieu06.github.io",
  base: "/cer-molina-ser",
});
