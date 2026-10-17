// 画面の枠だけ先に入れ、ほかは使った時に入れる。BGM（範囲の読み込み）は入れない
const CACHE_NAME = 'depthline-fleet-v3';
const APP_SHELL = ['/', '/index.html', '/manifest.json', '/favicon.svg', '/icons/icon-192.png', '/icons/icon-512.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.map((key) => (key === CACHE_NAME ? null : caches.delete(key)))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;
  if (event.request.headers.has('range') || /\.mp3$/.test(url.pathname)) return;
  const hashed = url.pathname.startsWith('/assets/') && /-[A-Za-z0-9_]{8,}\.(js|css)$/.test(url.pathname);
  if (hashed) {
    // 名前に指紋のある物はキャッシュ優先
    event.respondWith(caches.match(event.request).then((hit) => hit ?? fetch(event.request).then((res) => {
      if (res.ok) { const copy = res.clone(); caches.open(CACHE_NAME).then((c) => c.put(event.request, copy)); }
      return res;
    })));
    return;
  }
  // それ以外は新しい物を優先（つながらない時はキャッシュ）
  event.respondWith(fetch(event.request).then((res) => {
    if (res.ok) { const copy = res.clone(); caches.open(CACHE_NAME).then((c) => c.put(event.request, copy)); }
    return res;
  }).catch(() => caches.match(event.request).then((hit) => hit ?? caches.match('/index.html'))));
});
