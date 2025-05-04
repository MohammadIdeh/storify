// lib/customer/services/customer_order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/customer/widgets/modelCustomer.dart';

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

  // Place a new order
  static Future<Map<String, dynamic>> placeOrder(Order order) async {
    final headers = await AuthService.getAuthHeaders(role: 'Customer');
    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(order.toJson()),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      // Check for insufficient stock error
      if (data.containsKey('available') && data.containsKey('requested')) {
        throw InsufficientStockException(
          productName: data['productName'],
          available: data['available'],
          requested: data['requested'],
          message: data['message'],
        );
      }

      throw Exception(
          'Failed to place order: ${data['message'] ?? response.statusCode}');
    }
  }

  // Get order history
  static Future<List<dynamic>> getOrderHistory() async {
    final headers = await AuthService.getAuthHeaders(role: 'Customer');
    final response = await http.get(
      Uri.parse('$baseUrl/myOrders'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['orders'];
    } else {
      throw Exception('Failed to load order history: ${response.statusCode}');
    }
  }

  // In CustomerOrderService.dart, replace the isLocationSet() method with this:
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

          print(
              '📍 LOCATION CHECK - hasLat: $hasLatitude, hasLng: $hasLongitude');
          return hasLatitude && hasLongitude;
        }

        return false;
      } else {
        print('❌ Profile API error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception in isLocationSet: $e');
      return false;
    }
  }
}

// Custom exception for insufficient stock
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
