// lib/employee/widgets/orderServiceEmp.dart - Updated version with new APIs
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';

// Batch models for the new API
class BatchInfo {
  final int productId;
  final String productName;
  final int requiredQuantity;
  final int availableQuantity;
  final List<Batch> batches;
  final List<FifoRecommendation> fifoRecommendation;
  final List<BatchAlert> alerts;
  final bool canFulfill;

  BatchInfo({
    required this.productId,
    required this.productName,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.batches,
    required this.fifoRecommendation,
    required this.alerts,
    required this.canFulfill,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    return BatchInfo(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      requiredQuantity: json['requiredQuantity'] ?? 0,
      availableQuantity: json['availableQuantity'] ?? 0,
      batches: (json['batches'] as List? ?? [])
          .map((batch) => Batch.fromJson(batch))
          .toList(),
      fifoRecommendation: (json['fifoRecommendation'] as List? ?? [])
          .map((rec) => FifoRecommendation.fromJson(rec))
          .toList(),
      alerts: (json['alerts'] as List? ?? [])
          .map((alert) => BatchAlert.fromJson(alert))
          .toList(),
      canFulfill: json['canFulfill'] ?? false,
    );
  }
}

class Batch {
  final int id;
  final int productId;
  final String? batchNumber;
  final int quantity;
  final int originalQuantity;
  final String? prodDate;
  final String? expDate;
  final String receivedDate;
  final int supplierId;
  final int supplierOrderId;
  final double costPrice;
  final String status;
  final String? notes;

  Batch({
    required this.id,
    required this.productId,
    this.batchNumber,
    required this.quantity,
    required this.originalQuantity,
    this.prodDate,
    this.expDate,
    required this.receivedDate,
    required this.supplierId,
    required this.supplierOrderId,
    required this.costPrice,
    required this.status,
    this.notes,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      batchNumber: json['batchNumber'],
      quantity: json['quantity'] ?? 0,
      originalQuantity: json['originalQuantity'] ?? 0,
      prodDate: json['prodDate'],
      expDate: json['expDate'],
      receivedDate: json['receivedDate'] ?? '',
      supplierId: json['supplierId'] ?? 0,
      supplierOrderId: json['supplierOrderId'] ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      notes: json['notes'],
    );
  }
}

class FifoRecommendation {
  final int batchId;
  final int quantity;
  final String? prodDate;
  final String? expDate;
  final String receivedDate;
  final String? batchNumber;
  final int remainingInBatch;
  final double costPrice;
  final int supplierId;

  FifoRecommendation({
    required this.batchId,
    required this.quantity,
    this.prodDate,
    this.expDate,
    required this.receivedDate,
    this.batchNumber,
    required this.remainingInBatch,
    required this.costPrice,
    required this.supplierId,
  });

  factory FifoRecommendation.fromJson(Map<String, dynamic> json) {
    return FifoRecommendation(
      batchId: json['batchId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      prodDate: json['prodDate'],
      expDate: json['expDate'],
      receivedDate: json['receivedDate'] ?? '',
      batchNumber: json['batchNumber'],
      remainingInBatch: json['remainingInBatch'] ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      supplierId: json['supplierId'] ?? 0,
    );
  }
}

class BatchAlert {
  final String type;
  final String message;
  final String severity;
  final List<Map<String, dynamic>>? batchDetails;
  final List<Map<String, dynamic>>? nearExpiryItems;

  BatchAlert({
    required this.type,
    required this.message,
    required this.severity,
    this.batchDetails,
    this.nearExpiryItems,
  });

  factory BatchAlert.fromJson(Map<String, dynamic> json) {
    return BatchAlert(
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? '',
      batchDetails: json['batchDetails'] != null
          ? List<Map<String, dynamic>>.from(json['batchDetails'])
          : null,
      nearExpiryItems: json['nearExpiryItems'] != null
          ? List<Map<String, dynamic>>.from(json['nearExpiryItems'])
          : null,
    );
  }
}

class BatchInfoResponse {
  final String message;
  final String orderId;
  final String orderStatus;
  final List<BatchInfo> batchInfo;
  final bool hasCriticalAlerts;
  final bool hasMultipleBatches;

  BatchInfoResponse({
    required this.message,
    required this.orderId,
    required this.orderStatus,
    required this.batchInfo,
    required this.hasCriticalAlerts,
    required this.hasMultipleBatches,
  });

  factory BatchInfoResponse.fromJson(Map<String, dynamic> json) {
    return BatchInfoResponse(
      message: json['message'] ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderStatus: json['orderStatus'] ?? '',
      batchInfo: (json['batchInfo'] as List? ?? [])
          .map((info) => BatchInfo.fromJson(info))
          .toList(),
      hasCriticalAlerts: json['hasCriticalAlerts'] ?? false,
      hasMultipleBatches: json['hasMultipleBatches'] ?? false,
    );
  }
}

class ManualBatchAllocation {
  final int productId;
  final List<BatchAllocation> batchAllocations;

  ManualBatchAllocation({
    required this.productId,
    required this.batchAllocations,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'batchAllocations': batchAllocations.map((ba) => ba.toJson()).toList(),
    };
  }
}

class BatchAllocation {
  final int batchId;
  final int quantity;

  BatchAllocation({
    required this.batchId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'quantity': quantity,
    };
  }
}

class OrderService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  // Enhanced error handling
  static Future<Map<String, dynamic>> _handleResponse(
      http.Response response, String operation) async {
    debugPrint('=== API Response Debug Info ===');
    debugPrint('Operation: $operation');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Headers: ${response.headers}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('Request URL: ${response.request?.url}');

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

      debugPrint('=== 403 Error Details ===');
      debugPrint('Error Message: $errorMessage');
      debugPrint('User IP might be blocked or restricted');
      debugPrint('Check server logs for IP-based restrictions');

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

      debugPrint('=== API Request Debug Info ===');
      debugPrint('Method: $method');
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      if (body != null) debugPrint('Body: ${jsonEncode(body)}');

      http.Response response;

      if (method == 'GET') {
        response = await http.get(Uri.parse(url), headers: headers);
      } else if (method == 'PUT') {
        response = await http.put(
          Uri.parse(url),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (method == 'POST') {
        response = await http.post(
          Uri.parse(url),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        );
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      return response;
    } catch (e) {
      debugPrint('Error making request: $e');
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
      debugPrint('Error fetching customer orders: $e');
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
      debugPrint('Error fetching supplier orders: $e');
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
      debugPrint('Error fetching customer order details: $e');
      rethrow;
    }
  }

  // NEW: Start preparation for customer order
  static Future<Map<String, dynamic>> startCustomerOrderPreparation(
      int orderId, String? notes) async {
    try {
      final Map<String, dynamic> body = {};
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await _makeRequest(
          'POST', '$baseUrl/customer-order/$orderId/start-preparation',
          body: body);
      return await _handleResponse(
          response, 'Start customer order preparation');
    } catch (e) {
      debugPrint('Error starting customer order preparation: $e');
      rethrow;
    }
  }

  // NEW: Complete preparation for customer order
  static Future<Map<String, dynamic>> completeCustomerOrderPreparation(
      int orderId,
      {String? notes,
      List<ManualBatchAllocation>? manualBatchAllocations}) async {
    try {
      final Map<String, dynamic> body = {};

      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      if (manualBatchAllocations != null && manualBatchAllocations.isNotEmpty) {
        body['manualBatchAllocations'] = manualBatchAllocations
            .map((allocation) => allocation.toJson())
            .toList();
      }

      final response = await _makeRequest(
          'POST', '$baseUrl/customer-order/$orderId/complete-preparation',
          body: body);
      return await _handleResponse(
          response, 'Complete customer order preparation');
    } catch (e) {
      debugPrint('Error completing customer order preparation: $e');
      rethrow;
    }
  }

  // NEW: Get batch information for customer order
  static Future<BatchInfoResponse> getCustomerOrderBatchInfo(
      int orderId) async {
    try {
      final response = await _makeRequest(
          'GET', '$baseUrl/customer-order/$orderId/batch-info');
      final data =
          await _handleResponse(response, 'Get customer order batch info');
      return BatchInfoResponse.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching customer order batch info: $e');
      rethrow;
    }
  }

  // DEPRECATED: Old method - kept for backward compatibility
  @deprecated
  static Future<Map<String, dynamic>> updateCustomerOrderStatus(
      int orderId, String status, String? note) async {
    debugPrint(
        'WARNING: updateCustomerOrderStatus is deprecated. Use new methods instead.');

    // For backward compatibility, route to new methods
    if (status == "Preparing") {
      return await startCustomerOrderPreparation(orderId, note);
    } else if (status == "Prepared") {
      return await completeCustomerOrderPreparation(orderId, notes: note);
    } else {
      throw Exception('Status $status is not supported by new API');
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
      debugPrint('Error fetching supplier order details: $e');
      rethrow;
    }
  }

  // Update supplier order status (unchanged)
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
      debugPrint('Error updating supplier order: $e');
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
      debugPrint('Error fetching order history: $e');
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
      debugPrint('Error getting network info: $e');
    }

    return {
      'publicIP': 'Unknown',
      'error': 'Could not determine IP',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
