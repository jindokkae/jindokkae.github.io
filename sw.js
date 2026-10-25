self.addEventListener('install',()=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(self.clients.claim()));
self.addEventListener('notificationclick',e=>{e.notification.close();
  e.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(l=>{for(const c of l){if('focus' in c)return c.focus()}return self.clients.openWindow('./')}))});
self.addEventListener('push',e=>{let d={};try{d=e.data?e.data.json():{}}catch(_){d={body:e.data&&e.data.text()}}
  e.waitUntil(self.registration.showNotification(d.title||'진도깨',{body:d.body||'',icon:/밥숑/.test(d.title||'')?'icon-bab.png':'icon-jd.png',badge:/밥숑/.test(d.title||'')?'badge-bab.png':'icon-192.png',tag:d.tag||'jindokkae',data:{url:'./'}}))});
