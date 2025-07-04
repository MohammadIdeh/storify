// lib/admin/services/delivery_service.dart
import 'dart:convert';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/delivery_models.dart';

class DeliveryService {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';

  /// Fetch all unassigned orders (previously prepared orders)
  static Future<List<PreparedOrder>> getPreparedOrders() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/admin/orders/unassigned'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('unassignedOrders')) {
          final List<dynamic> ordersJson = data['unassignedOrders'];
          return ordersJson
              .map((orderJson) => PreparedOrder.fromJson(orderJson))
              .toList();
        } else {
          throw Exception(
              'Failed to load unassigned orders: Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to load unassigned orders. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching unassigned orders: $e');
    }
  }

  /// Fetch all delivery employees
  static Future<List<DeliveryEmployee>> getDeliveryEmployees() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/admin/delivery-employees'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('deliveryEmployees')) {
          final List<dynamic> employeesJson = data['deliveryEmployees'];
          return employeesJson
              .map((employeeJson) => DeliveryEmployee.fromJson(employeeJson))
              .toList();
        } else {
          throw Exception(
              'Failed to load delivery employees: Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to load delivery employees. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching delivery employees: $e');
    }
  }

  /// Assign orders to delivery employee with queue system
  static Future<AssignOrdersResponse?> assignOrders(
      AssignOrdersRequest request) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        Uri.parse('$baseUrl/delivery/admin/assign-orders'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return AssignOrdersResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to assign orders. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      return null;
    }
  }
}

/// Queue manager for handling multiple order assignments
class OrderAssignmentQueue {
  static final OrderAssignmentQueue _instance =
      OrderAssignmentQueue._internal();
  factory OrderAssignmentQueue() => _instance;
  OrderAssignmentQueue._internal();

  final Queue<AssignOrdersRequest> _requestQueue = Queue<AssignOrdersRequest>();
  bool _isProcessing = false;
  final List<AssignOrdersResponse> _results = [];
  final List<String> _errors = [];

  /// Add requests to the queue
  void addRequest(AssignOrdersRequest request) {
    _requestQueue.add(request);
  }

  /// Process all requests in the queue sequentially
  Future<OrderAssignmentResult> processQueue() async {
    if (_isProcessing) {
      throw Exception('Queue is already being processed');
    }

    _isProcessing = true;
    _results.clear();
    _errors.clear();

    try {
      while (_requestQueue.isNotEmpty) {
        final request = _requestQueue.removeFirst();

        try {
          final result = await DeliveryService.assignOrders(request);
          if (result != null) {
            _results.add(result);
          } else {
            _errors.add(
                'Failed to assign orders for delivery employee ${request.deliveryEmployeeId}');
          }
        } catch (e) {
          _errors.add(
              'Error assigning orders for delivery employee ${request.deliveryEmployeeId}: $e');
        }

        // Add a small delay between requests to avoid overwhelming the server
        if (_requestQueue.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      return OrderAssignmentResult(
        successfulAssignments: _results,
        errors: _errors,
        totalProcessed: _results.length + _errors.length,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Clear the queue
  void clearQueue() {
    _requestQueue.clear();
    _results.clear();
    _errors.clear();
  }

  /// Check if queue is empty
  bool get isEmpty => _requestQueue.isEmpty;

  /// Get queue length
  int get length => _requestQueue.length;

  /// Check if processing
  bool get isProcessing => _isProcessing;
}

class OrderAssignmentResult {
  final List<AssignOrdersResponse> successfulAssignments;
  final List<String> errors;
  final int totalProcessed;

  OrderAssignmentResult({
    required this.successfulAssignments,
    required this.errors,
    required this.totalProcessed,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasSuccessfulAssignments => successfulAssignments.isNotEmpty;

  int get successCount {
    int totalOrdersAssigned = 0;
    for (var assignment in successfulAssignments) {
      totalOrdersAssigned += assignment.assignedOrders.length;
    }
    return totalOrdersAssigned;
  }

  int get errorCount => errors.length;
}
