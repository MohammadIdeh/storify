import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Model class for products statistics
class ProductStats {
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int totalCategories;

  ProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.totalCategories,
  });

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      inactiveProducts: json['inactiveProducts'] ?? 0,
      totalCategories: json['totalCategories'] ?? 0,
    );
  }

  // Empty stats object for initialization
  factory ProductStats.empty() {
    return ProductStats(
      totalProducts: 0,
      activeProducts: 0,
      inactiveProducts: 0,
      totalCategories: 0,
    );
  }
}

// Class to handle API calls and manage product statistics
class ProductStatsService {
  static const String _apiUrl =
      'https://finalproject-a5ls.onrender.com/product/stats/dashboard';
  static const String _cardOrderKey = 'product_cards_order';

  // Singleton pattern
  static final ProductStatsService _instance = ProductStatsService._internal();

  factory ProductStatsService() {
    return _instance;
  }

  ProductStatsService._internal();

  // Fetch product statistics from API
  Future<ProductStats> fetchProductStats() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ProductStats.fromJson(jsonData['stats']);
      } else {
        throw Exception(
            'Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard stats: $e');
    }
  }

  // Save card order to SharedPreferences
  Future<void> saveCardOrder(List<int> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardOrderKey, json.encode(order));
  }

  // Get card order from SharedPreferences
  Future<List<int>> getCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderString = prefs.getString(_cardOrderKey);

    if (orderString == null) {
      // Default order: 0, 1, 2, 3
      return [0, 1, 2, 3];
    }

    try {
      final List<dynamic> decodedOrder = json.decode(orderString);
      return decodedOrder.map((item) => item as int).toList();
    } catch (e) {
      // If there's an error parsing, return default order
      return [0, 1, 2, 3];
    }
  }
}
