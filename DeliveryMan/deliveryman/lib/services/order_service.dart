import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/order.dart';

class AssignedOrdersResponse {
  final int count;
  final List<Order> assignedOrders;

  AssignedOrdersResponse({
    required this.count,
    required this.assignedOrders,
  });

  factory AssignedOrdersResponse.fromJson(Map<String, dynamic> json) {
    return AssignedOrdersResponse(
      count: json['count'] as int,
      assignedOrders: (json['assignedOrders'] as List<dynamic>)
          .map((orderJson) => Order.fromJson(orderJson))
          .toList(),
    );
  }
}

class BatchDeliveryRequest {
  final List<int> orderIds;
  final double latitude;
  final double longitude;

  BatchDeliveryRequest({
    required this.orderIds,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderIds': orderIds,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class OrderService with ChangeNotifier {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';
  static const int maxBatchSize = 5;
  
  List<Order> _assignedOrders = [];
  List<Order> _completedOrders = [];
  List<Order> _activeOrders = []; // Orders currently being delivered
  Order? _currentOrder;
  String? _token;
  bool _isLoading = false;
  String? _lastError;
  Timer? _refreshTimer;
  
  // Multi-order selection state
  bool _isSelectionMode = false;
  List<Order> _selectedOrders = [];
  DeliveryBatch? _currentBatch;

  // Getters
  List<Order> get assignedOrders => [..._assignedOrders];
  List<Order> get completedOrders => [..._completedOrders];
  List<Order> get activeOrders => [..._activeOrders];
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isSelectionMode => _isSelectionMode;
  List<Order> get selectedOrders => [..._selectedOrders];
  DeliveryBatch? get currentBatch => _currentBatch;
  int get selectedCount => _selectedOrders.length;
  bool get canStartBatch => _selectedOrders.isNotEmpty && _selectedOrders.length <= maxBatchSize;
  bool get hasActiveDeliveries => _activeOrders.isNotEmpty;

  void updateToken(String? token) {
    _token = token;
    if (_token != null) {
      _startRefreshTimer();
    } else {
      _stopRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchAssignedOrders();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Multi-order selection methods
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      clearSelection();
    }
    notifyListeners();
  }

  void toggleOrderSelection(Order order) {
    if (!order.canStart || order.isInProgress) return;
    
    final index = _assignedOrders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _assignedOrders[index] = _assignedOrders[index].copyWith(
        isSelected: !_assignedOrders[index].isSelected,
      );
      
      if (_assignedOrders[index].isSelected) {
        if (_selectedOrders.length < maxBatchSize) {
          _selectedOrders.add(_assignedOrders[index]);
        } else {
          // Max batch size reached, don't select
          _assignedOrders[index] = _assignedOrders[index].copyWith(isSelected: false);
          _lastError = 'Maximum $maxBatchSize orders can be selected for batch delivery';
        }
      } else {
        _selectedOrders.removeWhere((o) => o.id == order.id);
      }
      
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedOrders.clear();
    for (int i = 0; i < _assignedOrders.length; i++) {
      _assignedOrders[i] = _assignedOrders[i].copyWith(isSelected: false);
    }
    notifyListeners();
  }

  void selectAllAvailable() {
    clearSelection();
    final availableOrders = _assignedOrders
        .where((o) => o.canStart && !o.isInProgress)
        .take(maxBatchSize)
        .toList();
    
    for (final order in availableOrders) {
      final index = _assignedOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _assignedOrders[index] = _assignedOrders[index].copyWith(isSelected: true);
        _selectedOrders.add(_assignedOrders[index]);
      }
    }
    notifyListeners();
  }

  Future<void> fetchAssignedOrders() async {
    if (_token == null) {
      _lastError = 'No authentication token available';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      print('Fetching assigned orders from: $baseUrl/delivery/orders/assigned');
      print('Using token: ${_token?.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/delivery/orders/assigned'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final assignedResponse = AssignedOrdersResponse.fromJson(responseData);
          
          // Preserve selection state when updating orders
          final previouslySelected = _selectedOrders.map((o) => o.id).toSet();
          
          _assignedOrders = assignedResponse.assignedOrders.map((order) {
            return order.copyWith(
              isSelected: previouslySelected.contains(order.id),
            );
          }).toList();
          
          // Update selected orders list with new data
          _selectedOrders = _assignedOrders.where((o) => o.isSelected).toList();
          
          // Separate active orders (in progress) from assigned orders
          _activeOrders = _assignedOrders.where((o) => o.isInProgress).toList();
          
          print('Successfully parsed ${assignedResponse.count} assigned orders');
          print('Active orders: ${_activeOrders.length}');

          // Set current order logic
          _updateCurrentOrder();

        } catch (parseError) {
          print('Error parsing response: $parseError');
          _lastError = 'Error parsing server response: $parseError';
        }
      } else if (response.statusCode == 401) {
        _lastError = 'Authentication failed. Please login again.';
        print('Authentication failed with token: $_token');
      } else if (response.statusCode == 403) {
        _lastError = 'Access denied. You do not have permission to view orders.';
      } else if (response.statusCode == 404) {
        _lastError = 'Orders endpoint not found.';
      } else {
        _lastError = 'Server error (${response.statusCode}): ${response.body}';
        print('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('Network error fetching assigned orders: $error');
      
      if (error.toString().contains('SocketException') ||
          error.toString().contains('TimeoutException')) {
        _lastError = 'Network error. Please check your connection and try again.';
      } else {
        _lastError = 'An unexpected error occurred: ${error.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateCurrentOrder() {
    if (_activeOrders.isNotEmpty) {
      // If we have active orders, use the first one
      _currentOrder = _activeOrders.first;
      print('Set current order to active order: ${_currentOrder!.id}');
    } else if (_assignedOrders.isNotEmpty) {
      // If no active orders, try to find one that can be started
      try {
        _currentOrder = _assignedOrders.firstWhere(
          (order) => order.canStart && !order.isInProgress,
        );
        print('Set current order to startable order: ${_currentOrder!.id}');
      } catch (e) {
        // If no startable order either, just use the first one
        _currentOrder = _assignedOrders.isNotEmpty ? _assignedOrders.first : null;
        print('Set current order to first available order: ${_currentOrder?.id ?? 'None'}');
      }
    } else {
      _currentOrder = null;
      print('No assigned orders available');
    }
  }

  // Batch delivery start method
  Future<bool> startBatchDelivery(Position currentPosition) async {
    if (_token == null || _selectedOrders.isEmpty) return false;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      print('Starting batch delivery with ${_selectedOrders.length} orders');
      
      // Optimize route for selected orders
      final batch = await optimizeDeliveryRoute(_selectedOrders, currentPosition);
      _currentBatch = batch;
      
      // Start each order individually via API
      bool allStarted = true;
      for (final order in _selectedOrders) {
        final success = await _startSingleDelivery(
          order.id, 
          currentPosition.latitude, 
          currentPosition.longitude
        );
        if (!success) {
          allStarted = false;
          print('Failed to start order ${order.id}');
        }
      }

      if (allStarted) {
        print('Batch delivery started successfully!');
        // Clear selection and refresh orders
        clearSelection();
        toggleSelectionMode(); // Exit selection mode
        await fetchAssignedOrders();
        return true;
      } else {
        _lastError = 'Some orders could not be started. Please try again.';
        return false;
      }
      
    } catch (e) {
      print('Error starting batch delivery: $e');
      _lastError = 'Failed to start batch delivery: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Single order start (internal method)
  Future<bool> _startSingleDelivery(int orderId, double latitude, double longitude) async {
    try {
      print('Starting delivery for order $orderId at ($latitude, $longitude)');
      
      final response = await http.post(
        Uri.parse('$baseUrl/delivery/start-delivery'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
        body: json.encode({
          'orderId': orderId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      print('Start delivery response for order $orderId: ${response.statusCode}');
      print('Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error starting delivery for order $orderId: $e');
      return false;
    }
  }

  // Route optimization using nearest neighbor algorithm
  Future<DeliveryBatch> optimizeDeliveryRoute(List<Order> orders, Position startPosition) async {
    if (orders.isEmpty) {
      return DeliveryBatch(
        orders: [],
        optimizedRoute: [],
        totalDistance: 0,
        estimatedDuration: 0,
      );
    }

    print('Optimizing route for ${orders.length} orders');

    // Start point (delivery person current location)
    RoutePoint startPoint = RoutePoint(
      latitude: startPosition.latitude,
      longitude: startPosition.longitude,
      sequenceIndex: 0,
    );

    List<RoutePoint> optimizedRoute = [startPoint];
    List<Order> remainingOrders = [...orders];
    double totalDistance = 0;
    
    double currentLat = startPosition.latitude;
    double currentLng = startPosition.longitude;
    int sequenceIndex = 1;

    // Nearest neighbor algorithm
    while (remainingOrders.isNotEmpty) {
      Order? nearestOrder;
      double shortestDistance = double.infinity;
      
      // Find the nearest unvisited order
      for (final order in remainingOrders) {
        final distance = _calculateDistance(
          currentLat, 
          currentLng, 
          order.latitude, 
          order.longitude
        );
        
        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestOrder = order;
        }
      }
      
      if (nearestOrder != null) {
        // Add to route
        optimizedRoute.add(RoutePoint(
          latitude: nearestOrder.latitude,
          longitude: nearestOrder.longitude,
          order: nearestOrder.copyWith(
            routeIndex: sequenceIndex - 1,
            routeColor: RouteColors.getColorForIndex(sequenceIndex - 1),
          ),
          sequenceIndex: sequenceIndex,
        ));
        
        totalDistance += shortestDistance;
        currentLat = nearestOrder.latitude;
        currentLng = nearestOrder.longitude;
        remainingOrders.remove(nearestOrder);
        sequenceIndex++;
      }
    }

    // Estimate duration (assuming average speed of 30 km/h in city)
    int estimatedDuration = ((totalDistance / 30) * 60).round(); // minutes
    
    print('Route optimized: ${optimizedRoute.length - 1} stops, ${totalDistance.toStringAsFixed(2)} km, ~$estimatedDuration minutes');

    return DeliveryBatch(
      orders: optimizedRoute.where((rp) => rp.order != null).map((rp) => rp.order!).toList(),
      optimizedRoute: optimizedRoute,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
    );
  }

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Legacy methods for backward compatibility
  Future<void> fetchCompletedOrders() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/orders/completed'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body);
        _completedOrders =
            ordersJson.map((order) => Order.fromJson(order)).toList();
        notifyListeners();
      } else {
        print("Error fetching completed orders: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching completed orders: $e");
    }
  }

  Future<bool> updateOrderStatus(int orderId, OrderStatus status) async {
    if (_token == null) return false;

    try {
      print('Updating order $orderId status to ${Order.statusToString(status)}');
      
      final response = await http.put(
        Uri.parse('$baseUrl/delivery/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
        body: json.encode({
          'status': Order.statusToString(status),
        }),
      );

      print('Update status response: ${response.statusCode}');
      print('Update status body: ${response.body}');

      if (response.statusCode == 200) {
        // Refresh orders after successful status update
        await fetchAssignedOrders();
        if (status == OrderStatus.delivered) {
          await fetchCompletedOrders();
        }
        return true;
      } else {
        print('Failed to update order status: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print("Error updating order status: $e");
      return false;
    }
  }

  // Helper methods
  Order? getOrderById(int orderId) {
    try {
      return _assignedOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  bool canStartOrder(int orderId) {
    final order = getOrderById(orderId);
    return order?.canStart == true && !order!.isInProgress;
  }

  bool isOrderInProgress(int orderId) {
    final order = getOrderById(orderId);
    return order?.isInProgress == true;
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }
}