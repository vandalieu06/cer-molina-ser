export const pageTitle = "Cer Molina Segura";

export interface SubPage {
  title: string;
  url: string;
}

export type Page = {
  title: string;
  url: string;
  children?: SubPage[];
};

export const pages: Page[] = [
  { title: "Inicio", url: `/` },
  { title: "Sobre Nosotros", url: `/sobre-nosotros` },
  {
    title: "Adopciones",
    url: `/adopciones`,
    children: [
      { title: "Ver adopciones", url: `/adopciones` },
      { title: "Gatos en adopción", url: `/adopciones/gatos` },
    ],
  },
  { title: "Colonias Felinas", url: `/colonias-felinas` },
  { title: "Voluntariado", url: `/voluntariado` },
  { title: "Hazte Socio/a", url: `/socios` },
  { title: "Donaciones", url: `/donaciones` },
  { title: "Recursos", url: `/recursos` },
  { title: "Noticias", url: `/noticias` },
  { title: "Contacto", url: `/contacto` },
];
