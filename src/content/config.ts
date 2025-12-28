import { defineCollection, z } from "astro:content";

const blog = defineCollection({
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
