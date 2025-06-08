// lib/admin/widgets/OrderSupplierWidgets/low_stock_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/low_stock_models.dart';

class LowStockService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';
  static const String _lastCheckKey = 'low_stock_last_check';
  static const String _hasShownNotificationKey = 'low_stock_notification_shown';

  // Check if we should show notification (once per session)
  static Future<bool> shouldShowNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_lastCheckKey);
      final hasShownToday = prefs.getBool(_hasShownNotificationKey) ?? false;

      final today =
          DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format

      // If we haven't checked today or haven't shown notification today, allow showing
      if (lastCheck != today || !hasShownToday) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking notification status: $e');
      return true; // Default to showing if there's an error
    }
  }

  // Mark that we've shown the notification today
  static Future<void> markNotificationShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];

      await prefs.setString(_lastCheckKey, today);
      await prefs.setBool(_hasShownNotificationKey, true);
    } catch (e) {
      print('Error marking notification as shown: $e');
    }
  }

  // Reset notification status (call this when user navigates away from orders screen)
  static Future<void> resetNotificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasShownNotificationKey, false);
    } catch (e) {
      print('Error resetting notification status: $e');
    }
  }

  // Get low stock items
  static Future<LowStockResponse?> getLowStockItems() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/low-stock/low-stock-items'),
        headers: headers,
      );

      print('Low stock API response status: ${response.statusCode}');
      print('Low stock API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LowStockResponse.fromJson(data);
      } else {
        print('Failed to get low stock items. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting low stock items: $e');
      return null;
    }
  }

  // Get suppliers for a specific product
  static Future<ProductSuppliersResponse?> getProductSuppliers(
      int productId) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/supplierOrders/product/$productId/suppliers'),
        headers: headers,
      );

      print('Product suppliers API response status: ${response.statusCode}');
      print('Product suppliers API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parsedResponse = ProductSuppliersResponse.fromJson(data);

        // Debug: Print supplier information
        print(
            'Found ${parsedResponse.suppliers.length} suppliers for product $productId');
        for (var supplier in parsedResponse.suppliers) {
          print(
              'Supplier: ${supplier.id} - ${supplier.name} - ${supplier.email}');
        }

        return parsedResponse;
      } else {
        print(
            'Failed to get product suppliers. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting product suppliers: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Generate orders for selected products with advanced options
  static Future<GenerateOrdersResponse?> generateOrders({
    List<int>? selectedProductIds,
    bool selectAll = false,
    Map<int, int>? customQuantities, // Product ID -> Custom Quantity
    int? customSupplierId, // Single supplier for ALL items
    Map<int, int>? customSuppliers, // Product ID -> Custom Supplier ID
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Convert Map<int, int> to Map<String, int> for JSON serialization
      Map<String, int>? jsonCustomQuantities;
      if (customQuantities != null && customQuantities.isNotEmpty) {
        jsonCustomQuantities = {};
        customQuantities.forEach((productId, quantity) {
          jsonCustomQuantities![productId.toString()] = quantity;
        });
      }

      Map<String, int>? jsonCustomSuppliers;
      if (customSuppliers != null && customSuppliers.isNotEmpty) {
        jsonCustomSuppliers = {};
        customSuppliers.forEach((productId, supplierId) {
          jsonCustomSuppliers![productId.toString()] = supplierId;
        });
      }

      final request = GenerateOrdersRequest(
        selectedProductIds: selectedProductIds,
        selectAll: selectAll,
        customQuantities: jsonCustomQuantities,
        customSupplierId: customSupplierId,
        customSuppliers: jsonCustomSuppliers,
      );

      print('Generate orders request: ${request.toString()}');
      print('Generate orders JSON: ${json.encode(request.toJson())}');

      final response = await http.post(
        Uri.parse('$baseUrl/low-stock/generate-orders'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      print('Generate orders API response status: ${response.statusCode}');
      print('Generate orders API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return GenerateOrdersResponse.fromJson(data);
      } else {
        print('Failed to generate orders. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error generating orders: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Check if there are critical low stock items
  static bool hasCriticalItems(List<LowStockItem> items) {
    return items.any((item) => item.alertLevel.toUpperCase() == 'CRITICAL');
  }

  // Get count of low stock items by alert level
  static Map<String, int> getAlertLevelCounts(List<LowStockItem> items) {
    final counts = <String, int>{
      'CRITICAL': 0,
      'WARNING': 0,
      'LOW': 0,
    };

    for (var item in items) {
      final level = item.alertLevel.toUpperCase();
      counts[level] = (counts[level] ?? 0) + 1;
    }

    return counts;
  }

  // Get formatted notification message
  static String getNotificationMessage(List<LowStockItem> items) {
    final counts = getAlertLevelCounts(items);
    final criticalCount = counts['CRITICAL'] ?? 0;
    final totalCount = items.length;

    if (criticalCount > 0) {
      return '$criticalCount critical items need immediate attention ($totalCount total low stock items)';
    } else {
      return '$totalCount items are running low on stock';
    }
  }

  // Update product's selected supplier
  static Future<void> updateProductSupplier(
      LowStockItem item, SupplierInfo newSupplier) async {
    // This would update the supplier for the product in the backend if needed
    // For now, we'll just update it locally in the UI
    print(
        'Updated supplier for product ${item.product.name} to ${newSupplier.name}');
  }
}
