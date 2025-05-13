import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/supplier/widgets/orderwidgets/OrderDetails_Model.dart';

class ApiService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  // Fetch all orders for a supplier
  Future<List<Order>> fetchSupplierOrders() async {
    try {
      // Get auth headers for the current role
      final headers = await AuthService.getAuthHeaders();

      // Using the CORRECT endpoint for supplier orders
      final response = await http.get(
        Uri.parse('$baseUrl/supplierOrders/my/orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> ordersList = data['orders'];

        return ordersList
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  // Updated method to handle partial acceptance
  Future<bool> updateOrderStatus(
    int orderId,
    String status, {
    String? note,
    List<Map<String, dynamic>>? declinedItems,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final Map<String, dynamic> body = {
        'status': status,
      };

      if (note != null && note.isNotEmpty) {
        body['note'] = note;
      }

      // Add declined items if provided (for partial acceptance)
      if (declinedItems != null && declinedItems.isNotEmpty) {
        body['items'] = declinedItems;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/supplierOrders/$orderId/status'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
            'Failed to update order status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }
}
