interface Page {
  title: string;
  url: string;
}

export const pageTitle = "CER Molina Segura";

export const pages: Page[] = [
  { title: "Inicio", url: "/" },
  { title: "Sobre Nosotros", url: "/sobre-nosotros" },
  { title: "Adopciones", url: "/adopciones" },
  { title: "Colinas Felinas", url: "/colonias-felinas" },
  { title: "Voluntariado", url: "/voluntariado" },
  { title: "Hazte Socio/a", url: "/socios" },
  { title: "Donaciones", url: "/donaciones" },
  { title: "Recursos", url: "/recursos" },
  { title: "Contacto", url: "/contacto" },
];
