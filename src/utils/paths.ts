const BASE_URL = "/cer-molina-ser";

export const getPath = (path: string) => {
  // Evita duplicar si el path ya empieza con el base
  if (path.startsWith(BASE_URL)) return path;
  // Asegura que el path empiece con /
  const cleanPath = path.startsWith("/") ? path : `/${path}`;
  return `${BASE_URL}${cleanPath}`;
};
