// lib/admin/services/supplier_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/supplier_models.dart';
import 'package:storify/utilis/notification_service.dart'; // Import NotificationService

class SupplierService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  // Fetch all suppliers
  static Future<List<Supplier>> getSuppliers() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/supplier/suppliers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'Suppliers retrieved successfully') {
          return (data['suppliers'] as List)
              .map((supplierJson) => Supplier.fromJson(supplierJson))
              .toList();
        } else {
          throw Exception('Failed to load suppliers: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to load suppliers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching suppliers: $e');
    }
  }

  static Future<List<SupplierProduct>> getSupplierProducts(
      int supplierId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/supplierOrders/supplier/$supplierId/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'Supplier products retrieved successfully') {
          return (data['products'] as List)
              .map((productJson) =>
                  SupplierProduct.fromJson(productJson, supplierId))
              .toList();
        } else {
          throw Exception(
              'Failed to load supplier products: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to load supplier products. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching supplier products: $e');
    }
  }

  static Future<bool> placeOrder(OrderRequest order) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        Uri.parse('$baseUrl/supplierOrders/'),
        headers: headers,
        body: json.encode(order.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['message'] == 'Order created successfully') {
          // Extract order ID from response if available, or generate a temporary one
          final String orderId = data['data']?['_id'] ??
              'ORDER-${DateTime.now().millisecondsSinceEpoch}';

          // Send notification to supplier
          await _sendOrderNotificationToSupplier(
              order.supplierId, orderId, order.items.length);

          return true;
        } else {
          throw Exception('Failed to create order: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to create order. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating order: $e');
      return false;
    }
  }

  // New method to send notification to supplier about new order
  static Future<void> _sendOrderNotificationToSupplier(
      int supplierId, String orderId, int itemCount) async {
    try {
      final title = "New Order Received";
      final message =
          "You have received a new order (#$orderId) with $itemCount item${itemCount > 1 ? 's' : ''}.";

      // Additional data to include with notification
      final additionalData = {
        'orderId': orderId,
        'type': 'new_order',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send notification to supplier
      await NotificationService().sendNotificationToSupplier(
          supplierId, title, message, additionalData);

      print('Notification sent to supplier ID: $supplierId');
    } catch (e) {
      print('Error sending notification to supplier: $e');
    }
  }

  static Future<Map<String, dynamic>?> findLowerPriceProduct(
    SupplierProduct product,
    int currentSupplierId,
  ) async {
    try {
      // Get all suppliers
      final suppliers = await getSuppliers();

      SupplierProduct? lowerPriceProduct;
      Supplier? lowerPriceSupplier;

      // Check each supplier except the current one
      for (var supplier in suppliers) {
        if (supplier.id != currentSupplierId) {
          final products = await getSupplierProducts(supplier.id);

          // Find products with the same name but lower price
          for (var otherProduct in products) {
            if (otherProduct.name.toLowerCase() == product.name.toLowerCase() &&
                otherProduct.costPrice < product.costPrice) {
              // If we found a lower price, or if this is lower than our previous find
              if (lowerPriceProduct == null ||
                  otherProduct.costPrice < lowerPriceProduct.costPrice) {
                lowerPriceProduct = otherProduct;
                lowerPriceSupplier = supplier;
              }
            }
          }
        }
      }

      if (lowerPriceProduct != null && lowerPriceSupplier != null) {
        return {
          'product': lowerPriceProduct,
          'supplier': lowerPriceSupplier,
        };
      }

      return null;
    } catch (e) {
      print('Error finding lower price product: $e');
      return null;
    }
  }
}
