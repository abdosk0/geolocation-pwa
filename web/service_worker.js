// service_worker.js

// Define cache name and files to cache
var CACHE_NAME = 'my-flutter-app-cache';
var urlsToCache = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/manifest.json',
  '/favicon.ico',
  // Add any other assets or URLs to cache here
];

// Install service worker and cache assets
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(urlsToCache);
    })
  );
});

// Fetch assets from cache or network
self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request).then(function(response) {
      return response || fetch(event.request);
    })
  );
});
