/* EZPZ Study service worker.
 *
 * Recent Flutter deprecated its built-in offline service worker, so we ship our
 * own. It does two jobs:
 *   1. Makes the app installable (Chrome requires an active SW with a fetch
 *      handler before it offers "Install app" / "Add to Home screen").
 *   2. Speeds up repeat visits and enables offline use by caching the app shell
 *      (CanvasKit, wasm, fonts, the content pack) so they aren't re-downloaded.
 *
 * Strategy:
 *   • JS + navigations  → network-first (always get the latest app logic when
 *     online; fall back to cache when offline).
 *   • everything else   → cache-first (large, build-stable files: wasm,
 *     canvaskit, fonts, images, the versioned content JSON).
 *   • cross-origin (e.g. Supabase) → not intercepted; passes straight through.
 *
 * Bump CACHE on each deploy to evict the previous build's cached files.
 */
'use strict';

const CACHE = 'ezpz-cache-v1';

self.addEventListener('install', (event) => {
  // Activate this SW immediately without waiting for old tabs to close.
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    // Drop caches from previous builds.
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

function isNetworkFirst(url, request) {
  if (request.mode === 'navigate') return true;
  return /\.(js|json)$/.test(url.pathname) &&
         !url.pathname.includes('/assets/'); // content pack JSON stays cache-first
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  // Only handle same-origin requests; let Supabase / other hosts pass through.
  if (url.origin !== self.location.origin) return;

  if (isNetworkFirst(url, request)) {
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
    return;
  }

  // Cache-first for large, build-stable assets.
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const cached = await cache.match(request);
    if (cached) return cached;
    const fresh = await fetch(request);
    if (fresh && fresh.ok) cache.put(request, fresh.clone());
    return fresh;
  })());
});
