import 'dart:convert';

import 'package:flutter/material.dart';
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

  // Updated method to handle partial acceptance with production/expiry dates and notes
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

      // Add items array if provided (for partial acceptance or when dates/notes are included)
      if (declinedItems != null && declinedItems.isNotEmpty) {
        body['items'] = declinedItems;

        // Debug print to verify the structure
        debugPrint('Sending items to API: ${json.encode(declinedItems)}');

        // Validate that each item has the required structure
        for (var item in declinedItems) {
          if (!item.containsKey('id')) {
            throw Exception('Each item must have an "id" field');
          }

          // Optional fields validation
          if (item.containsKey('prodDate')) {
            // Validate date format (YYYY-MM-DD)
            final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
            if (!dateRegex.hasMatch(item['prodDate'])) {
              throw Exception('Production date must be in YYYY-MM-DD format');
            }
          }

          if (item.containsKey('expDate')) {
            // Validate date format (YYYY-MM-DD)
            final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
            if (!dateRegex.hasMatch(item['expDate'])) {
              throw Exception('Expiry date must be in YYYY-MM-DD format');
            }
          }

          if (item.containsKey('costPrice') && item['costPrice'] is! num) {
            throw Exception('Cost price must be a number');
          }
        }
      }

      debugPrint('Sending request body: ${json.encode(body)}');

      final response = await http.put(
        Uri.parse('$baseUrl/supplierOrders/$orderId/status'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        // Try to extract error message from response
        String errorMessage =
            'Failed to update order status: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage += ' - ${errorData['message']}';
          } else if (errorData['error'] != null) {
            errorMessage += ' - ${errorData['error']}';
          }
        } catch (e) {
          // If response body is not JSON, use the raw body
          errorMessage += ' - ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error in updateOrderStatus: $e');
      throw Exception('Error updating order status: $e');
    }
  }

  // Helper method to format date for API
  static String formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Helper method to validate date string
  static bool isValidDateFormat(String date) {
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(date)) return false;

    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Method to create an item map with all possible fields
  static Map<String, dynamic> createItemUpdate({
    required int productId,
    String? status,
    double? costPrice,
    DateTime? prodDate,
    DateTime? expDate,
    String? notes,
  }) {
    final Map<String, dynamic> item = {
      'id': productId,
    };

    if (status != null) {
      item['status'] = status;
    }

    if (costPrice != null) {
      item['costPrice'] = costPrice;
    }

    if (prodDate != null) {
      item['prodDate'] = formatDateForApi(prodDate);
    }

    if (expDate != null) {
      item['expDate'] = formatDateForApi(expDate);
    }

    if (notes != null && notes.trim().isNotEmpty) {
      item['notes'] = notes.trim();
    }

    return item;
  }
}
