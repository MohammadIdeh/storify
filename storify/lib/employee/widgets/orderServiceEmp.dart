// lib/employee/widgets/orderServiceEmp.dart - Enhanced version
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';

class OrderService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  // Enhanced error handling
  static Future<Map<String, dynamic>> _handleResponse(
      http.Response response, String operation) async {
    print('=== API Response Debug Info ===');
    print('Operation: $operation');
    print('Status Code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Response Body: ${response.body}');
    print('Request URL: ${response.request?.url}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      // Extract more details for 403 errors
      String errorMessage = 'Access denied (403)';
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage =
            errorBody['message'] ?? errorBody['error'] ?? errorMessage;
      } catch (e) {
        // If response body is not JSON, use the raw body
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }

      print('=== 403 Error Details ===');
      print('Error Message: $errorMessage');
      print('User IP might be blocked or restricted');
      print('Check server logs for IP-based restrictions');

      throw Exception('$operation failed: $errorMessage (Status: 403)');
    } else {
      String errorMessage = 'Request failed';
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage =
            errorBody['message'] ?? errorBody['error'] ?? errorMessage;
      } catch (e) {
        errorMessage =
            response.body.isNotEmpty ? response.body : 'Unknown error';
      }

      throw Exception(
          '$operation failed: $errorMessage (Status: ${response.statusCode})');
    }
  }

  // Enhanced request wrapper with debugging
  static Future<http.Response> _makeRequest(String method, String url,
      {Map<String, dynamic>? body}) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      print('=== API Request Debug Info ===');
      print('Method: $method');
      print('URL: $url');
      print('Headers: $headers');
      if (body != null) print('Body: ${jsonEncode(body)}');

      http.Response response;

      if (method == 'GET') {
        response = await http.get(Uri.parse(url), headers: headers);
      } else if (method == 'PUT') {
        response = await http.put(
          Uri.parse(url),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        );
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      return response;
    } catch (e) {
      print('Error making request: $e');
      rethrow;
    }
  }

  // Get customer orders with enhanced error handling
  static Future<Map<String, dynamic>> getCustomerOrders() async {
    try {
      final response =
          await _makeRequest('GET', '$baseUrl/worker/customer-orders');
      return await _handleResponse(response, 'Get customer orders');
    } catch (e) {
      print('Error fetching customer orders: $e');
      rethrow;
    }
  }

  // Get supplier orders with enhanced error handling
  static Future<Map<String, dynamic>> getSupplierOrders() async {
    try {
      final response =
          await _makeRequest('GET', '$baseUrl/worker/supplier-orders');
      return await _handleResponse(response, 'Get supplier orders');
    } catch (e) {
      print('Error fetching supplier orders: $e');
      rethrow;
    }
  }

  // Get customer order details
  static Future<Map<String, dynamic>> getCustomerOrderDetails(
      int orderId) async {
    try {
      final response =
          await _makeRequest('GET', '$baseUrl/worker/customer-orders/$orderId');
      return await _handleResponse(response, 'Get customer order details');
    } catch (e) {
      print('Error fetching customer order details: $e');
      rethrow;
    }
  }

  // Update customer order status
  static Future<Map<String, dynamic>> updateCustomerOrderStatus(
      int orderId, String status, String? note) async {
    try {
      final Map<String, dynamic> body = {'status': status};
      if (note != null && note.isNotEmpty) {
        body['note'] = note;
      }

      final response = await _makeRequest(
          'PUT', '$baseUrl/worker/customer-orders/$orderId',
          body: body);
      return await _handleResponse(response, 'Update customer order status');
    } catch (e) {
      print('Error updating customer order: $e');
      rethrow;
    }
  }

  // Get supplier order details
  static Future<Map<String, dynamic>> getSupplierOrderDetails(
      int orderId) async {
    try {
      final response =
          await _makeRequest('GET', '$baseUrl/worker/supplier-orders/$orderId');
      return await _handleResponse(response, 'Get supplier order details');
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
      final Map<String, dynamic> body = {'status': status};
      if (note != null && note.isNotEmpty) {
        body['note'] = note;
      }
      if (updatedItems != null && updatedItems.isNotEmpty) {
        body['items'] = updatedItems;
      }

      final response = await _makeRequest(
          'PUT', '$baseUrl/worker/supplier-orders/$orderId',
          body: body);
      return await _handleResponse(response, 'Update supplier order status');
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
      final response = await _makeRequest(
          'GET', '$baseUrl/worker/orders-history?page=$page&limit=$limit');
      return await _handleResponse(response, 'Get order history');
    } catch (e) {
      print('Error fetching order history: $e');
      rethrow;
    }
  }

  // Network connectivity test
  static Future<Map<String, String>> getNetworkInfo() async {
    try {
      // Get public IP and basic network info
      final response = await http.get(Uri.parse('https://httpbin.org/ip'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'publicIP': data['origin'] ?? 'Unknown',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      print('Error getting network info: $e');
    }

    return {
      'publicIP': 'Unknown',
      'error': 'Could not determine IP',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
