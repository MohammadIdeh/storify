// lib/utilis/notificationService.dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Callback functions that UI can register to be notified of new notifications
  List<Function(NotificationItem)> _newNotificationCallbacks = [];
  List<Function(List<NotificationItem>)> _notificationsListChangedCallbacks =
      [];

  // In-memory store of notifications
  List<NotificationItem> _notifications = [];

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

    // Register background/terminated message handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Send token to backend
    await NotificationService().sendTokenToBackend(token);
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

  // Process any background notifications when app starts
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
        await saveNotifications();

        // Notify listeners
        for (var callback in _notificationsListChangedCallbacks) {
          callback(_notifications);
        }
      }
    } catch (e) {
      print('Error processing background notifications: $e');
    }
  }

  // Send the FCM token to your backend
  Future<void> sendTokenToBackend(String? token) async {
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

      // Send to your backend
      final response = await http.post(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/notifications/register-token'),
        headers: headers,
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
  void registerNewNotificationCallback(Function(NotificationItem) callback) {
    _newNotificationCallbacks.add(callback);
  }

  void registerNotificationsListChangedCallback(
      Function(List<NotificationItem>) callback) {
    _notificationsListChangedCallbacks.add(callback);
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

      // Convert to NotificationItem
      final notification = NotificationItem.fromFirebaseMessage(message);

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
  List<NotificationItem> getNotifications() {
    // Sort by timestamp (newest first) and return a copy
    final notifications = List<NotificationItem>.from(_notifications);
    notifications.sort((a, b) {
      // Parse the timeAgo and compare - this is simplified and would need real timestamp logic
      return b.id.compareTo(a.id); // Using id as a proxy for timestamp for now
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

      await saveNotifications();

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
    await saveNotifications();

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

      // Send to your backend
      final response = await http.post(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/notifications/send-to-supplier'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Successfully sent notification to supplier');
      } else {
        print('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending notification: $e');
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

      // Send to your backend
      final response = await http.post(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/notifications/send-to-admin'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Successfully sent notification to admin');
      } else {
        print('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Save notifications to SharedPreferences
  Future<void> saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> notificationsJson = _notifications
          .map((notification) => {
                'id': notification.id,
                'title': notification.title,
                'message': notification.message,
                'timeAgo': notification.timeAgo,
                'isRead': notification.isRead,
                // Cannot serialize icon, iconBackgroundColor, and onTap
              })
          .toList();

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
            .map((item) => NotificationItem(
                  id: item['id'],
                  title: item['title'],
                  message: item['message'],
                  timeAgo: item['timeAgo'],
                  isRead: item['isRead'] ?? false,
                  icon: Icons.notifications, // Default icon
                  iconBackgroundColor:
                      const Color.fromARGB(255, 105, 65, 198), // Default color
                ))
            .toList();
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
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
}
