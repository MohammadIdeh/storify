import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http_parser/http_parser.dart';
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
      // Ensure we have valid coordinates
      if (origin.latitude.abs() > 90 ||
          origin.longitude.abs() > 180 ||
          destination.latitude.abs() > 90 ||
          destination.longitude.abs() > 180) {
        print('❌ Invalid coordinates provided');
        return null;
      }

      // Build the URL with all necessary parameters
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$googleMapsApiKey'
          '&mode=driving'
          '&alternatives=false'
          '&traffic_model=best_guess'
          '&departure_time=now'
          '&units=metric';

      print('🗺️ Requesting Google Directions...');
      print(
          '📍 From: ${origin.latitude.toStringAsFixed(6)}, ${origin.longitude.toStringAsFixed(6)}');
      print(
          '📍 To: ${destination.latitude.toStringAsFixed(6)}, ${destination.longitude.toStringAsFixed(6)}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DeliveryApp/1.0',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'Google Directions API timeout after 15 seconds');
        },
      );

      print('📥 Google Directions response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('📊 Google Directions API status: ${data['status']}');

        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Validate route data
          if (route['overview_polyline'] == null ||
              route['overview_polyline']['points'] == null) {
            print('❌ No polyline data in response');
            return null;
          }

          // Extract polyline points
          final encodedPolyline =
              route['overview_polyline']['points'] as String;
          final polylinePoints = _decodePolyline(encodedPolyline);

          if (polylinePoints.isEmpty) {
            print('❌ Failed to decode polyline');
            return null;
          }

          // Extract distance and duration
          final distanceKm = (leg['distance']['value'] as int) / 1000.0;

          // Prefer duration_in_traffic if available, otherwise use duration
          int durationSeconds;
          if (leg['duration_in_traffic'] != null) {
            durationSeconds = leg['duration_in_traffic']['value'] as int;
          } else {
            durationSeconds = leg['duration']['value'] as int;
          }
          final durationMinutes = (durationSeconds / 60).round();

          print('✅ Google Directions success:');
          print('   📏 Distance: ${distanceKm.toStringAsFixed(2)}km');
          print('   ⏱️ Duration: ${durationMinutes}min');
          print('   🛣️ Route points: ${polylinePoints.length}');

          return GoogleDirectionsResponse(
            points: polylinePoints,
            distanceKm: distanceKm,
            durationMinutes: durationMinutes,
            encodedPolyline: encodedPolyline,
          );
        } else {
          String errorMsg = 'Unknown error';
          if (data['status'] != null) {
            switch (data['status']) {
              case 'NOT_FOUND':
                errorMsg =
                    'Route not found - one of the locations may be invalid';
                break;
              case 'ZERO_RESULTS':
                errorMsg = 'No route found between these locations';
                break;
              case 'MAX_WAYPOINTS_EXCEEDED':
                errorMsg = 'Too many waypoints in request';
                break;
              case 'INVALID_REQUEST':
                errorMsg = 'Invalid request - check coordinates';
                break;
              case 'OVER_DAILY_LIMIT':
              case 'OVER_QUERY_LIMIT':
                errorMsg = 'Google Maps API quota exceeded';
                break;
              case 'REQUEST_DENIED':
                errorMsg = 'API key invalid or request denied';
                break;
              default:
                errorMsg = 'API returned status: ${data['status']}';
            }
          }

          print('❌ Google Directions API error: $errorMsg');

          if (data['error_message'] != null) {
            print('❌ Additional error info: ${data['error_message']}');
          }

          return null;
        }
      } else if (response.statusCode == 403) {
        print(
            '❌ Google Directions API: Forbidden (403) - Check API key and billing');
        return null;
      } else if (response.statusCode == 429) {
        print('❌ Google Directions API: Rate limited (429)');
        return null;
      } else {
        print('❌ Google Directions API HTTP error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      if (e is TimeoutException) {
        print('❌ Google Directions API timeout: ${e.message}');
      } else {
        print('❌ Error calling Google Directions API: $e');
      }
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    try {
      if (encoded.isEmpty) {
        print('❌ Empty polyline string');
        return [];
      }

      List<LatLng> points = [];
      int index = 0;
      int len = encoded.length;
      int lat = 0;
      int lng = 0;

      while (index < len) {
        int b;
        int shift = 0;
        int result = 0;

        // Decode latitude
        do {
          if (index >= len) break;
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;

        // Decode longitude
        do {
          if (index >= len) break;
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        final latLng = LatLng(lat / 1E5, lng / 1E5);

        // Validate decoded coordinates
        if (latLng.latitude.abs() <= 90 && latLng.longitude.abs() <= 180) {
          points.add(latLng);
        }
      }

      print('🔄 Decoded ${points.length} points from polyline');
      return points;
    } catch (e) {
      print('❌ Error decoding polyline: $e');
      return [];
    }
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

      if (ordersToRoute.isEmpty) {
        print('❌ No orders found for route generation');
        return routes;
      }

      print(
          '🗺️ Generating optimized routes for ${ordersToRoute.length} orders');

      // Optimize route order using nearest neighbor algorithm
      List<Order> optimizedOrders = _optimizeDeliveryRoute(
        ordersToRoute,
        startLatitude,
        startLongitude,
      );

      // Create routes for each order with Google Directions
      LatLng currentLocation = LatLng(startLatitude, startLongitude);
      int successfulRoutes = 0;

      for (int i = 0; i < optimizedOrders.length; i++) {
        final order = optimizedOrders[i];
        final orderLocation = LatLng(order.latitude, order.longitude);

        print(
            '🛣️ Generating route ${i + 1}/${optimizedOrders.length} for Order #${order.id}');

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
          successfulRoutes++;

          print(
              '✅ Real route generated: ${distance.toStringAsFixed(1)}km, ${estimatedTime}min');
        } else {
          // Fallback to straight line calculation
          print('⚠️ Using fallback calculation for Order #${order.id}');
          routePoints = [currentLocation, orderLocation];
          distance = _calculateDistance(currentLocation.latitude,
              currentLocation.longitude, order.latitude, order.longitude);
          estimatedTime =
              (distance * 2.5).round(); // Estimate: 2.5 min per km in city
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

        // Small delay between API calls to avoid rate limiting
        if (i < optimizedOrders.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      print(
          '🎉 Route generation complete: ${successfulRoutes}/${ordersToRoute.length} real routes');
    } catch (e) {
      print('❌ Error generating optimized routes: $e');
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

  // Complete delivery with signature and payment details (using multipart/form-data)
// In your order_service.dart, replace the completeDelivery method with this fixed version:

  Future<bool> completeDelivery(Map<String, dynamic> deliveryData) async {
    if (_token == null) return false;

    // Set loading state at the beginning
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      print('🏁 Completing delivery with data: ${deliveryData.keys}');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/delivery/complete-delivery'),
      );

      // Add headers
      request.headers.addAll({
        'token': _token!,
      });

      // Add form fields
      request.fields['orderId'] = deliveryData['orderId'];
      request.fields['paymentMethod'] = deliveryData['paymentMethod'];
      request.fields['amountPaid'] = deliveryData['amountPaid'];
      request.fields['totalAmount'] = deliveryData['totalAmount'];
      request.fields['deliveryNotes'] = deliveryData['deliveryNotes'];

      // Add signature file if provided
      if (deliveryData['signatureImage'] != null) {
        try {
          // Decode base64 signature
          final signatureBase64 = deliveryData['signatureImage'] as String;
          final signatureBytes = base64Decode(signatureBase64);

          // Create multipart file from bytes
          var signatureFile = http.MultipartFile.fromBytes(
            'signature', // Field name expected by backend
            signatureBytes,
            filename: 'signature_${deliveryData['orderId']}.png',
            contentType: MediaType('image', 'png'),
          );

          request.files.add(signatureFile);
          print('📎 Added signature file: ${signatureBytes.length} bytes');
        } catch (e) {
          print('❌ Error processing signature: $e');
          _lastError = 'Error processing signature';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      print(
          '📤 Sending multipart completion request to: $baseUrl/delivery/complete-delivery');
      print('📝 Form fields: ${request.fields.keys}');
      print('📁 Files: ${request.files.map((f) => f.field).toList()}');

      // Send request with timeout
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      // Convert streamed response to regular response
      final responseBody = await response.stream.bytesToString();

      print('📥 Complete delivery response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(responseBody);
          print('✅ Delivery completed successfully: $responseData');

          final orderId = int.parse(deliveryData['orderId']);

          // Remove completed order from active routes
          _activeRoutes.removeWhere((route) => route.order.id == orderId);
          if (_activeRoutes.length <= 1) {
            _isBatchDeliveryActive = false;
          }

          // Refresh orders
          await fetchAssignedOrders();
          await fetchCompletedOrders();

          print('✅ Orders refreshed after completion');

          // Reset loading state on success
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          print('❌ Error parsing success response: $e');
          // Still return true since the request was successful (200)
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = json.decode(responseBody);
          print('❌ Bad request: ${errorData}');
          _lastError = errorData['message'] ?? 'Bad request';
        } catch (e) {
          print('❌ Bad request - could not parse error: $responseBody');
          _lastError = 'Bad request - invalid data format';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized request');
        _lastError = 'Authentication failed. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (response.statusCode == 404) {
        print('❌ Order not found');
        _lastError = 'Order not found or already completed.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (response.statusCode == 500) {
        print('❌ Server error: $responseBody');
        _lastError = 'Server error: Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        print(
            '❌ Failed to complete delivery: ${response.statusCode} - $responseBody');
        _lastError = 'Failed to complete delivery: HTTP ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error completing delivery: $e');

      if (e is TimeoutException) {
        _lastError = 'Request timeout. Please check your internet connection.';
      } else if (e.toString().contains('SocketException')) {
        _lastError = 'Network error. Please check your internet connection.';
      } else {
        _lastError = 'Error completing delivery: ${e.toString()}';
      }

      // Reset loading state on error
      _isLoading = false;
      notifyListeners();
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

  Future<void> testGoogleDirectionsAPI() async {
    print('🧪 Testing Google Directions API...');

    // Test with known coordinates (e.g., from Amman to nearby location)
    final testOrigin = LatLng(31.9539, 35.9106); // Amman center
    final testDestination = LatLng(31.9613, 35.9467); // Nearby location

    final result = await _getDirectionsFromGoogle(testOrigin, testDestination);

    if (result != null) {
      print('✅ Google Directions API test successful!');
      print('   Distance: ${result.distanceKm.toStringAsFixed(2)}km');
      print('   Duration: ${result.durationMinutes} minutes');
      print('   Points: ${result.points.length}');
    } else {
      print('❌ Google Directions API test failed!');
      print('   Check API key: $googleMapsApiKey');
      print('   Verify billing is enabled for Google Maps Platform');
      print('   Ensure Directions API is enabled in Google Cloud Console');
    }
  }
}
