import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:storify/utilis/notification_database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _databaseService = NotificationDatabaseService();
  }

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Database service
  late final NotificationDatabaseService _databaseService;

  // Callback functions that UI can register to be notified of new notifications
  List<Function(NotificationItem)> _newNotificationCallbacks = [];
  List<Function(List<NotificationItem>)> _notificationsListChangedCallbacks =
      [];

  // NEW: Low stock notification handler
  Function()? _lowStockNotificationHandler;

  // In-memory store of notifications
  List<NotificationItem> _notifications = [];

  // Track initialization state
  bool _isInitialized = false;
  bool _isInitializing = false;

  // OPTIMIZED: Fast, non-blocking initialization
  static Future<void> initialize() async {
    final instance = NotificationService();

    if (instance._isInitialized || instance._isInitializing) {
      print('NotificationService already initialized or initializing');
      return;
    }

    instance._isInitializing = true;

    try {
      // 1. Quick local notifications setup (non-blocking)
      await instance._initLocalNotifications();

      // 2. Load cached notifications immediately (fast)
      await instance._loadNotifications();

      // 3. Set up message handlers immediately
      FirebaseMessaging.onMessage.listen(instance._handleForegroundMessage);

      print('NotificationService: Quick initialization completed');
      instance._isInitialized = true;
      instance._isInitializing = false;

      // 4. Do heavy operations in background (non-blocking)
      _initializeInBackground();
    } catch (e) {
      print('Error in quick notification initialization: $e');
      instance._isInitializing = false;
      // Don't throw - let app continue without notifications
    }
  }

  // Background initialization - doesn't block app startup
  static void _initializeInBackground() {
    final instance = NotificationService();

    // Run heavy operations in background
    Future.microtask(() async {
      try {
        print('NotificationService: Starting background initialization...');

        // Handle permissions based on platform
        if (kIsWeb) {
          await instance._requestWebPermissions();
        } else {
          await instance._requestMobilePermissions();
        }

        // Get token in background
        String? token = await FirebaseMessaging.instance.getToken(
          vapidKey: kIsWeb
              ? "YOUR_VAPID_KEY_HERE"
              : null, // Add your VAPID key for web
        );

        if (token != null) {
          print('FCM Token obtained: ${token.substring(0, 20)}...');

          // Send token to backend (non-blocking)
          instance._sendTokenToBackend(token).catchError((e) {
            print('Error sending token to backend: $e');
          });
        }

        // Load from Firestore in background
        instance.loadNotificationsFromFirestore().catchError((e) {
          print('Error loading from Firestore: $e');
        });

        print('NotificationService: Background initialization completed');
      } catch (e) {
        print('Error in background notification initialization: $e');
        // Don't throw - notifications are not critical for app function
      }
    });
  }

  // Web-specific permission handling
  Future<void> _requestWebPermissions() async {
    try {
      // Check current permission status first
      NotificationSettings settings =
          await FirebaseMessaging.instance.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        print('Requesting web notification permissions...');

        // Request permission (this may show popup but won't block since it's in background)
        final newSettings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        print('Web permission result: ${newSettings.authorizationStatus}');

        if (newSettings.authorizationStatus == AuthorizationStatus.authorized) {
          print('Web notifications permission granted');
        } else {
          print('Web notifications permission denied or not determined');
        }
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        print('Web notifications already authorized');
      } else {
        print(
            'Web notifications not authorized: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('Error requesting web permissions: $e');
    }
  }

  // Mobile-specific permission handling
  Future<void> _requestMobilePermissions() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('Mobile permission result: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting mobile permissions: $e');
    }
  }

  // Initialize local notifications (fast, non-blocking)
  Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification tapped: ${response.payload}');
        },
      );

      print('Local notifications initialized');
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  // Show a local notification
  Future<void> showNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'firebase_push_channel',
        'Firebase Push Notifications',
        channelDescription: 'Channel for Firebase push notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        platformChannelSpecifics,
        payload: message.data.toString(),
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
    // Store the notification for when app is opened
    final notification = NotificationItem.fromFirebaseMessage(message);
    await _storeBackgroundNotification(notification);
  }

  // Store background notifications
  static Future<void> _storeBackgroundNotification(
      NotificationItem notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing background notifications
      List<Map<String, dynamic>> bgNotifications = [];
      String? existingData = prefs.getString('background_notifications');
      if (existingData != null) {
        bgNotifications =
            List<Map<String, dynamic>>.from(jsonDecode(existingData));
      }

      // Convert to storable format
      Map<String, dynamic> notificationData = {
        'id': notification.id,
        'title': notification.title,
        'message': notification.message,
        'timeAgo': notification.timeAgo,
        'isRead': notification.isRead,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add new notification
      bgNotifications.add(notificationData);

      // Store back
      await prefs.setString(
          'background_notifications', jsonEncode(bgNotifications));
    } catch (e) {
      print('Error storing background notification: $e');
    }
  }

  // Process any background notifications when app starts (OPTIMIZED)
  Future<void> processBackgroundNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? existingData = prefs.getString('background_notifications');

      if (existingData != null) {
        List<dynamic> bgNotifications = jsonDecode(existingData);

        for (var notificationData in bgNotifications) {
          // Convert to NotificationItem
          final notification = NotificationItem(
            id: notificationData['id'],
            title: notificationData['title'],
            message: notificationData['message'],
            timeAgo: _getTimeAgo(DateTime.parse(notificationData['timestamp'])),
            isRead: notificationData['isRead'] ?? false,
          );

          // Add to list
          _notifications.add(notification);
        }

        // Clear background notifications
        await prefs.remove('background_notifications');

        // Save merged notifications
        await _saveNotifications();

        // Notify listeners
        for (var callback in _notificationsListChangedCallbacks) {
          callback(_notifications);
        }

        // Save to Firestore in background (non-blocking)
        for (var notification in _notifications) {
          _databaseService.saveNotification(notification).catchError((e) {
            print('Error saving background notification to Firestore: $e');
          });
        }
      }
    } catch (e) {
      print('Error processing background notifications: $e');
    }
  }

  // OPTIMIZED: Send the FCM token to your backend (non-blocking)
  Future<void> _sendTokenToBackend(String? token) async {
    if (token == null) return;

    try {
      // Get auth headers
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Get user's info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentRole = await AuthService.getCurrentRole() ?? '';
      final supplierId = prefs.getInt('supplierId');

      // Create request body
      final body = {
        'token': token,
        'role': currentRole,
        if (supplierId != null) 'supplierId': supplierId,
      };

      print('Sending token to backend...');

      // Send to your backend with timeout
      final response = await http
          .post(
            Uri.parse(
                'https://finalproject-a5ls.onrender.com/notifications/register-token'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Successfully registered FCM token with backend');
      } else {
        print('Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending token to backend: $e');
      // Don't throw - token registration failure shouldn't break the app
    }
  }

  // Register callbacks for UI to be notified when new notifications arrive
  void registerNewNotificationCallback(Function(NotificationItem) callback) {
    _newNotificationCallbacks.add(callback);
  }

  void registerNotificationsListChangedCallback(
      Function(List<NotificationItem>) callback) {
    _notificationsListChangedCallbacks.add(callback);

    // Immediately call with current notifications
    callback(_notifications);
  }

  // NEW: Register low stock notification handler
  void registerLowStockNotificationHandler(Function() handler) {
    _lowStockNotificationHandler = handler;
    print('🔔 Low stock notification handler registered');
  }

  // Unregister callbacks when they're no longer needed
  void unregisterNewNotificationCallback(Function(NotificationItem) callback) {
    _newNotificationCallbacks.remove(callback);
  }

  void unregisterNotificationsListChangedCallback(
      Function(List<NotificationItem>) callback) {
    _notificationsListChangedCallbacks.remove(callback);
  }

  // Handle incoming foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      // Show local notification
      showNotification(message);

      // Convert to NotificationItem
      final notification = NotificationItem.fromFirebaseMessage(message);

      // Add to list
      _notifications.add(notification);

      // Save to SharedPreferences
      _saveNotifications();

      // Save to Firestore in background (non-blocking)
      _databaseService.saveNotification(notification).catchError((e) {
        print('Error saving notification to Firestore: $e');
      });

      // Notify listeners
      for (var callback in _newNotificationCallbacks) {
        callback(notification);
      }

      for (var callback in _notificationsListChangedCallbacks) {
        callback(_notifications);
      }
    }
  }

  // Get all notifications
  List<NotificationItem> getNotifications() {
    // Sort by timestamp (newest first) and return a copy
    final notifications = List<NotificationItem>.from(_notifications);
    notifications.sort((a, b) {
      return b.id.compareTo(a.id); // Using id as a proxy for timestamp
    });
    return notifications;
  }

  // Get unread count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Mark notification as read
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      // Create a new notification with isRead set to true
      final updatedNotification = NotificationItem(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        timeAgo: _notifications[index].timeAgo,
        icon: _notifications[index].icon,
        iconBackgroundColor: _notifications[index].iconBackgroundColor,
        isRead: true,
        onTap: _notifications[index].onTap,
      );

      // Replace in list
      _notifications[index] = updatedNotification;

      // Save to SharedPreferences
      await _saveNotifications();

      // Save to Firestore in background (non-blocking)
      _databaseService.markAsRead(id).catchError((e) {
        print('Error marking as read in Firestore: $e');
      });

      // Notify listeners
      for (var callback in _notificationsListChangedCallbacks) {
        callback(_notifications);
      }
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    List<NotificationItem> updatedList = [];

    for (var notification in _notifications) {
      // Create a new notification with isRead set to true
      updatedList.add(NotificationItem(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        timeAgo: notification.timeAgo,
        icon: notification.icon,
        iconBackgroundColor: notification.iconBackgroundColor,
        isRead: true,
        onTap: notification.onTap,
      ));
    }

    _notifications = updatedList;

    // Save to SharedPreferences
    await _saveNotifications();

    // Save to Firestore in background (non-blocking)
    _databaseService.markAllAsRead().catchError((e) {
      print('Error marking all as read in Firestore: $e');
    });

    // Notify listeners
    for (var callback in _notificationsListChangedCallbacks) {
      callback(_notifications);
    }
  }

  // Send a notification to a supplier
  Future<void> sendNotificationToSupplier(int supplierId, String title,
      String message, Map<String, dynamic> additionalData) async {
    try {
      // Get auth headers
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Create request body
      final body = {
        'supplierId': supplierId,
        'title': title,
        'body': message,
        'data': additionalData,
      };

      print('Sending supplier notification...');

      // Send to your backend with timeout
      final response = await http
          .post(
            Uri.parse(
                'https://finalproject-a5ls.onrender.com/notifications/send-to-supplier'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Successfully sent notification to supplier');
      } else {
        print(
            'Failed to send notification to supplier: ${response.statusCode}');

        // Add a local notification for immediate feedback
        final testNotification = NotificationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Supplier Notification (Local)',
          message: 'Notification to supplier ID $supplierId: $message',
          timeAgo: 'Just now',
          isRead: false,
          icon: Icons.business,
        );

        _notifications.add(testNotification);
        await _saveNotifications();

        // Save to Firestore in background
        _databaseService.saveNotification(testNotification).catchError((e) {
          print('Error saving to Firestore: $e');
        });

        // Notify listeners
        for (var callback in _notificationsListChangedCallbacks) {
          callback(_notifications);
        }
      }
    } catch (e) {
      print('Error sending notification to supplier: $e');
    }
  }

  // Send a notification to admin
  Future<void> sendNotificationToAdmin(
      String title, String message, Map<String, dynamic> additionalData) async {
    try {
      // Get auth headers
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Create request body
      final body = {
        'title': title,
        'body': message,
        'data': additionalData,
      };

      print('Sending admin notification...');

      // Send to your backend with timeout
      final response = await http
          .post(
            Uri.parse(
                'https://finalproject-a5ls.onrender.com/notifications/send-to-admin'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Successfully sent notification to admin');
      } else {
        print('Failed to send notification to admin: ${response.statusCode}');
      }

      // Add a local notification for immediate feedback regardless of API response
      final testNotification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        timeAgo: 'Just now',
        isRead: false,
        icon: Icons.admin_panel_settings,
      );

      _notifications.add(testNotification);
      await _saveNotifications();

      // Save to Firestore in background
      _databaseService.saveNotification(testNotification).catchError((e) {
        print('Error saving to Firestore: $e');
      });

      // Notify listeners
      for (var callback in _notificationsListChangedCallbacks) {
        callback(_notifications);
      }
    } catch (e) {
      print('Error sending notification to admin: $e');

      // Even if there's an error, add a local notification
      final errorNotification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Error Sending Notification',
        message: 'Failed to send: $title - $message',
        timeAgo: 'Just now',
        isRead: false,
        icon: Icons.error,
      );

      _notifications.add(errorNotification);
      await _saveNotifications();

      // Notify listeners
      for (var callback in _notificationsListChangedCallbacks) {
        callback(_notifications);
      }
    }
  }

  // OPTIMIZED: Save notifications to SharedPreferences (fast)
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> notificationsJson = _notifications
          .map((notification) => _enhancedNotificationToMap(notification))
          .toList();

      await prefs.setString('notifications', jsonEncode(notificationsJson));
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Enhanced notification to map with low stock type
  Map<String, dynamic> _enhancedNotificationToMap(
      NotificationItem notification) {
    final map = notification.toMap();

    // Add special type for low stock notifications
    if (notification.title.contains('Stock Alert') ||
        notification.title.contains('Low Stock')) {
      map['type'] = 'low_stock';
    }

    return map;
  }

  // Enhanced notification from map
  NotificationItem _enhancedNotificationFromMap(Map<String, dynamic> map) {
    final notification = NotificationItem.fromMap(map);
    return notification;
  }

  // OPTIMIZED: Load notifications from SharedPreferences (fast)
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');

      if (notificationsJson != null) {
        final List decodedList = jsonDecode(notificationsJson);
        _notifications = decodedList
            .map((item) =>
                _enhancedNotificationFromMap(item as Map<String, dynamic>))
            .toList();

        print(
            'Loaded ${_notifications.length} notifications from SharedPreferences');
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
    }
  }

  // OPTIMIZED: Load notifications from Firestore (background, non-blocking)
  Future<void> loadNotificationsFromFirestore() async {
    try {
      print('Loading notifications from Firestore...');
      final firestoreNotifications =
          await _databaseService.getAllNotifications();

      if (firestoreNotifications.isNotEmpty) {
        print(
            'Loaded ${firestoreNotifications.length} notifications from Firestore');

        // Merge with existing notifications, avoiding duplicates
        final existingIds = _notifications.map((n) => n.id).toSet();
        final newNotifications = firestoreNotifications
            .where((n) => !existingIds.contains(n.id))
            .toList();

        if (newNotifications.isNotEmpty) {
          _notifications.addAll(newNotifications);

          // Save to SharedPreferences for offline access
          await _saveNotifications();

          // Notify listeners
          for (var callback in _notificationsListChangedCallbacks) {
            callback(_notifications);
          }
        }
      }
    } catch (e) {
      print('Error loading notifications from Firestore: $e');
    }
  }

  // Helper to calculate time ago
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Test database connection
  Future<void> testDatabaseConnection() async {
    try {
      // Get auth headers
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Test connection to backend with timeout
      final response = await http
          .get(
            Uri.parse('https://finalproject-a5ls.onrender.com/health'),
            headers: headers,
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Show success notification
        await addManualNotification(
          'Database Connection Test',
          'Successfully connected to the database! Status: ${response.statusCode}',
        );
      } else {
        // Show error notification
        await addManualNotification(
          'Database Connection Test',
          'Failed to connect to database. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Show error notification
      await addManualNotification(
        'Database Connection Test',
        'Error testing database connection: $e',
      );
    }
  }

  // Check Firestore connection
  Future<void> checkFirestoreConnection() async {
    try {
      print('Checking Firestore connection...');

      // Try to write a test document with timeout
      final testDoc = {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Firestore connection test'
      };

      await FirebaseFirestore.instance
          .collection('connection_tests')
          .add(testDoc)
          .timeout(Duration(seconds: 5));

      print('Successfully wrote test document to Firestore');

      // Force reload notifications in background
      loadNotificationsFromFirestore().catchError((e) {
        print('Error reloading notifications: $e');
      });
    } catch (e) {
      print('Firestore connection test failed: $e');
    }
  }

  // Add a manual notification for testing
  Future<void> addManualNotification(String title, String message) async {
    final testNotification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timeAgo: 'Just now',
      isRead: false,
      icon: Icons.notifications,
    );

    _notifications.add(testNotification);
    await _saveNotifications();

    // Notify listeners
    for (var callback in _notificationsListChangedCallbacks) {
      callback(_notifications);
    }
  }

  // Add a public method to save notifications
  Future<void> saveNotification(NotificationItem notification) async {
    try {
      // Add to in-memory list
      _notifications.add(notification);

      // Save to SharedPreferences
      await _saveNotifications();

      // Save to database in background (non-blocking)
      _databaseService.saveNotification(notification).catchError((e) {
        print('Error saving notification to database: $e');
      });

      // Notify listeners
      for (var callback in _newNotificationCallbacks) {
        callback(notification);
      }

      for (var callback in _notificationsListChangedCallbacks) {
        callback(_notifications);
      }
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  // NEW: Save low stock notification with special handling
  Future<void> saveLowStockNotification(NotificationItem notification) async {
    try {
      // Add to in-memory list
      _notifications.add(notification);

      // Save to SharedPreferences
      await _saveNotifications();

      // Save to database in background (non-blocking)
      _databaseService.saveNotification(notification).catchError((e) {
        print('Error saving low stock notification to database: $e');
      });

      // Notify listeners
      for (var callback in _newNotificationCallbacks) {
        callback(notification);
      }

      for (var callback in _notificationsListChangedCallbacks) {
        callback(_notifications);
      }

      print('Saved low stock notification: ${notification.title}');
    } catch (e) {
      print('Error saving low stock notification: $e');
    }
  }

  // NEW: Handle notification tap - checks if it's a low stock notification
  bool handleNotificationTap(NotificationItem notification) {
    if (notification.title.contains('Stock Alert') ||
        notification.title.contains('Low Stock')) {
      print('🔔 Low stock notification tapped: ${notification.title}');

      // Call the registered handler if available
      if (_lowStockNotificationHandler != null) {
        _lowStockNotificationHandler!();
        return true; // Handled
      } else {
        print('⚠️ No low stock notification handler registered');
        return false; // Not handled
      }
    }

    return false; // Not a low stock notification
  }
}
