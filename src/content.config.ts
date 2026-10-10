import { defineCollection } from "astro:content";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

const blog = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/content/blog" }),
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      date: z.string(),
      tag: z.string(),
      excerpt: z.string(),
      image: image(), // Astro procesará y optimizará estas imágenes
    }),
});

export const collections = { blog };
