// lib/admin/widgets/OrderSupplierWidgets/customer_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/customer_models.dart';

class CustomerService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  /// Fetch all customers
  static Future<List<Customer>> getCustomers() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/customer-order/customers'),
        headers: headers,
      );

      debugPrint('🔍 Customers API Response Status: ${response.statusCode}');
      debugPrint('🔍 Customers API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['message'] == 'Customers retrieved successfully') {
          final List<dynamic> customersJson = data['customers'];
          return customersJson
              .map((customerJson) => Customer.fromJson(customerJson))
              .toList();
        } else {
          throw Exception('Failed to load customers: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to load customers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 Error fetching customers: $e');
      throw Exception('Error fetching customers: $e');
    }
  }

  /// Fetch order history for a specific customer
  static Future<CustomerOrderHistory> getCustomerOrderHistory(
      int customerId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/customer-order/customer/$customerId/history'),
        headers: headers,
      );

      debugPrint(
          '🔍 Customer History API Response Status: ${response.statusCode}');
      debugPrint('🔍 Customer History API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CustomerOrderHistory.fromJson(data);
      } else {
        throw Exception(
            'Failed to load customer order history. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 Error fetching customer order history: $e');
      throw Exception('Error fetching customer order history: $e');
    }
  }

  /// Get customer statistics
  static Map<String, int> getCustomerStats(List<Customer> customers) {
    int activeCustomers = 0;
    int totalOrders = 0;
    double totalAccountBalance = 0.0;

    for (var customer in customers) {
      if (customer.user.isActive == 'Active') {
        activeCustomers++;
      }
      totalOrders += customer.orderCount;
      totalAccountBalance += double.tryParse(customer.accountBalance) ?? 0.0;
    }

    return {
      'total': customers.length,
      'active': activeCustomers,
      'totalOrders': totalOrders,
      'avgOrders':
          customers.isNotEmpty ? (totalOrders / customers.length).round() : 0,
    };
  }

  /// Get order statistics for a customer
  static Map<String, dynamic> getOrderStats(List<CustomerOrder> orders) {
    if (orders.isEmpty) {
      return {
        'total': 0,
        'completed': 0,
        'cancelled': 0,
        'active': 0,
        'totalSpent': 0.0,
        'avgOrderValue': 0.0,
      };
    }

    int completed = 0;
    int cancelled = 0;
    int active = 0;
    double totalSpent = 0.0;

    for (var order in orders) {
      totalSpent += order.totalCost;

      switch (order.status.toLowerCase()) {
        case 'delivered':
        case 'shipped':
          completed++;
          break;
        case 'cancelled':
        case 'declined':
        case 'rejected':
          cancelled++;
          break;
        case 'accepted':
        case 'assigned':
        case 'preparing':
        case 'prepared':
        case 'on_theway':
          active++;
          break;
      }
    }

    return {
      'total': orders.length,
      'completed': completed,
      'cancelled': cancelled,
      'active': active,
      'totalSpent': totalSpent,
      'avgOrderValue': totalSpent / orders.length,
    };
  }

  /// Format currency value
  static String formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  /// Format date string
  static String formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return "${date.day}-${date.month}-${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  /// Format date with time
  static String formatDateTime(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }
}
