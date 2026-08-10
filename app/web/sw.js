/* EZPZ Study service worker.
 *
 * Recent Flutter deprecated its built-in offline service worker, so we ship our
 * own. It makes the app installable (Chrome needs an active SW with a fetch
 * handler) and makes it load fast and work offline.
 *
 * Strategy: STALE-WHILE-REVALIDATE for every same-origin GET.
 *   • Serve from cache immediately when present → the app opens INSTANTLY even
 *     on slow/flaky mobile data or fully offline (this is the key property for a
 *     village pilot). No waiting on the network to show the UI.
 *   • In the background, fetch a fresh copy and update the cache for next time.
 *   • Not cached yet → fetch from network and cache it.
 *
 * Every file is handled the SAME way, so a load always draws one consistent set
 * of files from the cache — this avoids the "fresh JS + stale assets" mismatch
 * that a split cache-first/network-first strategy caused (which crashed the app
 * to a black screen).
 *
 * Cross-origin requests (e.g. Supabase) are not intercepted.
 */
'use strict';

const CACHE = 'ezpz-cache-v4';

// The app-shell files to precache on install (best-effort). These are ONLY the
// files a Chromium browser (Chrome / Samsung Internet — ~all Android users)
// actually downloads. We deliberately DO NOT list the full `canvaskit.wasm`
// (2.9MB) or `skwasm.wasm` (1.5MB): Chrome uses the smaller `canvaskit/chromium`
// build, so precaching the others just wastes ~4.4MB of download on first load
// (this was the main cause of the very slow first open on mobile data).
// Precaching reuses the browser's HTTP cache (default cache mode), so it copies
// the files the page already fetched rather than downloading them again.
const SHELL = [
  'index.html',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
  'sqlite3.wasm',
  'drift_worker.js',
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // Precache the shell REUSING the browser's HTTP cache (default cache mode).
    // Registration happens on window 'load', after the page has already
    // downloaded these files, so this just copies them into the SW cache — it
    // does NOT re-download them. (Using {cache:'reload'} here previously forced
    // a second full download of the whole app, doubling the first-load data and
    // making it painfully slow on mobile data.)
    await Promise.all(SHELL.map((u) => cache.add(u).catch(() => {})));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
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
    const cached = await cache.match(request);

    const network = fetch(request)
        .then((fresh) => {
          if (fresh && fresh.ok) cache.put(request, fresh.clone());
          return fresh;
        })
        .catch(() => null);

    if (cached) {
      // Serve the cached copy now; refresh the cache in the background.
      event.waitUntil(network);
      return cached;
    }

    // Nothing cached yet (first visit / new file): use the network.
    const fresh = await network;
    if (fresh) return fresh;

    // Offline and uncached: fall back to the app shell for navigations.
    if (request.mode === 'navigate') {
      const index = await cache.match('index.html');
      if (index) return index;
    }
    return Response.error();
  })());
});
