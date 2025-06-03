import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/order.dart';

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class RouteInfo {
  final Order order;
  final List<LatLng> routePoints;
  final Color routeColor;
  final double distance; // in kilometers
  final int estimatedTime; // in minutes
  final String? polylineEncoded; // Google's encoded polyline

  RouteInfo({
    required this.order,
    required this.routePoints,
    required this.routeColor,
    required this.distance,
    required this.estimatedTime,
    this.polylineEncoded,
  });
}

class GoogleDirectionsResponse {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final String encodedPolyline;

  GoogleDirectionsResponse({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.encodedPolyline,
  });
}

class BatchDeliveryResult {
  final bool success;
  final List<int> successfulOrders;
  final List<int> failedOrders;
  final String? errorMessage;
  final List<RouteInfo> routes;

  BatchDeliveryResult({
    required this.success,
    required this.successfulOrders,
    required this.failedOrders,
    this.errorMessage,
    required this.routes,
  });
}

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

class OrderService with ChangeNotifier {
  static const String baseUrl = 'https://finalproject-a5ls.onrender.com';
  static const String googleMapsApiKey =
      'AIzaSyCJMZfn5L4HMpbF7oKfqJjbuB9DysEbXdI';
  static const int maxBatchSize = 5;

  List<Order> _assignedOrders = [];
  List<Order> _completedOrders = [];
  List<Order> _activeOrders = [];
  Order? _currentOrder;
  String? _token;
  bool _isLoading = false;
  String? _lastError;
  Timer? _refreshTimer;

  // Multi-order selection state
  bool _isSelectionMode = false;
  List<Order> _selectedOrders = [];

  // Route management
  List<RouteInfo> _activeRoutes = [];
  bool _isBatchDeliveryActive = false;

  // Route colors for different orders
  static const List<Color> routeColors = [
    Color(0xFF6941C6), // Primary purple
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF2196F3), // Blue
    Color(0xFFE91E63), // Pink
  ];

  // Getters
  List<Order> get assignedOrders => [..._assignedOrders];
  List<Order> get completedOrders => [..._completedOrders];
  List<Order> get activeOrders => [..._activeOrders];
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isSelectionMode => _isSelectionMode;
  List<Order> get selectedOrders => [..._selectedOrders];
  int get selectedCount => _selectedOrders.length;
  bool get canStartBatch =>
      _selectedOrders.isNotEmpty && _selectedOrders.length <= maxBatchSize;
  bool get hasActiveDeliveries => _activeOrders.isNotEmpty;
  List<RouteInfo> get activeRoutes => [..._activeRoutes];
  bool get isBatchDeliveryActive => _isBatchDeliveryActive;

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
          _assignedOrders[index] =
              _assignedOrders[index].copyWith(isSelected: false);
          _lastError =
              'Maximum $maxBatchSize orders can be selected for batch delivery';
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
        _assignedOrders[index] =
            _assignedOrders[index].copyWith(isSelected: true);
        _selectedOrders.add(_assignedOrders[index]);
      }
    }
    notifyListeners();
  }

  // Public method to get directions for single routes (used by Map)
  Future<GoogleDirectionsResponse?> getDirectionsFromGoogle(
    LatLng origin,
    LatLng destination,
  ) async {
    return await _getDirectionsFromGoogle(origin, destination);
  }

  Future<GoogleDirectionsResponse?> _getDirectionsFromGoogle(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$googleMapsApiKey'
          '&mode=driving'
          '&traffic_model=best_guess'
          '&departure_time=now';

      print('🗺️ Fetching directions from Google Maps API...');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Google Directions API timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Extract polyline points
          final polylinePoints =
              _decodePolyline(route['overview_polyline']['points']);

          // Extract distance and duration
          final distanceKm = leg['distance']['value'] / 1000.0;
          final durationMinutes = (leg['duration_in_traffic']?['value'] ??
                  leg['duration']['value']) ~/
              60;

          print(
              '✅ Google Directions: ${distanceKm.toStringAsFixed(1)}km, ${durationMinutes}min');

          return GoogleDirectionsResponse(
            points: polylinePoints,
            distanceKm: distanceKm,
            durationMinutes: durationMinutes,
            encodedPolyline: route['overview_polyline']['points'],
          );
        } else {
          print('❌ Google Directions API error: ${data['status']}');
          return null;
        }
      } else {
        print('❌ Google Directions API HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error calling Google Directions API: $e');
      return null;
    }
  }

  // Decode Google's polyline encoding
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
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

      final response = await http.get(
        Uri.parse('$baseUrl/delivery/orders/assigned'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final assignedResponse =
              AssignedOrdersResponse.fromJson(responseData);

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

          print(
              'Successfully parsed ${assignedResponse.count} assigned orders');
          print('Active orders: ${_activeOrders.length}');

          // Set current order logic
          _updateCurrentOrder();
        } catch (parseError) {
          print('Error parsing response: $parseError');
          _lastError = 'Error parsing server response: $parseError';
        }
      } else if (response.statusCode == 401) {
        _lastError = 'Authentication failed. Please login again.';
      } else if (response.statusCode == 403) {
        _lastError =
            'Access denied. You do not have permission to view orders.';
      } else {
        _lastError = 'Server error (${response.statusCode}): ${response.body}';
      }
    } catch (error) {
      print('Network error fetching assigned orders: $error');

      if (error.toString().contains('SocketException') ||
          error.toString().contains('TimeoutException')) {
        _lastError =
            'Network error. Please check your connection and try again.';
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
      _currentOrder = _activeOrders.first;
      _isBatchDeliveryActive = _activeOrders.length > 1;
      print('Set current order to active order: ${_currentOrder!.id}');
    } else if (_assignedOrders.isNotEmpty) {
      try {
        _currentOrder = _assignedOrders.firstWhere(
          (order) => order.canStart && !order.isInProgress,
        );
        print('Set current order to startable order: ${_currentOrder!.id}');
      } catch (e) {
        _currentOrder =
            _assignedOrders.isNotEmpty ? _assignedOrders.first : null;
        print(
            'Set current order to first available order: ${_currentOrder?.id ?? 'None'}');
      }
    } else {
      _currentOrder = null;
      _isBatchDeliveryActive = false;
      print('No assigned orders available');
    }
  }

  // Batch delivery start method with Google Directions
  Future<BatchDeliveryResult> startBatchDelivery(
      Position currentPosition) async {
    if (_token == null || _selectedOrders.isEmpty) {
      return BatchDeliveryResult(
        success: false,
        successfulOrders: [],
        failedOrders: _selectedOrders.map((o) => o.id).toList(),
        errorMessage: 'No authentication token or no orders selected',
        routes: [],
      );
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      print('Starting batch delivery with ${_selectedOrders.length} orders');

      List<int> successfulOrders = [];
      List<int> failedOrders = [];
      List<String> errors = [];

      // Start each order individually via API
      for (final order in _selectedOrders) {
        final success = await _startSingleDelivery(
            order.id, currentPosition.latitude, currentPosition.longitude);
        if (success) {
          successfulOrders.add(order.id);
        } else {
          failedOrders.add(order.id);
          errors.add('Failed to start order ${order.id}');
        }
      }

      // Generate optimized routes with Google Directions for successful orders
      List<RouteInfo> routes = [];
      if (successfulOrders.isNotEmpty) {
        routes = await _generateOptimizedRoutesWithDirections(
          successfulOrders,
          currentPosition.latitude,
          currentPosition.longitude,
        );
      }

      final result = BatchDeliveryResult(
        success: successfulOrders.isNotEmpty,
        successfulOrders: successfulOrders,
        failedOrders: failedOrders,
        errorMessage: errors.isNotEmpty ? errors.join('; ') : null,
        routes: routes,
      );

      if (result.success) {
        _activeRoutes = routes;
        _isBatchDeliveryActive = routes.length > 1;

        // Clear selection and refresh orders
        clearSelection();
        toggleSelectionMode(); // Exit selection mode
        await fetchAssignedOrders();
      }

      return result;
    } catch (e) {
      print('Error starting batch delivery: $e');
      return BatchDeliveryResult(
        success: false,
        successfulOrders: [],
        failedOrders: _selectedOrders.map((o) => o.id).toList(),
        errorMessage: 'Failed to start batch delivery: ${e.toString()}',
        routes: [],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate optimized routes using Google Directions API
  Future<List<RouteInfo>> _generateOptimizedRoutesWithDirections(
    List<int> orderIds,
    double startLatitude,
    double startLongitude,
  ) async {
    List<RouteInfo> routes = [];

    try {
      // Get orders for the given IDs
      List<Order> ordersToRoute = _assignedOrders
          .where((order) => orderIds.contains(order.id))
          .toList();

      if (ordersToRoute.isEmpty) return routes;

      // Optimize route order using nearest neighbor algorithm
      List<Order> optimizedOrders = _optimizeDeliveryRoute(
        ordersToRoute,
        startLatitude,
        startLongitude,
      );

      // Create routes for each order with Google Directions
      LatLng currentLocation = LatLng(startLatitude, startLongitude);

      for (int i = 0; i < optimizedOrders.length; i++) {
        final order = optimizedOrders[i];
        final orderLocation = LatLng(order.latitude, order.longitude);

        // Get real route from Google Directions API
        final directionsResponse = await _getDirectionsFromGoogle(
          currentLocation,
          orderLocation,
        );

        List<LatLng> routePoints;
        double distance;
        int estimatedTime;

        if (directionsResponse != null) {
          // Use Google Directions data
          routePoints = directionsResponse.points;
          distance = directionsResponse.distanceKm;
          estimatedTime = directionsResponse.durationMinutes;
        } else {
          // Fallback to straight line
          print('⚠️ Using fallback route for order ${order.id}');
          routePoints = [currentLocation, orderLocation];
          distance = _calculateDistance(currentLocation.latitude,
              currentLocation.longitude, order.latitude, order.longitude);
          estimatedTime =
              (distance * 2).round(); // Rough estimate: 2 min per km
        }

        routes.add(RouteInfo(
          order: order,
          routePoints: routePoints,
          routeColor: routeColors[i % routeColors.length],
          distance: distance,
          estimatedTime: estimatedTime,
          polylineEncoded: directionsResponse?.encodedPolyline,
        ));

        currentLocation = orderLocation;
      }
    } catch (e) {
      print('Error generating optimized routes: $e');
    }

    return routes;
  }

  // Single order start (internal method)
  Future<bool> _startSingleDelivery(
      int orderId, double latitude, double longitude) async {
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

      print(
          'Start delivery response for order $orderId: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error starting delivery for order $orderId: $e');
      return false;
    }
  }

  // Complete delivery with signature and payment details
  Future<bool> completeDelivery(Map<String, dynamic> deliveryData) async {
    if (_token == null) return false;

    try {
      print('🏁 Completing delivery with data: ${deliveryData.keys}');

      final response = await http.post(
        Uri.parse('$baseUrl/delivery/complete-delivery'),
        headers: {
          'Content-Type': 'application/json',
          'token': _token!,
        },
        body: json.encode(deliveryData),
      );

      print('Complete delivery response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final orderId = int.parse(deliveryData['orderId']);

        // Remove completed order from active routes
        _activeRoutes.removeWhere((route) => route.order.id == orderId);
        if (_activeRoutes.length <= 1) {
          _isBatchDeliveryActive = false;
        }

        // Refresh orders
        await fetchAssignedOrders();
        await fetchCompletedOrders();

        print('✅ Delivery completed successfully');
        return true;
      } else {
        print(
            '❌ Failed to complete delivery: ${response.statusCode} - ${response.body}');
        _lastError = 'Failed to complete delivery: ${response.body}';
        return false;
      }
    } catch (e) {
      print('❌ Error completing delivery: $e');
      _lastError = 'Error completing delivery: ${e.toString()}';
      return false;
    }
  }

  // Route optimization using nearest neighbor algorithm (shortest path)
  List<Order> _optimizeDeliveryRoute(
    List<Order> orders,
    double startLatitude,
    double startLongitude,
  ) {
    if (orders.length <= 1) return orders;

    List<Order> optimizedRoute = [];
    List<Order> remainingOrders = List.from(orders);

    double currentLat = startLatitude;
    double currentLng = startLongitude;

    // Nearest neighbor algorithm for shortest path
    while (remainingOrders.isNotEmpty) {
      Order? nearestOrder;
      double shortestDistance = double.infinity;

      for (final order in remainingOrders) {
        final distance = _calculateDistance(
          currentLat,
          currentLng,
          order.latitude,
          order.longitude,
        );

        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestOrder = order;
        }
      }

      if (nearestOrder != null) {
        optimizedRoute.add(nearestOrder);
        remainingOrders.remove(nearestOrder);
        currentLat = nearestOrder.latitude;
        currentLng = nearestOrder.longitude;
      }
    }

    print('Optimized route order: ${optimizedRoute.map((o) => o.id).toList()}');
    return optimizedRoute;
  }

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

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
      print(
          'Updating order $orderId status to ${Order.statusToString(status)}');

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

      if (response.statusCode == 200) {
        // Remove completed order from active routes
        if (status == OrderStatus.delivered) {
          _activeRoutes.removeWhere((route) => route.order.id == orderId);
          if (_activeRoutes.length <= 1) {
            _isBatchDeliveryActive = false;
          }
        }

        // Refresh orders after successful status update
        await fetchAssignedOrders();
        if (status == OrderStatus.delivered) {
          await fetchCompletedOrders();
        }
        return true;
      } else {
        print(
            'Failed to update order status: ${response.statusCode} - ${response.body}');
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

  void clearActiveRoutes() {
    _activeRoutes.clear();
    _isBatchDeliveryActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }
}
