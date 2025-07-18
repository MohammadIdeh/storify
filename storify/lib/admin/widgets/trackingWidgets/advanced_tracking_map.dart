// lib/admin/widgets/trackingWidgets/advanced_tracking_map.dart

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import 'dart:convert';
import 'dart:async';

class AdvancedTrackingMap extends StatefulWidget {
  final bool showAsCards;
  final Function(int)? onOrderCancel;

  const AdvancedTrackingMap({
    super.key,
    this.showAsCards = false,
    this.onOrderCancel,
  });

  @override
  State<AdvancedTrackingMap> createState() => _AdvancedTrackingMapState();
}

class _AdvancedTrackingMapState extends State<AdvancedTrackingMap> {
  // PUBLIC METHOD: This is called from track.dart to refresh the map
  Future<void> refreshMapData() async {
    debugPrint('🔄 Refreshing map data after order cancellation...');

    // Store the currently selected order ID
    final previouslySelectedOrderId = _selectedOrderId;

    await _fetchTrackingData();

    // Check if the previously selected order still exists
    if (previouslySelectedOrderId != null) {
      final orderStillExists =
          _orders.any((order) => order['orderId'] == previouslySelectedOrderId);

      if (!orderStillExists) {
        debugPrint(
            '⚠️ Previously selected order #$previouslySelectedOrderId no longer exists, resetting selection');
        setState(() {
          _selectedOrderId = null;
          _showAllOrders = true;
        });
      }
    }

    // Refresh the map view
    if (mapController != null && _currentLatLng != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 12),
      );
    }
  }

  GoogleMapController? mapController;
  LatLng? _currentLatLng;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Data from API
  Map<String, dynamic>? _trackingData;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoadingRoutes = false;

  // UI State
  int? _selectedOrderId;
  bool _showAllOrders = true;
  String _selectedFilter = 'all';
  bool _showSummary = true;

  // Route colors for different orders
  final List<Color> _routeColors = [
    const Color(0xFF6366F1), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Yellow
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFF97316), // Orange
    const Color(0xFF84CC16), // Lime
    const Color(0xFFF97316), // Orange
  ];

  // Backend API base URL
  static const String _backendBaseUrl =
      'https://finalproject-a5ls.onrender.com';

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLatLng = loc;
      });
    }).catchError((error) {
      setState(() {
        _currentLatLng = const LatLng(31.9000, 35.2000);
      });
    });
    _fetchTrackingData();
  }

  Future<Position> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _fetchTrackingData() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final headers = await AuthService.getAuthHeaders(role: 'Admin');
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/dashboard/tracking-orders/detailed'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _trackingData = data;
          _orders = data['orders'] ?? [];
          _isLoading = false;
        });

        // ADD DEBUG LOGGING
        debugPrint('✅ Map data refreshed - Found ${_orders.length} orders');
        await _updateMapMarkersWithRealRoutes();
      } else {
        setState(() {
          _errorMessage =
              'Failed to load tracking data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error fetching tracking data: $e';
        _isLoading = false;
      });
    }
  }

  Future<GoogleDirectionsResponse?> _getDirectionsFromGoogle(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      // Validate coordinates
      if (origin.latitude.abs() > 90 ||
          origin.longitude.abs() > 180 ||
          destination.latitude.abs() > 90 ||
          destination.longitude.abs() > 180) {
        debugPrint('❌ Invalid coordinates provided');
        return null;
      }

      debugPrint('🗺️ Requesting directions directly from Google...');
      debugPrint(
          '📍 From: ${origin.latitude.toStringAsFixed(6)}, ${origin.longitude.toStringAsFixed(6)}');
      debugPrint(
          '📍 To: ${destination.latitude.toStringAsFixed(6)}, ${destination.longitude.toStringAsFixed(6)}');

      // Google Maps API Key
      const String googleMapsApiKey = 'AIzaSyCJMZfn5L4HMpbF7oKfqJjbuB9DysEbXdI';

      // Build Google Directions API URL
      final String baseUrl =
          'https://maps.googleapis.com/maps/api/directions/json';
      final String url = '$baseUrl'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$googleMapsApiKey'
          '&mode=driving'
          '&alternatives=false'
          '&units=metric';

      // For web, use CORS proxy to avoid CORS issues
      final String finalUrl = kIsWeb
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}'
          : url;

      debugPrint('📱 Calling Google Directions API directly...');

      final response = await http.get(
        Uri.parse(finalUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'StorifyAdmin/1.0',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'Google Directions API timeout after 15 seconds');
        },
      );

      debugPrint(
          '📥 Google Directions response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        debugPrint('📊 Google API status: ${data['status']}');

        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // OPTION 1: Use step-by-step coordinates (more accurate)
          List<LatLng> routePoints = [];

          debugPrint('🔍 Extracting route points from steps...');

          if (leg['steps'] != null) {
            for (var step in leg['steps']) {
              // Add start location of each step
              final startLat = step['start_location']['lat'];
              final startLng = step['start_location']['lng'];
              routePoints.add(LatLng(startLat.toDouble(), startLng.toDouble()));

              // Add end location of each step
              final endLat = step['end_location']['lat'];
              final endLng = step['end_location']['lng'];
              routePoints.add(LatLng(endLat.toDouble(), endLng.toDouble()));
            }

            debugPrint(
                '✅ Extracted ${routePoints.length} points from ${leg['steps'].length} steps');
          }

          // FALLBACK: If steps method fails, try polyline decoding
          if (routePoints.isEmpty) {
            debugPrint('⚠️ No points from steps, trying polyline decoding...');
            final encodedPolyline =
                route['overview_polyline']['points'] as String;
            routePoints = _decodePolylineSimple(encodedPolyline);
          }

          // ULTIMATE FALLBACK: Just use start and end points
          if (routePoints.isEmpty) {
            debugPrint(
                '⚠️ Polyline decoding failed, using start/end points only');
            routePoints = [
              LatLng(leg['start_location']['lat'].toDouble(),
                  leg['start_location']['lng'].toDouble()),
              LatLng(leg['end_location']['lat'].toDouble(),
                  leg['end_location']['lng'].toDouble()),
            ];
          }

          // Extract distance and duration
          final distanceKm = (leg['distance']['value'] as int) / 1000.0;

          int durationSeconds;
          if (leg['duration_in_traffic'] != null) {
            durationSeconds = leg['duration_in_traffic']['value'] as int;
          } else {
            durationSeconds = leg['duration']['value'] as int;
          }
          final durationMinutes = (durationSeconds / 60).round();

          // Debug the actual coordinates
          if (routePoints.isNotEmpty) {
            debugPrint('🎯 Route validation:');
            debugPrint(
                '   First point: ${routePoints.first.latitude.toStringAsFixed(6)}, ${routePoints.first.longitude.toStringAsFixed(6)}');
            debugPrint(
                '   Last point: ${routePoints.last.latitude.toStringAsFixed(6)}, ${routePoints.last.longitude.toStringAsFixed(6)}');

            // Check if coordinates are in expected range for Palestine/West Bank
            bool validRegion = routePoints.every((point) =>
                point.latitude >= 31.0 &&
                point.latitude <= 33.0 &&
                point.longitude >= 34.0 &&
                point.longitude <= 36.0);

            debugPrint(
                '   Region validation: ${validRegion ? '✅ Valid' : '❌ Invalid'} for Palestine/West Bank');
          }

          debugPrint('✅ Google Directions success:');
          debugPrint('   📏 Distance: ${distanceKm.toStringAsFixed(2)}km');
          debugPrint('   ⏱️ Duration: ${durationMinutes}min');
          debugPrint('   🛣️ Route points: ${routePoints.length}');

          return GoogleDirectionsResponse(
            points: routePoints,
            distanceKm: distanceKm,
            durationMinutes: durationMinutes,
            encodedPolyline: route['overview_polyline']['points'] as String,
          );
        } else {
          debugPrint('❌ Google Directions API error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('❌ Google Directions HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error calling Google Directions: $e');
      return null;
    }
  }

  // SIMPLE POLYLINE DECODER (as backup)
  List<LatLng> _decodePolylineSimple(String encoded) {
    List<LatLng> points = [];

    if (encoded.isEmpty) return points;

    int index = 0;
    int lat = 0;
    int lng = 0;

    try {
      while (index < encoded.length) {
        int b, shift = 0, result = 0;

        // Decode latitude
        do {
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
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        double finalLat = lat / 100000.0;
        double finalLng = lng / 100000.0;

        // Only add valid coordinates
        if (finalLat.abs() <= 90 && finalLng.abs() <= 180) {
          points.add(LatLng(finalLat, finalLng));
        }
      }
    } catch (e) {
      debugPrint('❌ Simple polyline decode error: $e');
    }

    debugPrint('🔄 Simple decoder: ${points.length} points');
    return points;
  }

  // Polyline decoding function
  List<LatLng> _decodePolyline(String encoded) {
    try {
      if (encoded.isEmpty) {
        debugPrint('❌ Empty polyline string');
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

        if (latLng.latitude.abs() <= 90 && latLng.longitude.abs() <= 180) {
          points.add(latLng);
        }
      }

      debugPrint('🔄 Decoded ${points.length} points from polyline');
      return points;
    } catch (e) {
      debugPrint('❌ Error decoding polyline: $e');
      return [];
    }
  }

  Future<void> _updateMapMarkersWithRealRoutes() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRoutes = true;
    });

    // CLEAR EXISTING DATA FIRST
    _markers.clear();
    _polylines.clear();

    debugPrint('🔄 Processing ${_orders.length} orders for routes');

    // Process routes individually
    for (int i = 0; i < _orders.length; i++) {
      var order = _orders[i];
      final orderLocation = order['locationData']?['deliveryLocation'];
      final customerLocation = order['locationData']?['customerLocation'];

      if (orderLocation != null && customerLocation != null) {
        final deliveryLat = orderLocation['latitude']?.toDouble();
        final deliveryLng = orderLocation['longitude']?.toDouble();
        final customerLat = customerLocation['latitude']?.toDouble();
        final customerLng = customerLocation['longitude']?.toDouble();

        if (deliveryLat != null &&
            deliveryLng != null &&
            customerLat != null &&
            customerLng != null) {
          final urgency = order['orderStatus']?['urgencyLevel'] ?? 'Medium';
          final routeColor = _routeColors[i % _routeColors.length];
          final orderId = order['orderId'];

          final deliveryLocation = LatLng(deliveryLat, deliveryLng);
          final customerLocationLatLng = LatLng(customerLat, customerLng);

          // Add delivery man marker
          _markers.add(
            Marker(
              markerId: MarkerId('delivery_$orderId'),
              position: deliveryLocation,
              icon: await _getDeliveryManIcon(urgency),
              infoWindow: InfoWindow(
                title:
                    '🚚 ${context.l10n.deliveryMan} - ${context.l10n.route} #$orderId',
                snippet:
                    '${context.l10n.customer}: ${order['customer']?['personalInfo']?['name'] ?? context.l10n.unknownCustomer}\n${context.l10n.totalValue}: \$${order['orderMetrics']?['totalValue'] ?? 0}\n${context.l10n.status}: ${order['orderStatus']?['current'] ?? 'pending'}',
                onTap: () => _selectSpecificOrder(orderId),
              ),
              onTap: () => _selectSpecificOrder(orderId),
            ),
          );

          // Add customer marker
          _markers.add(
            Marker(
              markerId: MarkerId('customer_$orderId'),
              position: customerLocationLatLng,
              icon: await _getCustomerIcon(),
              infoWindow: InfoWindow(
                title:
                    '🏠 ${order['customer']?['personalInfo']?['name'] ?? context.l10n.customer}',
                snippet:
                    '${context.l10n.route} #$orderId\n${context.l10n.address}: ${order['customer']?['deliveryAddress']?['fullAddress'] ?? context.l10n.unknownAddress}\n${context.l10n.phone}: ${order['customer']?['personalInfo']?['phone'] ?? 'N/A'}',
                onTap: () => _selectSpecificOrder(orderId),
              ),
              onTap: () => _selectSpecificOrder(orderId),
            ),
          );

          // Get real route
          debugPrint('🗺️ Loading real route for Order #$orderId');

          final directionsResponse = await _getDirectionsFromGoogle(
            deliveryLocation,
            customerLocationLatLng,
          );

          List<LatLng> routePoints;
          bool isRealRoute = false;

          if (directionsResponse != null &&
              directionsResponse.points.isNotEmpty) {
            // Use real route
            routePoints = directionsResponse.points;
            isRealRoute = true;
            debugPrint(
                '✅ Real route loaded for Order #$orderId: ${directionsResponse.points.length} points, ${directionsResponse.distanceKm.toStringAsFixed(1)}km');
          } else {
            // Fallback to straight line
            debugPrint(
                '⚠️ Directions failed for Order #$orderId, using straight line');
            routePoints = [deliveryLocation, customerLocationLatLng];
            isRealRoute = false;
          }

          // Add route polyline
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route_$orderId'),
              points: routePoints,
              color: routeColor,
              width: isRealRoute ? 6 : 4,
              patterns: isRealRoute ? [] : _getRoutePattern(urgency),
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          );

          // Add delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }

    // Add admin current location marker (NOT counted as a route)
    if (_currentLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('adminLocation'),
          position: _currentLatLng!,
          icon: await _getAdminIcon(),
          infoWindow: InfoWindow(
            title: '👑 ${context.l10n.adminControlCenter}',
            snippet:
                '${context.l10n.monitoring} ${_orders.length} ${context.l10n.activeDeliveries}\n${context.l10n.yourCurrentLocation}',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoadingRoutes = false;
      });
    }

    debugPrint(
        '✅ Map updated with ${_orders.length} routes, ${_markers.length} markers, ${_polylines.length} polylines');
  }

  void _selectSpecificOrder(int orderId) {
    setState(() {
      _selectedOrderId = orderId;
      _showAllOrders = false;
    });

    // Focus on the selected order's route
    final selectedOrder = _orders.cast<Map<String, dynamic>>().firstWhere(
          (o) => o['orderId'] == orderId,
          orElse: () => <String, dynamic>{},
        );

    if (selectedOrder.isNotEmpty) {
      _focusOnRoute(selectedOrder);
    }

    debugPrint('Selected order: $orderId');
  }

  Future<BitmapDescriptor> _createMarkerFromIcon({
    required IconData iconData,
    required Color backgroundColor,
    required Color iconColor,
    double size = 48,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw circle background
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 1, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 1, borderPaint);

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: iconData.fontFamily,
        color: iconColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

// Updated delivery man icon with truck
  Future<BitmapDescriptor> _getDeliveryManIcon(String urgency) async {
    Color backgroundColor;

    switch (urgency.toLowerCase()) {
      case 'high':
        backgroundColor = Colors.red;
        break;
      case 'medium':
        backgroundColor = Colors.orange;
        break;
      case 'low':
        backgroundColor = Colors.green;
        break;
      default:
        backgroundColor = Colors.grey;
    }

    try {
      return await _createMarkerFromIcon(
        iconData: Icons.local_shipping,
        backgroundColor: backgroundColor,
        iconColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Failed to create custom delivery icon: $e');
      // Fallback to default colored marker
      switch (urgency.toLowerCase()) {
        case 'high':
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        case 'medium':
          return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange);
        case 'low':
          return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen);
        default:
          return BitmapDescriptor.defaultMarker;
      }
    }
  }

// Updated customer icon with person
  Future<BitmapDescriptor> _getCustomerIcon() async {
    try {
      return await _createMarkerFromIcon(
        iconData: Icons.person,
        backgroundColor: Colors.blue,
        iconColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Failed to create custom customer icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

// Updated admin icon with house
  Future<BitmapDescriptor> _getAdminIcon() async {
    try {
      return await _createMarkerFromIcon(
        iconData: Icons.home,
        backgroundColor: const Color(0xFFFFD700), // Gold color
        iconColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Failed to create custom admin icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }
  }

  List<PatternItem> _getRoutePattern(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return []; // Solid line for high priority
      case 'medium':
        return [PatternItem.dash(30), PatternItem.gap(10)]; // Dashed for medium
      case 'low':
        return [PatternItem.dot, PatternItem.gap(15)]; // Dotted for low
      default:
        return [PatternItem.dash(20), PatternItem.gap(10)];
    }
  }

  void _selectOrder(int orderId) {
    setState(() {
      _selectedOrderId = orderId;
      _showAllOrders = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_currentLatLng != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 12),
      );
    }
  }

  Widget _buildSummaryCards() {
    if (_trackingData == null) return const SizedBox.shrink();

    final summary = _trackingData!['summary'];
    if (summary == null) return const SizedBox.shrink();

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color.fromARGB(255, 46, 57, 84)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    l10n.liveRouteSummary,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                  ),
                  SizedBox(width: 8.w),
                  if (_isLoadingRoutes)
                    SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                      ),
                    ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 12.sp,
                          color: const Color(0xFF10B981),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          l10n.realRoutes,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => setState(() => _showSummary = !_showSummary),
                icon: Icon(
                  _showSummary ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (_showSummary) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    l10n.activeRoutes,
                    _orders.length
                        .toString(), // Use actual orders count instead of backend count
                    Icons.route,
                    const Color(0xFF6366F1),
                    isArabic,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSummaryItem(
                    l10n.totalValue,
                    '\$${summary['totalValueInTransit'] ?? 0}',
                    Icons.attach_money,
                    const Color(0xFF10B981),
                    isArabic,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    l10n.avgDistance,
                    '${_calculateAverageDistance().toStringAsFixed(1)} ${l10n.km}',
                    Icons.straighten,
                    const Color(0xFF8B5CF6),
                    isArabic,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSummaryItem(
                    l10n.outstanding,
                    '\$${summary['outstandingPayments'] ?? 0}',
                    Icons.payment,
                    const Color(0xFFF59E0B),
                    isArabic,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildUrgencyBreakdown(summary['urgencyBreakdown'] ?? {}),
          ],
        ],
      ),
    );
  }

  double _calculateAverageDistance() {
    if (_orders.isEmpty) return 0.0;

    double totalDistance = 0.0;
    int validOrders = 0;

    for (var order in _orders) {
      final orderLocation = order['locationData']?['deliveryLocation'];
      final customerLocation = order['locationData']?['customerLocation'];

      if (orderLocation != null && customerLocation != null) {
        final deliveryLat = orderLocation['latitude']?.toDouble();
        final deliveryLng = orderLocation['longitude']?.toDouble();
        final customerLat = customerLocation['latitude']?.toDouble();
        final customerLng = customerLocation['longitude']?.toDouble();

        if (deliveryLat != null &&
            deliveryLng != null &&
            customerLat != null &&
            customerLng != null) {
          final distance = Geolocator.distanceBetween(
                  deliveryLat, deliveryLng, customerLat, customerLng) /
              1000; // Convert to km

          totalDistance += distance;
          validOrders++;
        }
      }
    }

    return validOrders > 0 ? totalDistance / validOrders : 0.0;
  }

  Widget _buildSummaryItem(
      String title, String value, IconData icon, Color color, bool isArabic) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 4.h),
          Text(
            value,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
          ),
          Text(
            title,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBreakdown(Map<String, dynamic> urgencyData) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.routePriorityBreakdown,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
          ),
          SizedBox(height: 8.h),
          Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              children: [
                _buildUrgencyChip(l10n.high, urgencyData['high'] ?? 0,
                    Colors.red, '━━━', isArabic),
                SizedBox(width: 8.w),
                _buildUrgencyChip(l10n.medium, urgencyData['medium'] ?? 0,
                    Colors.orange, '┅┅┅', isArabic),
                SizedBox(width: 8.w),
                _buildUrgencyChip(l10n.low, urgencyData['low'] ?? 0,
                    Colors.green, '⋯⋯⋯', isArabic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(
      String label, int count, Color color, String pattern, bool isArabic) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '$label ($count)',
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: Colors.white,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.white,
                      ),
              ),
            ],
          ),
          Text(
            pattern,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: color,
                    fontWeight: FontWeight.w900,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 10.sp,
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color.fromARGB(255, 46, 57, 84)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.routeControls,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
          ),
          SizedBox(height: 12.h),
          Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() {
                      _showAllOrders = true;
                      _selectedOrderId = null;
                    }),
                    icon: Icon(
                        _showAllOrders ? Icons.route : Icons.route_outlined),
                    label: Text(
                      _showAllOrders ? l10n.allRoutes : l10n.showAll,
                      style: isArabic
                          ? GoogleFonts.cairo()
                          : GoogleFonts.spaceGrotesk(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showAllOrders
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _fetchTrackingData();
                    },
                    icon: _isLoadingRoutes
                        ? SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isLoadingRoutes ? l10n.updating : l10n.refreshRoutes,
                      style: isArabic
                          ? GoogleFonts.cairo()
                          : GoogleFonts.spaceGrotesk(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Wrap(
              spacing: 8.w,
              children: [
                _buildFilterChip(l10n.allRoutes, 'all', isArabic),
                _buildFilterChip(l10n.highPriority, 'high', isArabic),
                _buildFilterChip(l10n.mediumPriority, 'medium', isArabic),
                _buildFilterChip(l10n.lowPriority, 'low', isArabic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isArabic) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: isArabic
            ? GoogleFonts.cairo(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12.sp,
              )
            : GoogleFonts.spaceGrotesk(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12.sp,
              ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: const Color(0xFF374151),
      selectedColor: const Color(0xFF6366F1),
    );
  }

  Widget _buildLiveOrdersCards() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    final filteredOrders = _orders.where((order) {
      if (_selectedFilter == 'all') return true;
      final urgency =
          order['orderStatus']?['urgencyLevel']?.toString().toLowerCase() ?? '';
      return urgency == _selectedFilter;
    }).toList();

    if (filteredOrders.isEmpty) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color.fromARGB(255, 46, 57, 84)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.route_outlined,
                size: 48.sp,
                color: Colors.white54,
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.noActiveRoutes,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 16.sp,
                        color: Colors.white70,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        color: Colors.white70,
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.4,
      ),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final routeColor = _routeColors[index % _routeColors.length];
        return _buildLiveOrderCard(order, routeColor);
      },
    );
  }

  Widget _buildLiveOrderCard(Map<String, dynamic> order, Color routeColor) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);
    final orderId = order['orderId'];
    final canCancel = order['orderStatus']?['current'] == 'on_theway';

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _selectedOrderId == orderId
              ? routeColor
              : const Color.fromARGB(255, 46, 57, 84),
          width: _selectedOrderId == orderId ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: routeColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectOrder(orderId),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: routeColor,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '${l10n.route} #$orderId',
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(order['orderStatus']
                                    ?['urgencyLevel'] ??
                                'Medium')
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _getLocalizedUrgency(
                            order['orderStatus']?['urgencyLevel'] ?? 'Medium'),
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 8.sp,
                                color: _getUrgencyColor(order['orderStatus']
                                        ?['urgencyLevel'] ??
                                    'Medium'),
                                fontWeight: FontWeight.w600,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 8.sp,
                                color: _getUrgencyColor(order['orderStatus']
                                        ?['urgencyLevel'] ??
                                    'Medium'),
                                fontWeight: FontWeight.w600,
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 12.sp,
                      color: routeColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '→',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: Colors.white70,
                              fontWeight: FontWeight.w900,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              color: Colors.white70,
                              fontWeight: FontWeight.w900,
                            ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.home,
                      size: 12.sp,
                      color: Colors.blue,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  order['customer']?['personalInfo']?['name'] ??
                      l10n.unknownCustomer,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 14.sp,
                      color: const Color(0xFF10B981),
                    ),
                    Text(
                      '\$${order['orderMetrics']?['totalValue'] ?? 0}',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.verified,
                      size: 12.sp,
                      color: routeColor,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      l10n.real,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 10.sp,
                              color: routeColor,
                              fontWeight: FontWeight.w700,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 10.sp,
                              color: routeColor,
                              fontWeight: FontWeight.w700,
                            ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12.sp,
                      color: Colors.white54,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        order['orderStatus']?['orderAge']?['formatted'] ??
                            l10n.unknown,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 10.sp,
                                color: Colors.white54,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 10.sp,
                                color: Colors.white54,
                              ),
                      ),
                    ),
                    if (canCancel) ...[
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: () async {
                          // Show immediate visual feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${l10n.processingCancellation} #$orderId...',
                                style: isArabic
                                    ? GoogleFonts.cairo(color: Colors.white)
                                    : GoogleFonts.spaceGrotesk(
                                        color: Colors.white),
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Call parent's cancel function
                          widget.onOrderCancel?.call(orderId);
                        },
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          child: Icon(
                            Icons.cancel_outlined,
                            size: 14.sp,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: 4.w),
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: routeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalizedUrgency(String urgency) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    switch (urgency.toLowerCase()) {
      case 'high':
        return l10n.high;
      case 'medium':
        return l10n.medium;
      case 'low':
        return l10n.low;
      default:
        return l10n.medium;
    }
  }

  Widget _buildOrderDetails() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    if (_selectedOrderId == null || _showAllOrders) {
      return _buildOrdersList();
    }

    final order = _orders.cast<Map<String, dynamic>>().firstWhere(
          (o) => o['orderId'] == _selectedOrderId,
          orElse: () => <String, dynamic>{},
        );

    if (order.isEmpty) return const SizedBox.shrink();

    final canCancel = order['orderStatus']?['current'] == 'on_theway';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color.fromARGB(255, 46, 57, 84)),
      ),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${l10n.route} #${order['orderId'] ?? 'N/A'}',
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() {
                    _selectedOrderId = null;
                    _showAllOrders = true;
                  }),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Route Status
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _getStatusColor(
                        order['orderStatus']?['current'] ?? 'pending')
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: _getStatusColor(
                      order['orderStatus']?['current'] ?? 'pending'),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route,
                    size: 16.sp,
                    color: _getStatusColor(
                        order['orderStatus']?['current'] ?? 'pending'),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${l10n.route.toUpperCase()} ${(order['orderStatus']?['current'] ?? 'pending').toString().toUpperCase()}',
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(
                                order['orderStatus']?['current'] ?? 'pending'),
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(
                                order['orderStatus']?['current'] ?? 'pending'),
                          ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Route Information
            _buildDetailSection(
                l10n.routeInformation,
                [
                  _buildDetailRow(l10n.deliveryMan,
                      '${l10n.deliveryAgent} #${order['orderId']}', isArabic),
                  _buildDetailRow(
                      l10n.customer,
                      order['customer']?['personalInfo']?['name'] ?? 'N/A',
                      isArabic),
                  _buildDetailRow(l10n.routeStatus,
                      order['orderStatus']?['current'] ?? 'N/A', isArabic),
                  _buildDetailRow(
                      l10n.priorityLevel,
                      _getLocalizedUrgency(
                          order['orderStatus']?['urgencyLevel'] ?? 'Medium'),
                      isArabic),
                  _buildDetailRow(
                      l10n.estimatedDistance,
                      '${_calculateDistance(order).toStringAsFixed(1)} ${l10n.km}',
                      isArabic),
                ],
                isArabic),

            SizedBox(height: 16.h),

            // Customer Info
            _buildDetailSection(
                l10n.deliveryDestination,
                [
                  _buildDetailRow(
                      l10n.customerPhone,
                      order['customer']?['personalInfo']?['phone'] ?? 'N/A',
                      isArabic),
                  _buildDetailRow(
                      l10n.deliveryAddress,
                      order['customer']?['deliveryAddress']?['fullAddress'] ??
                          'N/A',
                      isArabic),
                  _buildDetailRow(
                      l10n.totalValue,
                      '\$${order['orderMetrics']?['totalValue'] ?? 0}',
                      isArabic),
                  _buildDetailRow(l10n.itemsCountt,
                      '${order['orderMetrics']?['totalItems'] ?? 0}', isArabic),
                ],
                isArabic),

            SizedBox(height: 16.h),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _focusOnRoute(order),
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      l10n.followRoute,
                      style: isArabic
                          ? GoogleFonts.cairo()
                          : GoogleFonts.spaceGrotesk(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (canCancel) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show immediate visual feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${l10n.processingCancellation} #${order['orderId']}...',
                              style: isArabic
                                  ? GoogleFonts.cairo(color: Colors.white)
                                  : GoogleFonts.spaceGrotesk(
                                      color: Colors.white),
                            ),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        widget.onOrderCancel?.call(order['orderId']);
                      },
                      icon: const Icon(Icons.cancel),
                      label: Text(
                        l10n.cancelOrder,
                        style: isArabic
                            ? GoogleFonts.cairo()
                            : GoogleFonts.spaceGrotesk(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistance(Map<String, dynamic> order) {
    final orderLocation = order['locationData']?['deliveryLocation'];
    final customerLocation = order['locationData']?['customerLocation'];

    if (orderLocation != null && customerLocation != null) {
      final deliveryLat = orderLocation['latitude']?.toDouble();
      final deliveryLng = orderLocation['longitude']?.toDouble();
      final customerLat = customerLocation['latitude']?.toDouble();
      final customerLng = customerLocation['longitude']?.toDouble();

      if (deliveryLat != null &&
          deliveryLng != null &&
          customerLat != null &&
          customerLng != null) {
        return Geolocator.distanceBetween(
                deliveryLat, deliveryLng, customerLat, customerLng) /
            1000; // Convert to km
      }
    }
    return 0.0;
  }

  Widget _buildOrdersList() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    final filteredOrders = _orders.where((order) {
      if (_selectedFilter == 'all') return true;
      final urgency =
          order['orderStatus']?['urgencyLevel']?.toString().toLowerCase() ?? '';
      return urgency == _selectedFilter;
    }).toList();

    return Container(
      height: 400.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color.fromARGB(255, 46, 57, 84)),
      ),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${l10n.activeRoutes} (${filteredOrders.length})',
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return _buildOrderCard(order);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);
    final orderId = order['orderId'];
    final canCancel = order['orderStatus']?['current'] == 'on_theway';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _selectedOrderId == orderId
              ? const Color(0xFF6366F1)
              : const Color.fromARGB(255, 46, 57, 84),
        ),
      ),
      child: InkWell(
        onTap: () => _selectOrder(orderId),
        child: Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.route,
                    size: 16.sp,
                    color: const Color(0xFF6366F1),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${l10n.route} #$orderId',
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(
                              order['orderStatus']?['urgencyLevel'] ?? 'Medium')
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _getLocalizedUrgency(
                          order['orderStatus']?['urgencyLevel'] ?? 'Medium'),
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 10.sp,
                              color: _getUrgencyColor(order['orderStatus']
                                      ?['urgencyLevel'] ??
                                  'Medium'),
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 10.sp,
                              color: _getUrgencyColor(order['orderStatus']
                                      ?['urgencyLevel'] ??
                                  'Medium'),
                            ),
                    ),
                  ),
                  if (canCancel) ...[
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () async {
                        // Show immediate visual feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${l10n.processingCancellation} #$orderId...',
                              style: isArabic
                                  ? GoogleFonts.cairo(color: Colors.white)
                                  : GoogleFonts.spaceGrotesk(
                                      color: Colors.white),
                            ),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        widget.onOrderCancel?.call(orderId);
                      },
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Icon(
                          Icons.cancel_outlined,
                          size: 16.sp,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 12.sp,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    ' → ',
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                  ),
                  Icon(
                    Icons.home,
                    size: 12.sp,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      order['customer']?['personalInfo']?['name'] ??
                          l10n.unknownCustomer,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Text(
                    '\$${order['orderMetrics']?['totalValue'] ?? 0}',
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: const Color(0xFF10B981),
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 12.sp,
                            color: const Color(0xFF10B981),
                          ),
                  ),
                  Text(
                    ' • ${order['orderMetrics']?['totalItems'] ?? 0} ${l10n.items}',
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                  ),
                  const Spacer(),
                  Text(
                    '${_calculateDistance(order).toStringAsFixed(1)} ${l10n.km}',
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 10.sp,
                            color: Colors.white54,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 10.sp,
                            color: Colors.white54,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
      String title, List<Widget> children, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isArabic) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
          ),
          Expanded(
            child: Text(
              value,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_theway':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.yellow;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _focusOnRoute(Map<String, dynamic> order) {
    final orderLocation = order['locationData']?['deliveryLocation'];
    final customerLocation = order['locationData']?['customerLocation'];

    if (orderLocation != null &&
        customerLocation != null &&
        mapController != null) {
      final deliveryLat = orderLocation['latitude']?.toDouble();
      final deliveryLng = orderLocation['longitude']?.toDouble();
      final customerLat = customerLocation['latitude']?.toDouble();
      final customerLng = customerLocation['longitude']?.toDouble();

      if (deliveryLat != null &&
          deliveryLng != null &&
          customerLat != null &&
          customerLng != null) {
        // Calculate bounds to fit both points
        final bounds = LatLngBounds(
          southwest: LatLng(
            deliveryLat < customerLat ? deliveryLat : customerLat,
            deliveryLng < customerLng ? deliveryLng : customerLng,
          ),
          northeast: LatLng(
            deliveryLat > customerLat ? deliveryLat : customerLat,
            deliveryLng > customerLng ? deliveryLng : customerLng,
          ),
        );

        mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100.0),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    if (widget.showAsCards) {
      // Show orders as cards layout
      if (_isLoading) {
        return SizedBox(
          height: 200.h,
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6366F1),
            ),
          ),
        );
      }

      if (_errorMessage != null) {
        return Container(
          height: 200.h,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 36, 50, 69),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 32.sp),
                SizedBox(height: 8.h),
                Text(
                  l10n.failedToLoadRoutes,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                ),
                SizedBox(height: 8.h),
                ElevatedButton(
                  onPressed: _fetchTrackingData,
                  child: Text(
                    l10n.retry,
                    style: isArabic
                        ? GoogleFonts.cairo()
                        : GoogleFonts.spaceGrotesk(),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return _buildLiveOrdersCards();
    }

    // Show full map layout
    if (_isLoading) {
      return Container(
        height: 820.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6366F1),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 820.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                l10n.failedToLoadTrackingData,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 16.sp,
                        color: Colors.white,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        color: Colors.white,
                      ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchTrackingData,
                child: Text(
                  l10n.retry,
                  style: isArabic
                      ? GoogleFonts.cairo()
                      : GoogleFonts.spaceGrotesk(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final initial = _currentLatLng ?? const LatLng(31.9000, 35.2000);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Section
          Expanded(
            flex: 3,
            child: Container(
              height: 820.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color.fromARGB(255, 66, 67, 121).withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: initial,
                        zoom: 12.0,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: _markers,
                      polylines: _polylines,
                      mapType: MapType.normal,
                    ),
                  ),
                  // Updated indicator for real routes
                  Positioned(
                    top: 16.h,
                    left: isRtl ? null : 16.w,
                    right: isRtl ? 16.w : null,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${l10n.realRoads} - ${_orders.length} ${l10n.routes}',
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                          ),
                          if (_isLoadingRoutes) ...[
                            SizedBox(width: 8.w),
                            SizedBox(
                              width: 12.w,
                              height: 12.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Routes legend
                  Positioned(
                    top: 16.h,
                    right: isRtl ? null : 16.w,
                    left: isRtl ? 16.w : null,
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.routeLegend,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_shipping,
                                size: 12.sp,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                l10n.deliveryMan,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 8.sp,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontSize: 8.sp,
                                        color: Colors.white,
                                      ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.home,
                                size: 12.sp,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                l10n.customer,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 8.sp,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontSize: 8.sp,
                                        color: Colors.white,
                                      ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 10.sp,
                                color: Colors.yellow,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                l10n.admin,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 8.sp,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontSize: 8.sp,
                                        color: Colors.white,
                                      ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            height: 1,
                            width: 80.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _routeColors.take(4).toList(),
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            l10n.googleDirectionsRoutes,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 8.sp,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 8.sp,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // Enhanced Control Panel
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 820.h,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummaryCards(),
                    _buildFilterControls(),
                    _buildOrderDetails(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for Google Directions response
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

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
