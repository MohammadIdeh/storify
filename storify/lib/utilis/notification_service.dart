// lib/utilis/notification_service.dart
// Enhanced version with better customer integration
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

  // Role-specific notification handlers
  Function()? _lowStockNotificationHandler;
  Function(String orderId)? _orderStatusUpdateHandler;
  Function(NotificationItem)? _customerNotificationHandler;

  // In-memory store of notifications
  List<NotificationItem> _notifications = [];

  // Track initialization state
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Current user role for filtering notifications
  String? _currentRole;

  // OPTIMIZED: Fast, non-blocking initialization
  static Future<void> initialize() async {
    final instance = NotificationService();

    if (instance._isInitialized || instance._isInitializing) {
      debugPrint('NotificationService already initialized or initializing');
      return;
    }

    instance._isInitializing = true;

    try {
      // Get current role
      instance._currentRole = await AuthService.getCurrentRole();
      debugPrint(
          '🔔 Initializing NotificationService for role: ${instance._currentRole}');

      // 1. Quick local notifications setup (non-blocking)
      await instance._initLocalNotifications();

      // 2. Load cached notifications immediately (fast)
      await instance._loadNotifications();

      // 3. Set up message handlers immediately
      FirebaseMessaging.onMessage.listen(instance._handleForegroundMessage);

      debugPrint('NotificationService: Quick initialization completed');
      instance._isInitialized = true;
      instance._isInitializing = false;

      // 4. Do heavy operations in background (non-blocking)
      _initializeInBackground();
    } catch (e) {
      debugPrint('Error in quick notification initialization: $e');
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
        debugPrint(
            'NotificationService: Starting background initialization...');

        // Handle permissions based on platform
        if (kIsWeb) {
          await instance._requestWebPermissions();
        } else {
          await instance._requestMobilePermissions();
        }

        // Get token in background
        String? token = await FirebaseMessaging.instance.getToken(
          vapidKey: kIsWeb
              ? "BOHOh4GKJLNdRFctdSl4_Uj5PDBrwOOyKpEODbTCaC4bJlBJF3g_Cw0z_4QkNBVGQTM5F9x-hTvG7wQtdV_Ng_c"
              : null, // Add your VAPID key for web
        );

        if (token != null) {
          debugPrint('FCM Token obtained: ${token.substring(0, 20)}...');

          // Send token to backend (non-blocking)
          instance._sendTokenToBackend(token).catchError((e) {
            debugPrint('Error sending token to backend: $e');
          });
        }

        // Load from Firestore in background
        instance.loadNotificationsFromFirestore().catchError((e) {
          debugPrint('Error loading from Firestore: $e');
        });

        debugPrint('NotificationService: Background initialization completed');
      } catch (e) {
        debugPrint('Error in background notification initialization: $e');
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
        debugPrint('Requesting web notification permissions...');

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

        debugPrint('Web permission result: ${newSettings.authorizationStatus}');

        if (newSettings.authorizationStatus == AuthorizationStatus.authorized) {
          debugPrint('Web notifications permission granted');
        } else {
          debugPrint('Web notifications permission denied or not determined');
        }
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        debugPrint('Web notifications already authorized');
      } else {
        debugPrint(
            'Web notifications not authorized: ${settings.authorizationStatus}');
      }
    } catch (e) {
      debugPrint('Error requesting web permissions: $e');
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

      debugPrint('Mobile permission result: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error requesting mobile permissions: $e');
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
          debugPrint('Notification tapped: ${response.payload}');
          _handleNotificationTap(response.payload);
        },
      );

      debugPrint('Local notifications initialized');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  // Handle notification tap from local notifications
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        final type = data['type'];
        final orderId = data['orderId'];

        debugPrint('🔔 Notification tapped - Type: $type, OrderID: $orderId');

        switch (type) {
          case 'order_status':
            if (_orderStatusUpdateHandler != null && orderId != null) {
              _orderStatusUpdateHandler!(orderId);
            }
            break;
          case 'low_stock':
            if (_lowStockNotificationHandler != null) {
              _lowStockNotificationHandler!();
            }
            break;
        }
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
      }
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
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    debugPrint("Handling a background message: ${message.messageId}");
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
        'type': notification.type,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add new notification
      bgNotifications.add(notificationData);

      // Store back
      await prefs.setString(
          'background_notifications', jsonEncode(bgNotifications));
    } catch (e) {
      debugPrint('Error storing background notification: $e');
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
            type: notificationData['type'],
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
            debugPrint('Error saving background notification to Firestore: $e');
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing background notifications: $e');
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

      debugPrint('Sending token to backend for role: $currentRole');

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
        debugPrint('Successfully registered FCM token with backend');
      } else {
        debugPrint('Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending token to backend: $e');
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

  // CUSTOMER-SPECIFIC HANDLERS
  void registerLowStockNotificationHandler(Function() handler) {
    _lowStockNotificationHandler = handler;
    debugPrint('🔔 Low stock notification handler registered');
  }

  void registerOrderStatusUpdateHandler(Function(String orderId) handler) {
    _orderStatusUpdateHandler = handler;
    debugPrint('🔔 Order status update handler registered');
  }

  void registerCustomerNotificationHandler(Function(NotificationItem) handler) {
    _customerNotificationHandler = handler;
    debugPrint('🔔 Customer notification handler registered');
  }

  // Unregister callbacks when they're no longer needed
  void unregisterNewNotificationCallback(Function(NotificationItem) callback) {
    _newNotificationCallbacks.remove(callback);
  }

  void unregisterNotificationsListChangedCallback(
      Function(List<NotificationItem>) callback) {
    _notificationsListChangedCallbacks.remove(callback);
  }

  void unregisterLowStockNotificationHandler() {
    _lowStockNotificationHandler = null;
    debugPrint('🔔 Low stock notification handler unregistered');
  }

  void unregisterOrderStatusUpdateHandler() {
    _orderStatusUpdateHandler = null;
    debugPrint('🔔 Order status update handler unregistered');
  }

  void unregisterCustomerNotificationHandler() {
    _customerNotificationHandler = null;
    debugPrint('🔔 Customer notification handler unregistered');
  }

  // Handle incoming foreground messages with role-specific processing
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
          'Message also contained a notification: ${message.notification}');

      // Show local notification
      showNotification(message);

      // Convert to NotificationItem
      final notification = NotificationItem.fromFirebaseMessage(message);

      // Check if this notification is for the current role
      if (_shouldProcessNotificationForCurrentRole(
          notification, message.data)) {
        // Add to list
        _notifications.add(notification);

        // Save to SharedPreferences
        _saveNotifications();

        // Save to Firestore in background (non-blocking)
        _databaseService.saveNotification(notification).catchError((e) {
          debugPrint('Error saving notification to Firestore: $e');
        });

        // Handle role-specific notifications
        _handleRoleSpecificNotification(notification, message.data);

        // Notify listeners
        for (var callback in _newNotificationCallbacks) {
          callback(notification);
        }

        for (var callback in _notificationsListChangedCallbacks) {
          callback(_notifications);
        }
      }
    }
  }

  // Check if notification should be processed for current role
  bool _shouldProcessNotificationForCurrentRole(
      NotificationItem notification, Map<String, dynamic> data) {
    final notificationRole = data['targetRole'];
    final currentRole = _currentRole;

    // If no target role specified, show to all
    if (notificationRole == null) return true;

    // If target role matches current role
    if (notificationRole == currentRole) return true;

    // For customer-specific checks
    if (currentRole == 'Customer') {
      // Show order-related notifications
      if (notification.type?.contains('order') == true) return true;
      // Show low stock notifications
      if (notification.type == 'low_stock') return true;
    }

    return false;
  }

  // Handle role-specific notification processing
  void _handleRoleSpecificNotification(
      NotificationItem notification, Map<String, dynamic> data) {
    if (_currentRole == 'Customer') {
      _handleCustomerNotification(notification, data);
    }
  }

  // Handle customer-specific notifications
  void _handleCustomerNotification(
      NotificationItem notification, Map<String, dynamic> data) {
    debugPrint('🛒 Processing customer notification: ${notification.type}');

    switch (notification.type) {
      case 'order_accepted':
      case 'order_prepared':
      case 'order_delivered':
      case 'order_cancelled':
      case 'order_rejected':
        final orderId = data['orderId'];
        if (_orderStatusUpdateHandler != null && orderId != null) {
          _orderStatusUpdateHandler!(orderId);
        }
        break;

      case 'low_stock':
        if (_lowStockNotificationHandler != null) {
          _lowStockNotificationHandler!();
        }
        break;
    }

    // Call general customer handler
    if (_customerNotificationHandler != null) {
      _customerNotificationHandler!(notification);
    }
  }

  // Get all notifications (filtered by role if needed)
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
      final updatedNotification = _notifications[index].copyWith(isRead: true);

      // Replace in list
      _notifications[index] = updatedNotification;

      // Save to SharedPreferences
      await _saveNotifications();

      // Save to Firestore in background (non-blocking)
      _databaseService.markAsRead(id).catchError((e) {
        debugPrint('Error marking as read in Firestore: $e');
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
      updatedList.add(notification.copyWith(isRead: true));
    }

    _notifications = updatedList;

    // Save to SharedPreferences
    await _saveNotifications();

    // Save to Firestore in background (non-blocking)
    _databaseService.markAllAsRead().catchError((e) {
      debugPrint('Error marking all as read in Firestore: $e');
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

      debugPrint('Sending supplier notification...');

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
        debugPrint('Successfully sent notification to supplier');
      } else {
        debugPrint(
            'Failed to send notification to supplier: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending notification to supplier: $e');
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

      debugPrint('Sending admin notification...');

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
        debugPrint('Successfully sent notification to admin');
      } else {
        debugPrint(
            'Failed to send notification to admin: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending notification to admin: $e');
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
      debugPrint('Error saving notifications: $e');
    }
  }

  // Enhanced notification to map with low stock type
  Map<String, dynamic> _enhancedNotificationToMap(
      NotificationItem notification) {
    return notification.toMap();
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

        debugPrint(
            'Loaded ${_notifications.length} notifications from SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      _notifications = [];
    }
  }

  // OPTIMIZED: Load notifications from Firestore (background, non-blocking)
  Future<void> loadNotificationsFromFirestore() async {
    try {
      debugPrint('Loading notifications from Firestore...');
      final firestoreNotifications =
          await _databaseService.getAllNotifications();

      if (firestoreNotifications.isNotEmpty) {
        debugPrint(
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
      debugPrint('Error loading notifications from Firestore: $e');
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

  // Add a manual notification for testing
  Future<void> addManualNotification(String title, String message) async {
    final testNotification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timeAgo: 'Just now',
      isRead: false,
      icon: Icons.notifications,
      type: 'manual',
    );

    await saveNotification(testNotification);
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
        debugPrint('Error saving notification to database: $e');
      });

      // Notify listeners
      for (var callback in _newNotificationCallbacks) {
        callback(notification);
      }

      for (var callback in _notificationsListChangedCallbacks) {
        callback(_notifications);
      }
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  // Save low stock notification with special handling
  Future<void> saveLowStockNotification(NotificationItem notification) async {
    try {
      // Add to in-memory list
      _notifications.add(notification);

      // Save to SharedPreferences
      await _saveNotifications();

      // Save to database in background (non-blocking)
      _databaseService.saveNotification(notification).catchError((e) {
        debugPrint('Error saving low stock notification to database: $e');
      });

      // Notify listeners
      for (var callback in _newNotificationCallbacks) {
        callback(notification);
      }

      for (var callback in _notificationsListChangedCallbacks) {
        callback(_notifications);
      }

      debugPrint('Saved low stock notification: ${notification.title}');
    } catch (e) {
      debugPrint('Error saving low stock notification: $e');
    }
  }

  // Handle notification tap - checks type and calls appropriate handler
  bool handleNotificationTap(NotificationItem notification) {
    debugPrint(
        '🔔 Notification tapped: ${notification.title} (${notification.type})');

    switch (notification.type) {
      case 'low_stock':
        if (_lowStockNotificationHandler != null) {
          _lowStockNotificationHandler!();
          return true;
        }
        break;

      case 'order_accepted':
      case 'order_prepared':
      case 'order_delivered':
      case 'order_cancelled':
      case 'order_rejected':
        // Extract order ID from message or title
        final orderIdMatch = RegExp(r'#(\d+)').firstMatch(notification.message);
        if (orderIdMatch != null && _orderStatusUpdateHandler != null) {
          final orderId = orderIdMatch.group(1)!;
          _orderStatusUpdateHandler!(orderId);
          return true;
        }
        break;
    }

    // Call general customer handler if available
    if (_customerNotificationHandler != null) {
      _customerNotificationHandler!(notification);
      return true;
    }

    return false; // Not handled
  }

  // Update current role (useful when user switches roles)
  Future<void> updateCurrentRole(String role) async {
    _currentRole = role;
    debugPrint('🔔 NotificationService role updated to: $role');

    // Re-register token with new role
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      _sendTokenToBackend(token).catchError((e) {
        debugPrint('Error updating token for new role: $e');
      });
    }
  }
}
