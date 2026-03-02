self.addEventListener("install", event => {
  console.log("Service Worker installed");
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  console.log("Service Worker active");
});

self.addEventListener("fetch", event => {
  return; // laat alles gewoon online lopen
});
