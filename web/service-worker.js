const CACHE_NAME = "statistieken-cache-v1";

const OFFLINE_URLS = [
  "/statistieken/",
  "/statistieken/index.html",
  "/statistieken/manifest.json",
  "/statistieken/version.json",
  "/statistieken/flutter.js",
  "/statistieken/flutter_bootstrap.js",
  "/statistieken/main.dart.js",
  "/statistieken/icons/Icon-192.avif",
  "/statistieken/icons/Icon-512.avif",
  "/statistieken/icons/Icon-maskable-192.avif",
  "/statistieken/icons/Icon-maskable-512.avif",
  "/statistieken/assets/AssetManifest.bin",
  "/statistieken/assets/FontManifest.json",
  "/statistieken/assets/NOTICES"
];

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(OFFLINE_URLS))
  );
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", event => {
  // Alleen cachen binnen jouw site
  if (event.request.url.includes("/statistieken/")) {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(event.request))
    );
  }
});
