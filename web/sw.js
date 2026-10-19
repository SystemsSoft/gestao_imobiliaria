// Service worker do app instalável (PWA). Sempre busca a versão mais nova
// no servidor; sem internet, abre a última tela inicial guardada.
const CACHE = 'mb-gestao-v1';
const INICIO = './';

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.add(INICIO)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((chaves) => Promise.all(chaves.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (e) => {
  if (e.request.mode !== 'navigate') return; // API, arquivos e vídeos: direto
  e.respondWith(
    fetch(e.request)
      .then((r) => {
        const copia = r.clone();
        caches.open(CACHE).then((c) => c.put(INICIO, copia));
        return r;
      })
      .catch(() => caches.match(INICIO)),
  );
});
