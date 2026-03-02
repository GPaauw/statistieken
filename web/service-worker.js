const CACHE_NAME = "statistieken-cache-v1";

// Voeg hier ALLE bestanden toe die offline moeten werken:
const OFFLINE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/version.json',
  '/flutter.js',
  '/flutter_bootstrap.js',
  // main.dart.js is the main compiled application.
  // Its name can change if build options are used, but this is the default.
  '/main.dart.js',
  '/icons/Icon-192.avif',
  '/icons/Icon-512.avif',
  '/icons/Icon-maskable-192.avif',
  '/icons/Icon-maskable-512.avif',
  // The following files are essential for loading assets and fonts.
  '/assets/AssetManifest.bin',
  '/assets/FontManifest.json',
  '/assets/NOTICES'
];

// Install: cache alle offline-bestanden
self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(OFFLINE_URLS);
    })
  );
  self.skipWaiting();
});

// Activate: oude caches verwijderen
self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

// Fetch: probeer netwerk, zo niet → gebruik cache
self.addEventListener("fetch", event => {
  event.respondWith(
    fetch(event.request).catch(() =>
      caches.match(event.request)
    )
  );
});
