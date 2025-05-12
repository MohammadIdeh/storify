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
  final int? supplierId;
  final String? supplierName;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.icon,
    this.iconBackgroundColor,
    this.isRead = false,
    this.onTap,
    this.supplierId,
    this.supplierName,
  });

  // Create from a Firebase message
  factory NotificationItem.fromFirebaseMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    return NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? 'New Notification',
      message: notification?.body ?? 'You have a new notification',
      timeAgo: 'Just now',
      isRead: false,
      supplierId: data['supplierId'] != null ? int.parse(data['supplierId']) : null,
      supplierName: data['supplierName'],
    );
  }
  
  // Create a copy with updated properties
  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? timeAgo,
    IconData? icon,
    Color? iconBackgroundColor,
    bool? isRead,
    Function()? onTap,
    int? supplierId,
    String? supplierName,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      icon: icon ?? this.icon,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      isRead: isRead ?? this.isRead,
      onTap: onTap ?? this.onTap,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
    );
  }
  
  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timeAgo': timeAgo,
      'isRead': isRead,
      'supplierId': supplierId,
      'supplierName': supplierName,
      // Cannot serialize icon, iconBackgroundColor, and onTap
    };
  }
  
  // Create from Map
  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timeAgo: map['timeAgo'] ?? 'Just now',
      isRead: map['isRead'] ?? false,
      supplierId: map['supplierId'],
      supplierName: map['supplierName'],
    );
  }
  
  @override
  String toString() {
    return 'NotificationItem(id: $id, title: $title, message: $message, timeAgo: $timeAgo, isRead: $isRead, supplierId: $supplierId, supplierName: $supplierName)';
  }
}