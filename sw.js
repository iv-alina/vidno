/* VIDNO · сервис-воркер
   Задача одна: страница всегда берётся из сети, иконки — из кеша,
   а когда выходит новая версия, приложение предлагает обновиться. */

var BUILD = '20260826-1146';                       // эту строку переписывает deploy.bat при каждой публикации
var CACHE = 'vidno-' + BUILD;
var SHELL = ['./', './index.html', './icon-180.png', './icon-512.png', './manifest.json'];

self.addEventListener('install', function(e){
  e.waitUntil(
    caches.open(CACHE).then(function(c){
      return Promise.all(SHELL.map(function(u){
        return fetch(u, {cache: 'reload'})            // мимо кеша браузера, иначе положим старое
          .then(function(res){ if (res.ok) return c.put(u, res); })
          .catch(function(){});
      }));
    })
  );
  // skipWaiting здесь не вызываем: новая версия ждёт, пока человек нажмёт «Обновить»
});

self.addEventListener('activate', function(e){
  e.waitUntil(
    caches.keys().then(function(keys){
      return Promise.all(keys.map(function(k){
        if (k !== CACHE) return caches.delete(k);     // чужие и старые кеши сносим подчистую
      }));
    }).then(function(){ return self.clients.claim(); })
  );
});

self.addEventListener('message', function(e){
  if (!e.data) return;
  if (e.data.type === 'skip-waiting') self.skipWaiting();
  if (e.data.type === 'build' && e.ports && e.ports[0]){
    e.ports[0].postMessage({build: BUILD});     // страница спрашивает, какая версия сейчас работает
  }
});

self.addEventListener('fetch', function(e){
  var req = e.request;
  if (req.method !== 'GET') return;

  var url;
  try { url = new URL(req.url); } catch(_){ return; }
  if (url.origin !== self.location.origin) return;    // шрифты Google и прочее чужое не трогаем

  var wantsHtml = req.mode === 'navigate' ||
                  (req.headers.get('accept') || '').indexOf('text/html') > -1;

  if (wantsHtml){                                     // страница: сначала сеть, кеш только на случай офлайна
    e.respondWith(
      fetch(req.url, {cache: 'no-store', credentials: 'same-origin'}).then(function(res){
        var copy = res.clone();
        caches.open(CACHE).then(function(c){ c.put('./index.html', copy); });
        return res;
      }).catch(function(){
        return caches.match('./index.html').then(function(r){
          return r || caches.match('./');
        });
      })
    );
    return;
  }

  e.respondWith(                                      // иконки и манифест: сначала кеш
    caches.match(req).then(function(hit){
      if (hit) return hit;
      return fetch(req).then(function(res){
        if (res.ok){
          var copy = res.clone();
          caches.open(CACHE).then(function(c){ c.put(req, copy); });
        }
        return res;
      });
    })
  );
});
