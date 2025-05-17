// lib/employee/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';

class OrderService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  // Get customer orders
  static Future<Map<String, dynamic>> getCustomerOrders() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/customer-orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to load customer orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching customer orders: $e');
      rethrow;
    }
  }

  // Get supplier orders
  static Future<Map<String, dynamic>> getSupplierOrders() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/supplier-orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to load supplier orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching supplier orders: $e');
      rethrow;
    }
  }

  // Get customer order details
  static Future<Map<String, dynamic>> getCustomerOrderDetails(
      int orderId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/customer-orders/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to load customer order details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching customer order details: $e');
      rethrow;
    }
  }

  // Update customer order status
  static Future<Map<String, dynamic>> updateCustomerOrderStatus(
      int orderId, String status, String? note) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final Map<String, dynamic> body = {
        'status': status,
      };

      if (note != null && note.isNotEmpty) {
        body['note'] = note;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/worker/customer-orders/$orderId'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to update customer order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating customer order: $e');
      rethrow;
    }
  }

  // Get supplier order details
  static Future<Map<String, dynamic>> getSupplierOrderDetails(
      int orderId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/supplier-orders/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to load supplier order details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching supplier order details: $e');
      rethrow;
    }
  }

  // Update supplier order status
  static Future<Map<String, dynamic>> updateSupplierOrderStatus(
      int orderId,
      String status,
      String? note,
      List<Map<String, dynamic>>? updatedItems) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final Map<String, dynamic> body = {
        'status': status,
      };

      if (note != null && note.isNotEmpty) {
        body['note'] = note;
      }

      if (updatedItems != null && updatedItems.isNotEmpty) {
        body['items'] = updatedItems;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/worker/supplier-orders/$orderId'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to update supplier order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating supplier order: $e');
      rethrow;
    }
  }

  // Get order history
  static Future<Map<String, dynamic>> getOrderHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/orders-history?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load order history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching order history: $e');
      rethrow;
    }
  }
}
