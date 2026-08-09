/* EZPZ Study service worker.
 *
 * Recent Flutter deprecated its built-in offline service worker, so we ship our
 * own. It makes the app installable (Chrome needs an active SW with a fetch
 * handler) and lets it work offline.
 *
 * Strategy: NETWORK-FIRST for every same-origin GET, falling back to the cache
 * only when offline. This is deliberately chosen over cache-first: a cache-first
 * SW that isn't perfectly versioned can serve a *stale mix* of files after a new
 * deploy (e.g. an old AssetManifest/CanvasKit with new Dart code), which crashes
 * a Flutter web app to a black screen. Network-first guarantees that when the
 * user is online they always get one consistent build, while still working
 * offline from the last successful load.
 *
 * Cross-origin requests (e.g. Supabase) are not intercepted.
 */
'use strict';

const CACHE = 'ezpz-cache-v2';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    // Purge every previous cache (including the old cache-first v1) so no stale
    // files survive a deploy.
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return; // let Supabase etc. pass through

  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    try {
      const fresh = await fetch(request);
      if (fresh && fresh.ok) cache.put(request, fresh.clone());
      return fresh;
    } catch (err) {
      const cached = await cache.match(request);
      if (cached) return cached;
      if (request.mode === 'navigate') {
        const index = await cache.match('index.html');
        if (index) return index;
      }
      throw err;
    }
  })());
});
