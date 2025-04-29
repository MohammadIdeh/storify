// Give this file the name: firebase-messaging-sw.js
// Place it directly in the web/ folder of your Flutter project

importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

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

messaging.onBackgroundMessage((payload) => {
  console.log("Background message received:", payload);

  const notificationTitle = payload.notification?.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification from Storify',
    icon: '/icons/Icon-192.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});