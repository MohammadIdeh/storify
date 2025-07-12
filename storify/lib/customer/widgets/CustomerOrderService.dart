// lib/customer/widgets/CustomerOrderService.dart
// Enhanced version with notification integration
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/customer/widgets/modelCustomer.dart';
import 'package:storify/utilis/notification_service.dart';
import 'package:storify/utilis/notificationModel.dart';

class CustomerOrderService {
  static const String baseUrl =
      'https://finalproject-a5ls.onrender.com/customer-order';

  // Get all categories
  static Future<List<Category>> getAllCategories() async {
    final headers = await AuthService.getAuthHeaders(role: 'Customer');
    final response = await http.get(
      Uri.parse('$baseUrl/all-category'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> categoriesJson = data['categories'];
      return categoriesJson.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  // Get products for a specific category
  static Future<List<Product>> getProductsByCategory(int categoryId) async {
    final headers = await AuthService.getAuthHeaders(role: 'Customer');
    final response = await http.get(
      Uri.parse('$baseUrl/category/$categoryId/products'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> productsJson = data['products'];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  // Enhanced place order with notification integration
  static Future<Map<String, dynamic>> placeOrder(Order order) async {
    final headers = await AuthService.getAuthHeaders(role: 'Customer');
    headers['Content-Type'] = 'application/json';

    debugPrint('🛒 Customer placing order...');

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(order.toJson()),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ Order placed successfully');

      // Get order details for notification
      final orderId = data['orderId'] ?? data['order']?['id'] ?? 'Unknown';
      final totalCost = data['totalCost'] ?? data['order']?['totalCost'] ?? 0.0;
      final itemCount = order.items.length;

      // Create success notification
      await _createOrderPlacedNotification(orderId, totalCost, itemCount);

      // Register for order status updates
      await _registerForOrderUpdates(orderId);

      return data;
    } else {
      debugPrint('❌ Order placement failed: ${response.statusCode}');

      // Check for insufficient stock error
      if (data.containsKey('available') && data.containsKey('requested')) {
        // Create insufficient stock notification
        await _createInsufficientStockNotification(
            data['productName'], data['available'], data['requested']);

        throw InsufficientStockException(
          productName: data['productName'],
          available: data['available'],
          requested: data['requested'],
          message: data['message'],
        );
      }

      // Create general error notification
      await _createOrderErrorNotification(data['message'] ?? 'Unknown error');

      throw Exception(
          'Failed to place order: ${data['message'] ?? response.statusCode}');
    }
  }

  // Get order history with notification polling
  static Future<List<dynamic>> getOrderHistory() async {
    final headers = await AuthService.getAuthHeaders(role: 'Customer');

    debugPrint('📋 Fetching customer order history...');

    final response = await http.get(
      Uri.parse('$baseUrl/myOrders'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final orders = data['orders'] as List<dynamic>;

      // Check for order status updates
      await _checkForOrderStatusUpdates(orders);

      return orders;
    } else {
      throw Exception('Failed to load order history: ${response.statusCode}');
    }
  }

  // Check if location is set
  static Future<bool> isLocationSet() async {
    final headers = await AuthService.getAuthHeaders(role: 'Customer');

    try {
      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/customer-details/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for location in the CUSTOMER object (not at top level)
        if (data.containsKey('customer') && data['customer'] != null) {
          final customer = data['customer'];
          final hasLatitude =
              customer.containsKey('latitude') && customer['latitude'] != null;
          final hasLongitude = customer.containsKey('longitude') &&
              customer['longitude'] != null;

          debugPrint(
              '📍 LOCATION CHECK - hasLat: $hasLatitude, hasLng: $hasLongitude');
          return hasLatitude && hasLongitude;
        }

        return false;
      } else {
        debugPrint('❌ Profile API error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception in isLocationSet: $e');
      return false;
    }
  }

  // ===============================
  // NOTIFICATION HELPER METHODS
  // ===============================

  // Create notification when order is placed successfully
  static Future<void> _createOrderPlacedNotification(
      dynamic orderId, double totalCost, int itemCount) async {
    try {
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '🛒 Order Placed Successfully',
        message:
            'Order #$orderId placed! $itemCount items - \$${totalCost.toStringAsFixed(2)}. We\'ll notify you when it\'s processed.',
        timeAgo: 'Just now',
        isRead: false,
        icon: Icons.check_circle,
        iconBackgroundColor: Colors.green,
        type: 'order_placed',
      );

      await NotificationService().saveNotification(notification);
      debugPrint('✅ Order placed notification created');
    } catch (e) {
      debugPrint('❌ Error creating order placed notification: $e');
    }
  }

  // Create notification for insufficient stock
  static Future<void> _createInsufficientStockNotification(
      String productName, int available, int requested) async {
    try {
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '⚠️ Insufficient Stock',
        message:
            '$productName: Only $available available, but you requested $requested. Please update your cart.',
        timeAgo: 'Just now',
        isRead: false,
        icon: Icons.inventory,
        iconBackgroundColor: Colors.orange,
        type: 'insufficient_stock',
      );

      await NotificationService().saveNotification(notification);
      debugPrint('⚠️ Insufficient stock notification created');
    } catch (e) {
      debugPrint('❌ Error creating insufficient stock notification: $e');
    }
  }

  // Create notification for order errors
  static Future<void> _createOrderErrorNotification(String errorMessage) async {
    try {
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '❌ Order Failed',
        message: 'Failed to place your order: $errorMessage. Please try again.',
        timeAgo: 'Just now',
        isRead: false,
        icon: Icons.error,
        iconBackgroundColor: Colors.red,
        type: 'order_error',
      );

      await NotificationService().saveNotification(notification);
      debugPrint('❌ Order error notification created');
    } catch (e) {
      debugPrint('❌ Error creating order error notification: $e');
    }
  }

  // Register customer for order status updates
  static Future<void> _registerForOrderUpdates(dynamic orderId) async {
    try {
      final headers = await AuthService.getAuthHeaders(role: 'Customer');
      headers['Content-Type'] = 'application/json';

      // Register with backend for push notifications
      final response = await http.post(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/notifications/register-order-updates'),
        headers: headers,
        body: jsonEncode({
          'orderId': orderId,
          'role': 'Customer',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Registered for order #$orderId updates');
      } else {
        debugPrint(
            '⚠️ Failed to register for order updates: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error registering for order updates: $e');
    }
  }

  // Check for order status updates and create notifications
  static Future<void> _checkForOrderStatusUpdates(List<dynamic> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckKey = 'last_order_status_check_customer';
      final lastCheck = prefs.getString(lastCheckKey);
      final currentTime = DateTime.now().toIso8601String();

      // Store current time for next check
      await prefs.setString(lastCheckKey, currentTime);

      if (lastCheck == null) {
        // First time checking, don't create notifications for existing orders
        debugPrint(
            '📋 First time checking order status - skipping notifications');
        return;
      }

      final lastCheckTime = DateTime.parse(lastCheck);

      for (var order in orders) {
        final orderUpdateTime =
            DateTime.parse(order['updatedAt'] ?? order['createdAt']);

        // Only check orders updated since last check
        if (orderUpdateTime.isAfter(lastCheckTime)) {
          await _createOrderStatusNotification(order);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking order status updates: $e');
    }
  }

  // Create notification for order status changes
  static Future<void> _createOrderStatusNotification(
      Map<String, dynamic> order) async {
    try {
      final orderId = order['id'];
      final status = order['status']?.toString().toLowerCase() ?? 'unknown';
      final totalCost = order['totalCost']?.toDouble() ?? 0.0;

      String title;
      String message;
      IconData icon;
      Color iconColor;
      String notificationType;

      switch (status) {
        case 'accepted':
          title = '✅ Order Accepted';
          message =
              'Great news! Order #$orderId has been accepted and is being prepared.';
          icon = Icons.thumb_up;
          iconColor = Colors.green;
          notificationType = 'order_accepted';
          break;
        case 'prepared':
          title = '👨‍🍳 Order Prepared';
          message = 'Order #$orderId is ready! It will be delivered soon.';
          icon = Icons.restaurant;
          iconColor = Colors.blue;
          notificationType = 'order_prepared';
          break;
        case 'delivered':
          title = '🚚 Order Delivered';
          message =
              'Order #$orderId has been delivered! Enjoy your items. Total: \$${totalCost.toStringAsFixed(2)}';
          icon = Icons.local_shipping;
          iconColor = Colors.green;
          notificationType = 'order_delivered';
          break;
        case 'cancelled':
          title = '❌ Order Cancelled';
          message =
              'Order #$orderId has been cancelled. You can place a new order anytime.';
          icon = Icons.cancel;
          iconColor = Colors.red;
          notificationType = 'order_cancelled';
          break;
        case 'rejected':
          title = '❌ Order Rejected';
          message =
              'Order #$orderId was rejected. Please contact support for more details.';
          icon = Icons.block;
          iconColor = Colors.red;
          notificationType = 'order_rejected';
          break;
        default:
          // Don't create notification for unknown statuses
          return;
      }

      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        timeAgo: 'Just now',
        isRead: false,
        icon: icon,
        iconBackgroundColor: iconColor,
        type: notificationType,
        onTap: () {
          // Navigate to order history or specific order
          debugPrint('🔔 Order status notification tapped for order #$orderId');
        },
      );

      await NotificationService().saveNotification(notification);
      debugPrint('🔔 Order status notification created: $title');
    } catch (e) {
      debugPrint('❌ Error creating order status notification: $e');
    }
  }

  // ===============================
  // LOW STOCK NOTIFICATIONS
  // ===============================

  // Create low stock notification for customers
  static Future<void> createLowStockNotification(
      String productName, int currentStock) async {
    try {
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '📦 Low Stock Alert',
        message:
            '$productName is running low ($currentStock left). Order soon to avoid disappointment!',
        timeAgo: 'Just now',
        isRead: false,
        icon: Icons.inventory_2,
        iconBackgroundColor: Colors.orange,
        type: 'low_stock',
        onTap: () {
          debugPrint('🔔 Low stock notification tapped for $productName');
          // Could navigate to product or show product list
        },
      );

      await NotificationService().saveLowStockNotification(notification);
      debugPrint('📦 Low stock notification created for $productName');
    } catch (e) {
      debugPrint('❌ Error creating low stock notification: $e');
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  // Initialize customer notifications
  static Future<void> initializeCustomerNotifications() async {
    try {
      debugPrint('🔔 Initializing customer notifications...');

      // Register FCM token with backend for customer role
      await NotificationService.initialize();

      // Register for low stock notifications handler
      NotificationService().registerLowStockNotificationHandler(() {
        debugPrint('🔔 Low stock notification handler called');
        // Could navigate to orders screen or show specific products
      });

      // Set up periodic order status checking
      _startPeriodicOrderStatusCheck();

      debugPrint('✅ Customer notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing customer notifications: $e');
    }
  }

  // Start periodic checking for order status updates
  static void _startPeriodicOrderStatusCheck() {
    // Check every 30 seconds for order updates
    Stream.periodic(Duration(seconds: 30)).listen((_) async {
      try {
        debugPrint('⏰ Periodic order status check...');
        await getOrderHistory(); // This will trigger status check
      } catch (e) {
        debugPrint('❌ Error in periodic order status check: $e');
      }
    });
  }

  // Send test notification (for debugging)
  static Future<void> sendTestNotification() async {
    try {
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '🧪 Test Notification',
        message:
            'This is a test notification for the customer app. Everything is working correctly!',
        timeAgo: 'Just now',
        isRead: false,
        icon: Icons.science,
        iconBackgroundColor: Colors.purple,
        type: 'test',
      );

      await NotificationService().saveNotification(notification);
      debugPrint('🧪 Test notification sent');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }
}

// Custom exception for insufficient stock (unchanged)
class InsufficientStockException implements Exception {
  final String productName;
  final int available;
  final int requested;
  final String message;

  InsufficientStockException({
    required this.productName,
    required this.available,
    required this.requested,
    required this.message,
  });

  @override
  String toString() {
    return message;
  }
}
