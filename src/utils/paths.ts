const BASE_URL = import.meta.env.BASE_URL;

export const getPath = (path: string) => {
  if (path.startsWith(BASE_URL)) return path;
  const cleanPath = path.startsWith("/") ? path : `/${path}`;
  return `${BASE_URL}${cleanPath}`;
};
