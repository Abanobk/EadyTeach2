importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAXhB_kJF3MbrJpCpfnFnWfdkCpYBSIkDU",
  authDomain: "easytech2.firebaseapp.com",
  projectId: "easytech2",
  storageBucket: "easytech2.firebasestorage.app",
  messagingSenderId: "621394137104",
  appId: "1:621394137104:web:REPLACE_WITH_WEB_APP_ID"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title || 'Easy Tech';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/app/icons/Icon-192.png',
    badge: '/app/icons/Icon-192.png',
    data: payload.data,
    tag: payload.data?.type || 'general',
    requireInteraction: true,
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const data = event.notification.data || {};
  let url = '/app/';

  if (data.type === 'task' && data.refId) {
    url = '/app/#/task/' + data.refId;
  } else if (data.type === 'quotation' && data.refId) {
    url = '/app/#/quotation/' + data.refId;
  } else if (data.type === 'order') {
    url = '/app/#/admin';
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var client of clientList) {
        if (client.url.includes('/app') && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    })
  );
});
