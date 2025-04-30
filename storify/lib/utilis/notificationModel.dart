import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final IconData? icon;
  final Color? iconBackgroundColor;
  final bool isRead;
  final Function()? onTap;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.icon,
    this.iconBackgroundColor,
    this.isRead = false,
    this.onTap,
  });

  // Create from a Firebase message
  factory NotificationItem.fromFirebaseMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    return NotificationItem(
      id: message.messageId ?? DateTime.now().toString(),
      title: notification?.title ?? 'New Notification',
      message: notification?.body ?? 'You have a new notification',
      timeAgo: 'Just now', // You'll need to calculate this
      isRead: false,
    );
  }
}