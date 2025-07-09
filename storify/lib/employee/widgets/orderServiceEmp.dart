// lib/employee/widgets/orderServiceEmp.dart - Updated version with enhanced start preparation response
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';

// Enhanced models to match the actual API response

// Model for the complete start preparation response
class StartPreparationResponse {
  final String message;
  final Map<String, dynamic> order;
  final PreparationInfo preparationInfo;

  StartPreparationResponse({
    required this.message,
    required this.order,
    required this.preparationInfo,
  });

  factory StartPreparationResponse.fromJson(Map<String, dynamic> json) {
    return StartPreparationResponse(
      message: json['message'] ?? '',
      order: json['order'] ?? {},
      preparationInfo: PreparationInfo.fromJson(json['preparationInfo'] ?? {}),
    );
  }
}

// Model for preparation info in the start preparation response
class PreparationInfo {
  final int totalItems;
  final List<ItemWithBatchInfo> itemsWithBatchInfo;
  final List<BatchAlert> batchAlerts;
  final bool hasMultipleBatches;
  final bool hasNearExpiry;
  final bool hasInsufficientStock;
  final bool hasNoBatchTracking;
  final bool canAutoComplete;
  final Map<String, int> preparationTypes;
  final List<CurrentPreparer> currentPreparers;

  PreparationInfo({
    required this.totalItems,
    required this.itemsWithBatchInfo,
    required this.batchAlerts,
    required this.hasMultipleBatches,
    required this.hasNearExpiry,
    required this.hasInsufficientStock,
    required this.hasNoBatchTracking,
    required this.canAutoComplete,
    required this.preparationTypes,
    required this.currentPreparers,
  });

  factory PreparationInfo.fromJson(Map<String, dynamic> json) {
    return PreparationInfo(
      totalItems: json['totalItems'] ?? 0,
      itemsWithBatchInfo: (json['itemsWithBatchInfo'] as List? ?? [])
          .map((item) => ItemWithBatchInfo.fromJson(item))
          .toList(),
      batchAlerts: (json['batchAlerts'] as List? ?? [])
          .map((alert) => BatchAlert.fromJson(alert))
          .toList(),
      hasMultipleBatches: json['hasMultipleBatches'] ?? false,
      hasNearExpiry: json['hasNearExpiry'] ?? false,
      hasInsufficientStock: json['hasInsufficientStock'] ?? false,
      hasNoBatchTracking: json['hasNoBatchTracking'] ?? false,
      canAutoComplete: json['canAutoComplete'] ?? false,
      preparationTypes: Map<String, int>.from(json['preparationTypes'] ?? {}),
      currentPreparers: (json['currentPreparers'] as List? ?? [])
          .map((preparer) => CurrentPreparer.fromJson(preparer))
          .toList(),
    );
  }
}

// Model for items with batch info in the preparation response
class ItemWithBatchInfo {
  final int productId;
  final String productName;
  final int requiredQuantity;
  final int availableQuantity;
  final FifoAllocation fifoAllocation;
  final bool canFulfill;
  final List<BatchAlert> alerts;
  final String preparationType;

  ItemWithBatchInfo({
    required this.productId,
    required this.productName,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.fifoAllocation,
    required this.canFulfill,
    required this.alerts,
    required this.preparationType,
  });

  factory ItemWithBatchInfo.fromJson(Map<String, dynamic> json) {
    return ItemWithBatchInfo(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      requiredQuantity: json['requiredQuantity'] ?? 0,
      availableQuantity: json['availableQuantity'] ?? 0,
      fifoAllocation: FifoAllocation.fromJson(json['fifoAllocation'] ?? {}),
      canFulfill: json['canFulfill'] ?? false,
      alerts: (json['alerts'] as List? ?? [])
          .map((alert) => BatchAlert.fromJson(alert))
          .toList(),
      preparationType: json['preparationType'] ?? '',
    );
  }
}

// Model for FIFO allocation details
class FifoAllocation {
  final List<AllocationItem> allocation;
  final bool canFulfill;
  final int? totalAvailable;
  final int? requiredQuantity;
  final List<BatchAlert> alerts;
  final String? fifoRecommendation;
  final BatchSummary? batchSummary;

  FifoAllocation({
    required this.allocation,
    required this.canFulfill,
    this.totalAvailable,
    this.requiredQuantity,
    required this.alerts,
    this.fifoRecommendation,
    this.batchSummary,
  });

  factory FifoAllocation.fromJson(Map<String, dynamic> json) {
    return FifoAllocation(
      allocation: (json['allocation'] as List? ?? [])
          .map((item) => AllocationItem.fromJson(item))
          .toList(),
      canFulfill: json['canFulfill'] ?? false,
      totalAvailable: json['totalAvailable'],
      requiredQuantity: json['requiredQuantity'],
      alerts: (json['alerts'] as List? ?? [])
          .map((alert) => BatchAlert.fromJson(alert))
          .toList(),
      fifoRecommendation: json['fifoRecommendation'],
      batchSummary: json['batchSummary'] != null
          ? BatchSummary.fromJson(json['batchSummary'])
          : null,
    );
  }
}

// Model for allocation items
class AllocationItem {
  final int? productId;
  final int quantity;
  final String source;
  final int? batchId;
  final String? prodDate;
  final String? expDate;
  final String? receivedDate;
  final String? batchNumber;
  final int? remainingInBatch;
  final double? costPrice;
  final int? supplierId;

  AllocationItem({
    this.productId,
    required this.quantity,
    required this.source,
    this.batchId,
    this.prodDate,
    this.expDate,
    this.receivedDate,
    this.batchNumber,
    this.remainingInBatch,
    this.costPrice,
    this.supplierId,
  });

  factory AllocationItem.fromJson(Map<String, dynamic> json) {
    return AllocationItem(
      productId: json['productId'],
      quantity: json['quantity'] ?? 0,
      source: json['source'] ?? '',
      batchId: json['batchId'],
      prodDate: json['prodDate'],
      expDate: json['expDate'],
      receivedDate: json['receivedDate'],
      batchNumber: json['batchNumber'],
      remainingInBatch: json['remainingInBatch'],
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      supplierId: json['supplierId'],
    );
  }
}

// Model for batch summary
class BatchSummary {
  final int totalBatches;
  final int batchesUsed;
  final bool hasMultipleDates;
  final Map<String, dynamic>? oldestBatch;

  BatchSummary({
    required this.totalBatches,
    required this.batchesUsed,
    required this.hasMultipleDates,
    this.oldestBatch,
  });

  factory BatchSummary.fromJson(Map<String, dynamic> json) {
    return BatchSummary(
      totalBatches: json['totalBatches'] ?? 0,
      batchesUsed: json['batchesUsed'] ?? 0,
      hasMultipleDates: json['hasMultipleDates'] ?? false,
      oldestBatch: json['oldestBatch'],
    );
  }
}

// Model for current preparers
class CurrentPreparer {
  final int employeeId;
  final String employeeName;
  final String startedAt;

  CurrentPreparer({
    required this.employeeId,
    required this.employeeName,
    required this.startedAt,
  });

  factory CurrentPreparer.fromJson(Map<String, dynamic> json) {
    return CurrentPreparer(
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'] ?? '',
      startedAt: json['startedAt'] ?? '',
    );
  }
}

// Existing models (kept for compatibility)
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
      severity: json['severity'] ?? 'info',
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

  // UPDATED: Start preparation for customer order - now returns enhanced response
  static Future<StartPreparationResponse> startCustomerOrderPreparation(
      int orderId, String? notes) async {
    try {
      final Map<String, dynamic> body = {};
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await _makeRequest(
          'POST', '$baseUrl/customer-order/$orderId/start-preparation',
          body: body);

      final data =
          await _handleResponse(response, 'Start customer order preparation');
      return StartPreparationResponse.fromJson(data);
    } catch (e) {
      debugPrint('Error starting customer order preparation: $e');
      rethrow;
    }
  }

  // LEGACY: Keep the old method for backward compatibility
  static Future<Map<String, dynamic>> startCustomerOrderPreparationLegacy(
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

  // Complete preparation for customer order
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

  // Get batch information for customer order
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

  // Helper method to convert StartPreparationResponse to BatchInfoResponse
  static BatchInfoResponse convertStartPreparationToBatchInfo(
      StartPreparationResponse startResponse, int orderId) {
    final preparationInfo = startResponse.preparationInfo;

    // Convert ItemWithBatchInfo to BatchInfo
    final batchInfoList = preparationInfo.itemsWithBatchInfo.map((item) {
      // Convert FIFO allocation to batch and recommendation lists
      final batches = <Batch>[];
      final fifoRecommendations = <FifoRecommendation>[];

      for (final allocation in item.fifoAllocation.allocation) {
        if (allocation.batchId != null) {
          // Create batch from allocation
          batches.add(Batch(
            id: allocation.batchId!,
            productId: item.productId,
            batchNumber: allocation.batchNumber,
            quantity: allocation.quantity,
            originalQuantity: allocation.quantity,
            prodDate: allocation.prodDate,
            expDate: allocation.expDate,
            receivedDate: allocation.receivedDate ?? '',
            supplierId: allocation.supplierId ?? 0,
            supplierOrderId: 0, // Not available in this response
            costPrice: allocation.costPrice ?? 0.0,
            status: 'available',
            notes: null,
          ));

          // Create FIFO recommendation
          fifoRecommendations.add(FifoRecommendation(
            batchId: allocation.batchId!,
            quantity: allocation.quantity,
            prodDate: allocation.prodDate,
            expDate: allocation.expDate,
            receivedDate: allocation.receivedDate ?? '',
            batchNumber: allocation.batchNumber,
            remainingInBatch:
                allocation.remainingInBatch ?? allocation.quantity,
            costPrice: allocation.costPrice ?? 0.0,
            supplierId: allocation.supplierId ?? 0,
          ));
        }
      }

      return BatchInfo(
        productId: item.productId,
        productName: item.productName,
        requiredQuantity: item.requiredQuantity,
        availableQuantity: item.availableQuantity,
        batches: batches,
        fifoRecommendation: fifoRecommendations,
        alerts: item.alerts,
        canFulfill: item.canFulfill,
      );
    }).toList();

    return BatchInfoResponse(
      message: startResponse.message,
      orderId: orderId.toString(),
      orderStatus: 'Preparing',
      batchInfo: batchInfoList,
      hasCriticalAlerts: preparationInfo.batchAlerts
          .any((alert) => alert.severity == 'critical'),
      hasMultipleBatches: preparationInfo.hasMultipleBatches,
    );
  }

  // DEPRECATED: Old method - kept for backward compatibility
  @deprecated
  static Future<Map<String, dynamic>> updateCustomerOrderStatus(
      int orderId, String status, String? note) async {
    debugPrint(
        'WARNING: updateCustomerOrderStatus is deprecated. Use new methods instead.');

    // For backward compatibility, route to new methods
    if (status == "Preparing") {
      final response = await startCustomerOrderPreparationLegacy(orderId, note);
      return response;
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

// FIXED OrderService method - replace in orderServiceEmp.dart

// Enhanced OrderService method with comprehensive ID debugging
// Replace the updateSupplierOrderStatus method in orderServiceEmp.dart

  static Future<Map<String, dynamic>> updateSupplierOrderStatus(
      int orderId,
      String status,
      String? note,
      List<Map<String, dynamic>>? updatedItems) async {
    try {
      if (updatedItems != null) {
        for (int i = 0; i < updatedItems.length; i++) {
          final item = updatedItems[i];

          item.forEach((key, value) {});
        }
      }

      final Map<String, dynamic> body = {'status': status};

      if (note != null && note.isNotEmpty) {
        body['note'] = note;
      }

      if (updatedItems != null && updatedItems.isNotEmpty) {
        // Clean the items to only include allowed fields
        final cleanedItems = updatedItems.map((item) {
          final cleanedItem = {
            'id': item['id'],
            'receivedQuantity': item['receivedQuantity'],
          };
          return cleanedItem;
        }).toList();

        body['items'] = cleanedItems;
      }

      final response = await _makeRequest(
          'PUT', '$baseUrl/worker/supplier-orders/$orderId',
          body: body);

      final result =
          await _handleResponse(response, 'Update supplier order status');

      result.forEach((key, value) {
        if (value is Map || value is List) {
        } else {}
      });

      // Check if the response contains updated order data
      if (result.containsKey('order')) {
        final updatedOrder = result['order'];

        if (updatedOrder['items'] != null) {
          final items = updatedOrder['items'] as List;
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
          }
        }
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateSupplierOrderStatusAlt(
      int orderId,
      String status,
      String? note,
      List<Map<String, dynamic>>? updatedItems) async {
    try {
      // Try a different endpoint structure similar to customer orders
      final Map<String, dynamic> body = {'status': status};
      if (note != null && note.isNotEmpty) {
        body['notes'] = note; // Try 'notes' instead of 'note'
      }
      if (updatedItems != null && updatedItems.isNotEmpty) {
        body['receivedItems'] =
            updatedItems; // Try 'receivedItems' instead of 'items'
      }

      debugPrint('=== ALTERNATIVE API CALL ===');
      debugPrint(
          'Trying endpoint: $baseUrl/supplier-order/$orderId/update-status');
      debugPrint('Body: ${jsonEncode(body)}');

      final response = await _makeRequest('PUT',
          '$baseUrl/supplier-order/$orderId/update-status', // Different endpoint
          body: body);

      return await _handleResponse(
          response, 'Update supplier order status (alt)');
    } catch (e) {
      debugPrint('Alternative endpoint failed: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyOrderUpdate(int orderId) async {
    try {
      debugPrint('=== VERIFYING ORDER UPDATE ===');
      debugPrint('Fetching order details for ID: $orderId');

      final response =
          await _makeRequest('GET', '$baseUrl/worker/supplier-orders/$orderId');
      final result = await _handleResponse(response, 'Verify order update');

      debugPrint('=== VERIFICATION RESULT ===');
      debugPrint('Order Status: ${result['order']?['status']}');
      debugPrint('Items: ${jsonEncode(result['order']?['items'])}');

      return result;
    } catch (e) {
      debugPrint('Error verifying order update: $e');
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
