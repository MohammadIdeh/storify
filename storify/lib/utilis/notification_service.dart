import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Define a class to represent notifications stored locally
class StoredNotification {
  final String id;
  final String title;
  final String message;
  final String type; // e.g., "new_product", "order_status"
  final Map<String, dynamic> data;
  final DateTime timestamp;
  bool isRead;

  StoredNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isRead = false,
  });

  // Create from Firebase message
  factory StoredNotification.fromFirebaseMessage(RemoteMessage message) {
    return StoredNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      message: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      data: Map<String, dynamic>.from(message.data),
      timestamp: DateTime.now(),
      isRead: false,
    );
  }

  // Convert to and from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory StoredNotification.fromJson(Map<String, dynamic> json) {
    return StoredNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'],
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Callback functions that UI can register to be notified of new notifications
  List<Function(StoredNotification)> _newNotificationCallbacks = [];
  List<Function(List<StoredNotification>)> _notificationsListChangedCallbacks =
      [];

  // In-memory store of notifications
  List<StoredNotification> _notifications = [];

  // Initialize Firebase Messaging
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get token
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');

    // Load saved notifications from SharedPreferences
    await NotificationService().loadNotifications();

    // Register foreground message handler
    FirebaseMessaging.onMessage.listen(
      NotificationService()._handleForegroundMessage,
    );

    // Send token to backend
    await NotificationService().sendTokenToBackend(token);
  }

  // Send the FCM token to your backend
  Future<void> sendTokenToBackend(String? token) async {
    if (token == null) return;

    try {
      // Get user's info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final roleName = prefs.getString('currentRole') ?? '';
      final supplierId = prefs.getInt('supplierId');

      // Create request body
      final body = {
        'token': token,
        'role': roleName,
        if (supplierId != null) 'supplierId': supplierId,
      };

      // Send to your backend
      final response = await http.post(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/notifications/register-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Successfully registered FCM token with backend');
      } else {
        print('Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending token to backend: $e');
    }
  }

  // Register callbacks for UI to be notified when new notifications arrive
  void registerNewNotificationCallback(Function(StoredNotification) callback) {
    _newNotificationCallbacks.add(callback);
  }

  void registerNotificationsListChangedCallback(
      Function(List<StoredNotification>) callback) {
    _notificationsListChangedCallbacks.add(callback);
  }

  // Unregister callbacks when they're no longer needed
  void unregisterNewNotificationCallback(
      Function(StoredNotification) callback) {
    _newNotificationCallbacks.remove(callback);
  }

  void unregisterNotificationsListChangedCallback(
      Function(List<StoredNotification>) callback) {
    _notificationsListChangedCallbacks.remove(callback);
  }

  // Handle incoming foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      // Convert to StoredNotification
      final notification = StoredNotification.fromFirebaseMessage(message);

      // Add to list
      _notifications.add(notification);

      // Save to SharedPreferences
      saveNotifications();

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
  List<StoredNotification> getNotifications() {
    return List.from(_notifications); // Return a copy
  }

  // Get unread count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Mark notification as read
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await saveNotifications();

      // Notify listeners
      for (var callback in _notificationsListChangedCallbacks) {
        callback(_notifications);
      }
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    await saveNotifications();

    // Notify listeners
    for (var callback in _notificationsListChangedCallbacks) {
      callback(_notifications);
    }
  }

  // Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    await saveNotifications();

    // Notify listeners
    for (var callback in _notificationsListChangedCallbacks) {
      callback(_notifications);
    }
  }

  // Save notifications to SharedPreferences
  Future<void> saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('notifications', jsonEncode(notificationsJson));
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Load notifications from SharedPreferences
  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');

      if (notificationsJson != null) {
        final List decodedList = jsonDecode(notificationsJson);
        _notifications = decodedList
            .map((item) => StoredNotification.fromJson(item))
            .toList();

        // Sort by timestamp (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
    }
  }
}
