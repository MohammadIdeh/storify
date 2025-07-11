// lib/admin/widgets/OrderSupplierWidgets/low_stock_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    } catch (e) {}
  }

  // Reset notification status (call this when user navigates away from orders screen)
  static Future<void> resetNotificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasShownNotificationKey, false);
    } catch (e) {}
  }

  // Get low stock items - Updated for new API structure
  static Future<LowStockResponse?> getLowStockItems() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/low-stock/low-stock-items'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LowStockResponse.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get suppliers for a specific product - Updated to use new supplier structure
  static Future<List<LowStockSupplier>?> getProductSuppliers(
      int productId, List<LowStockItem> lowStockItems) async {
    try {
      // First try to find suppliers from low stock items (since they're included now)
      final item = lowStockItems.firstWhere(
        (item) => item.product.productId == productId,
        orElse: () => throw Exception('Product not found in low stock items'),
      );

      if (item.suppliers.isNotEmpty) {
        return item.suppliers;
      }

      // Fallback to original API call if needed
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/supplierOrders/product/$productId/suppliers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parsedResponse = ProductSuppliersResponse.fromJson(data);

        // Convert to LowStockSupplier format
        final lowStockSuppliers = parsedResponse.suppliers
            .map((supplier) => LowStockSupplier(
                  supplierId: supplier.id,
                  supplierName: supplier.name,
                  supplierEmail: supplier.email,
                  supplierPhone: '', // Not available in old format
                  priceSupplier: 0.0, // Not available in old format
                  relationshipStatus: 'Active', // Default value
                ))
            .toList();

        return lowStockSuppliers;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Generate orders for selected products with advanced options - Updated for new structure
  static Future<GenerateOrdersResponse?> generateOrders({
    List<int>? selectedProductIds,
    bool selectAll = false,
    Map<int, int>? customQuantities,
    int? customSupplierId,
    Map<int, int>? customSuppliers,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // DEBUG: Print the original custom quantities
      debugPrint(
          '🐛 ADMIN DEBUG: Original customQuantities: $customQuantities');
      debugPrint('🐛 ADMIN DEBUG: selectedProductIds: $selectedProductIds');

      // Convert Map<int, int> to Map<String, int> for JSON serialization
      Map<String, int>? jsonCustomQuantities;
      if (customQuantities != null && customQuantities.isNotEmpty) {
        jsonCustomQuantities = {};
        customQuantities.forEach((productId, quantity) {
          jsonCustomQuantities![productId.toString()] = quantity;
          debugPrint(
              '🐛 ADMIN DEBUG: Mapping productId $productId -> quantity $quantity');
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

      // DEBUG: Print the final request body
      final requestBody = json.encode(request.toJson());
      debugPrint('🐛 ADMIN DEBUG: Final request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/low-stock/generate-orders'),
        headers: headers,
        body: requestBody,
      );

      debugPrint('🐛 ADMIN DEBUG: Response status: ${response.statusCode}');
      debugPrint('🐛 ADMIN DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return GenerateOrdersResponse.fromJson(data);
      } else {
        debugPrint(
            '🐛 ADMIN DEBUG: Request failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('🐛 ADMIN DEBUG: Exception in generateOrders: $e');
      return null;
    }
  }

  // Check if there are critical low stock items - Updated for new alert levels
  static bool hasCriticalItems(List<LowStockItem> items) {
    return items.any((item) =>
        item.alertLevel.toUpperCase() == 'CRITICAL' ||
        item.alertLevel.toUpperCase() == 'HIGH');
  }

  // Get count of low stock items by alert level - Updated for new alert levels
  static Map<String, int> getAlertLevelCounts(List<LowStockItem> items) {
    final counts = <String, int>{
      'CRITICAL': 0,
      'HIGH': 0,
      'MEDIUM': 0,
      'LOW': 0,
    };

    for (var item in items) {
      final level = item.alertLevel.toUpperCase();
      counts[level] = (counts[level] ?? 0) + 1;
    }

    return counts;
  }

  // Get formatted notification message - Updated for new structure
  static String getNotificationMessage(List<LowStockItem> items) {
    final counts = getAlertLevelCounts(items);
    final criticalCount = (counts['CRITICAL'] ?? 0) + (counts['HIGH'] ?? 0);
    final totalCount = items.length;

    if (criticalCount > 0) {
      return '$criticalCount critical/high priority items need immediate attention ($totalCount total low stock items)';
    } else {
      return '$totalCount items are running low on stock';
    }
  }

  // Get formatted summary message for display
  static String getSummaryMessage(LowStockResponse response) {
    final summary = response.summary;
    if (summary.itemsFilteredOut > 0) {
      return 'Showing ${summary.itemsWithActiveSuppliers} items with active suppliers (${summary.itemsFilteredOut} items filtered out due to no active suppliers)';
    } else {
      return 'Showing ${summary.itemsWithActiveSuppliers} items with active suppliers';
    }
  }

  // Get unique suppliers from all items
  static List<LowStockSupplier> getAllUniqueSuppliers(
      List<LowStockItem> items) {
    final Map<int, LowStockSupplier> uniqueSuppliers = {};

    for (var item in items) {
      for (var supplier in item.suppliers) {
        uniqueSuppliers[supplier.supplierId] = supplier;
      }
    }

    return uniqueSuppliers.values.toList();
  }

  // Update product's selected supplier
  static Future<void> updateProductSupplier(
      LowStockItem item, LowStockSupplier newSupplier) async {
    // This would update the supplier for the product in the backend if needed
    // For now, we'll just update it locally in the UI
  }
}
