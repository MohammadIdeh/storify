// firebase-messaging-sw.js
// Place it directly in the web/ folder of your Flutter project

importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

// Initialize Firebase with your configuration
firebase.initializeApp({
  apiKey: "AIzaSyDlDlnG_03TqqjNr-bZB9QTAkin1L6F2-8",
  authDomain: "storify-32241.firebaseapp.com",
  projectId: "storify-32241",
  storageBucket: "storify-32241.firebasestorage.app",
  messagingSenderId: "236339805910",
  appId: "1:236339805910:web:15f97918bb5385c1b09377",
  measurementId: "G-PN0H7TT9PS"
});

const messaging = firebase.messaging();

console.log('🔥 Storify Firebase messaging service worker initialized');

// Enhanced background message handler
messaging.onBackgroundMessage((payload) => {
  console.log("📱 Background message received:", payload);

  // Extract notification details
  const notificationTitle = payload.notification?.title || 'Storify Notification';
  const notificationBody = payload.notification?.body || 'You have a new notification from Storify';

  // Enhanced notification options
  const notificationOptions = {
    body: notificationBody,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'storify-notification',
    data: payload.data || {},
    requireInteraction: false,
    actions: [
      {
        action: 'open',
        title: 'Open Storify'
      },
      {
        action: 'dismiss',
        title: 'Dismiss'
      }
    ],
    // Add custom styling based on notification type
    image: payload.notification?.image,
    timestamp: Date.now(),
    silent: false,
    vibrate: [200, 100, 200] // Vibration pattern for mobile
  };

  // Customize notification based on type
  if (payload.data?.type) {
    switch (payload.data.type) {
      case 'low_stock':
        notificationOptions.tag = 'storify-low-stock';
        notificationOptions.icon = '/icons/Icon-192.png';
        break;
      case 'order':
        notificationOptions.tag = 'storify-order';
        notificationOptions.icon = '/icons/Icon-192.png';
        break;
      case 'supplier':
        notificationOptions.tag = 'storify-supplier';
        notificationOptions.icon = '/icons/Icon-192.png';
        break;
      default:
        notificationOptions.tag = 'storify-general';
    }
  }

  console.log('🔔 Showing notification:', notificationTitle);

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', function (event) {
  console.log('🔔 Notification clicked:', event);

  const notification = event.notification;
  const action = event.action;
  const data = notification.data || {};

  // Close the notification
  notification.close();

  // Handle dismiss action
  if (action === 'dismiss') {
    console.log('🔔 Notification dismissed by user');
    return;
  }

  // Handle open action or default click
  console.log('🔔 Opening Storify app...');

  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then(function (clientList) {

      // Look for existing Storify window
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url.includes(location.origin)) {
          console.log('🔔 Found existing Storify window, focusing it');

          // Send navigation data to the existing window
          if (data.type || data.orderId) {
            client.postMessage({
              type: 'notification_click',
              notificationType: data.type,
              orderId: data.orderId,
              supplierId: data.supplierId,
              data: data
            });
          }

          return client.focus();
        }
      }

      // No existing window, open new one
      console.log('🔔 Opening new Storify window');

      let url = '/';

      // Add URL parameters for navigation
      if (data.type || data.orderId) {
        const params = new URLSearchParams();
        if (data.type) params.append('notificationType', data.type);
        if (data.orderId) params.append('orderId', data.orderId);
        if (data.supplierId) params.append('supplierId', data.supplierId);
        url = '/?' + params.toString();
      }

      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    }).catch(function (error) {
      console.error('❌ Error handling notification click:', error);
    })
  );
});

// Handle notification close
self.addEventListener('notificationclose', function (event) {
  console.log('🔔 Notification closed:', event.notification.tag);
});

// Service Worker lifecycle
self.addEventListener('install', function (event) {
  console.log('🔧 Storify Service Worker installing...');
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  console.log('🔧 Storify Service Worker activated');
  event.waitUntil(clients.claim());
});

// Handle messages from main app
self.addEventListener('message', function (event) {
  console.log('📨 Service Worker message received:', event.data);

  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Error handling
self.addEventListener('error', function (event) {
  console.error('❌ Service Worker error:', event.error);
});

console.log('✅ Storify service worker setup complete');