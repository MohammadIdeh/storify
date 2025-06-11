import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'dart:convert';
import 'dart:async';

class AdvancedTrackingMap extends StatefulWidget {
  final bool showAsCards;

  const AdvancedTrackingMap({super.key, this.showAsCards = false});

  @override
  State<AdvancedTrackingMap> createState() => _AdvancedTrackingMapState();
}

class _AdvancedTrackingMapState extends State<AdvancedTrackingMap> {
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

  // Google Maps API Key - FIXED: Using your actual API key
  static const String _googleMapsApiKey =
      'AIzaSyCJMZfn5L4HMpbF7oKfqJjbuB9DysEbXdI';

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

  @override
  void dispose() {
    super.dispose();
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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final headers = await AuthService.getAuthHeaders(role: 'Admin');
      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/dashboard/tracking-orders/detailed'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _trackingData = data;
          _orders = data['orders'] ?? [];
          _isLoading = false;
        });
        await _updateMapMarkersWithRoutes();
      } else {
        setState(() {
          _errorMessage =
              'Failed to load tracking data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching tracking data: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<LatLng>> _getDirections(LatLng origin, LatLng destination) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'key=$_googleMapsApiKey';

      print('Making directions API call: $url'); // Debug log

      final response = await http.get(Uri.parse(url));

      print(
          'Directions API Response Status: ${response.statusCode}'); // Debug log
      print('Directions API Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final polylinePoints =
              data['routes'][0]['overview_polyline']['points'];
          print('Successfully got polyline points'); // Debug log
          return _decodePolyline(polylinePoints);
        } else {
          print(
              'Directions API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
    }

    // Fallback to straight line if directions fail
    print('Falling back to straight line between points');
    return [origin, destination];
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
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

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylineCoordinates;
  }

  Future<void> _updateMapMarkersWithRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
    });

    _markers.clear();
    _polylines.clear();

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

          // Add delivery man marker with truck icon - FIXED: Only show specific order info
          _markers.add(
            Marker(
              markerId: MarkerId('delivery_$orderId'),
              position: deliveryLocation,
              icon: await _getDeliveryManIcon(urgency),
              infoWindow: InfoWindow(
                title: '🚚 Delivery Man - Order #$orderId',
                snippet:
                    'Customer: ${order['customer']?['personalInfo']?['name'] ?? 'Unknown'}\nValue: \$${order['orderMetrics']?['totalValue'] ?? 0}\nStatus: ${order['orderStatus']?['current'] ?? 'pending'}',
                onTap: () => _selectSpecificOrder(orderId),
              ),
              onTap: () => _selectSpecificOrder(orderId),
            ),
          );

          // Add customer marker with home icon - FIXED: Only show specific customer info
          _markers.add(
            Marker(
              markerId: MarkerId('customer_$orderId'),
              position: customerLocationLatLng,
              icon: await _getCustomerIcon(),
              infoWindow: InfoWindow(
                title:
                    '🏠 ${order['customer']?['personalInfo']?['name'] ?? 'Customer'}',
                snippet:
                    'Order #$orderId\nAddress: ${order['customer']?['deliveryAddress']?['fullAddress'] ?? 'Unknown'}\nPhone: ${order['customer']?['personalInfo']?['phone'] ?? 'N/A'}',
                onTap: () => _selectSpecificOrder(orderId),
              ),
              onTap: () => _selectSpecificOrder(orderId),
            ),
          );

          // Get real route between delivery man and customer
          try {
            final routePoints = await _getDirections(
              deliveryLocation,
              customerLocationLatLng,
            );

            // Add route polyline with custom styling
            _polylines.add(
              Polyline(
                polylineId: PolylineId('route_$orderId'),
                points: routePoints,
                color: routeColor,
                width: 5,
                patterns: _getRoutePattern(urgency),
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
            );

            // Add animated markers along the route for visual effect
            if (routePoints.length > 2) {
              final midPoint = routePoints[routePoints.length ~/ 2];
              _markers.add(
                Marker(
                  markerId: MarkerId('route_indicator_$orderId'),
                  position: midPoint,
                  icon: await _getRouteIndicatorIcon(routeColor),
                  anchor: const Offset(0.5, 0.5),
                  infoWindow: InfoWindow(
                    title: '📍 Route #$orderId Progress',
                    snippet: 'Midpoint of delivery route',
                    onTap: () => _selectSpecificOrder(orderId),
                  ),
                ),
              );
            }
          } catch (e) {
            print('Error creating route for order $orderId: $e');
            // Fallback to straight line
            _polylines.add(
              Polyline(
                polylineId: PolylineId('route_$orderId'),
                points: [deliveryLocation, customerLocationLatLng],
                color: routeColor,
                width: 4,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            );
          }
        }
      }
    }

    // Add admin current location marker
    if (_currentLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('adminLocation'),
          position: _currentLatLng!,
          icon: await _getAdminIcon(),
          infoWindow: InfoWindow(
            title: '👑 Admin Control Center',
            snippet:
                'Monitoring ${_orders.length} active deliveries\nYour current location',
          ),
        ),
      );
    }

    setState(() {
      _isLoadingRoutes = false;
    });
  }

  // FIXED: New method to handle specific order selection
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

    print('Selected order: $orderId'); // Debug log
  }

  Future<BitmapDescriptor> _getDeliveryManIcon(String urgency) async {
    // You can create custom icons here or use different colored markers
    switch (urgency.toLowerCase()) {
      case 'high':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'medium':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'low':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  Future<BitmapDescriptor> _getCustomerIcon() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  Future<BitmapDescriptor> _getAdminIcon() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
  }

  Future<BitmapDescriptor> _getRouteIndicatorIcon(Color color) async {
    // Small marker to indicate active route
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
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
                    'Live Route Summary',
                    style: GoogleFonts.spaceGrotesk(
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
                    'Active Routes',
                    (summary['totalOrders'] ?? 0).toString(),
                    Icons.route,
                    const Color(0xFF6366F1),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Value',
                    '\$${summary['totalValueInTransit'] ?? 0}',
                    Icons.attach_money,
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Avg Distance',
                    '${_calculateAverageDistance().toStringAsFixed(1)} km',
                    Icons.straighten,
                    const Color(0xFF8B5CF6),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSummaryItem(
                    'Outstanding',
                    '\$${summary['outstandingPayments'] ?? 0}',
                    Icons.payment,
                    const Color(0xFFF59E0B),
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
          // Calculate straight line distance (you could enhance this with actual route distance)
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
      String title, String value, IconData icon, Color color) {
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
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.sp,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBreakdown(Map<String, dynamic> urgencyData) {
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
            'Route Priority Breakdown',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildUrgencyChip(
                  'High', urgencyData['high'] ?? 0, Colors.red, '━━━'),
              SizedBox(width: 8.w),
              _buildUrgencyChip(
                  'Medium', urgencyData['medium'] ?? 0, Colors.orange, '┅┅┅'),
              SizedBox(width: 8.w),
              _buildUrgencyChip(
                  'Low', urgencyData['low'] ?? 0, Colors.green, '⋯⋯⋯'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(
      String label, int count, Color color, String pattern) {
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
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            pattern,
            style: GoogleFonts.spaceGrotesk(
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
            'Route Controls',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _showAllOrders = true;
                    _selectedOrderId = null;
                  }),
                  icon:
                      Icon(_showAllOrders ? Icons.route : Icons.route_outlined),
                  label: Text(_showAllOrders ? 'All Routes' : 'Show All'),
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
                  label:
                      Text(_isLoadingRoutes ? 'Updating...' : 'Refresh Routes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            children: [
              _buildFilterChip('All Routes', 'all'),
              _buildFilterChip('High Priority', 'high'),
              _buildFilterChip('Medium Priority', 'medium'),
              _buildFilterChip('Low Priority', 'low'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: const Color(0xFF374151),
      selectedColor: const Color(0xFF6366F1),
      labelStyle: GoogleFonts.spaceGrotesk(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 12.sp,
      ),
    );
  }

  Widget _buildLiveOrdersCards() {
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
                'No Active Routes',
                style: GoogleFonts.spaceGrotesk(
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
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _selectedOrderId == order['orderId']
              ? routeColor
              : const Color.fromARGB(255, 46, 57, 84),
          width: _selectedOrderId == order['orderId'] ? 2 : 1,
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
        onTap: () => _selectOrder(order['orderId']),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
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
                      'Route #${order['orderId'] ?? 'N/A'}',
                      style: GoogleFonts.spaceGrotesk(
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
                      color: _getUrgencyColor(
                              order['orderStatus']?['urgencyLevel'] ?? 'Medium')
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      order['orderStatus']?['urgencyLevel'] ?? 'Medium',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 8.sp,
                        color: _getUrgencyColor(
                            order['orderStatus']?['urgencyLevel'] ?? 'Medium'),
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
                    style: GoogleFonts.spaceGrotesk(
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
                    'Unknown Customer',
                style: GoogleFonts.spaceGrotesk(
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
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.route,
                    size: 12.sp,
                    color: routeColor,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'LIVE',
                    style: GoogleFonts.spaceGrotesk(
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
                          'Unknown',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ),
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
    );
  }

  Widget _buildOrderDetails() {
    if (_selectedOrderId == null || _showAllOrders) {
      return _buildOrdersList();
    }

    final order = _orders.cast<Map<String, dynamic>>().firstWhere(
          (o) => o['orderId'] == _selectedOrderId,
          orElse: () => <String, dynamic>{},
        );

    if (order.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color.fromARGB(255, 46, 57, 84)),
      ),
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
                'Route #${order['orderId'] ?? 'N/A'}',
                style: GoogleFonts.spaceGrotesk(
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
              color:
                  _getStatusColor(order['orderStatus']?['current'] ?? 'pending')
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
                  'ROUTE ${(order['orderStatus']?['current'] ?? 'pending').toString().toUpperCase()}',
                  style: GoogleFonts.spaceGrotesk(
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
          _buildDetailSection('Route Information', [
            _buildDetailRow(
                'Delivery Man', 'Delivery Agent #${order['orderId']}'),
            _buildDetailRow('Customer',
                order['customer']?['personalInfo']?['name'] ?? 'N/A'),
            _buildDetailRow(
                'Route Status', order['orderStatus']?['current'] ?? 'N/A'),
            _buildDetailRow('Priority Level',
                order['orderStatus']?['urgencyLevel'] ?? 'N/A'),
            _buildDetailRow('Estimated Distance',
                '${_calculateDistance(order).toStringAsFixed(1)} km'),
          ]),

          SizedBox(height: 16.h),

          // Customer Info
          _buildDetailSection('Delivery Destination', [
            _buildDetailRow('Customer Phone',
                order['customer']?['personalInfo']?['phone'] ?? 'N/A'),
            _buildDetailRow('Delivery Address',
                order['customer']?['deliveryAddress']?['fullAddress'] ?? 'N/A'),
            _buildDetailRow('Total Value',
                '\$${order['orderMetrics']?['totalValue'] ?? 0}'),
            _buildDetailRow(
                'Items Count', '${order['orderMetrics']?['totalItems'] ?? 0}'),
          ]),

          SizedBox(height: 16.h),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _focusOnRoute(order),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Follow Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
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
                'Active Routes (${filteredOrders.length})',
                style: GoogleFonts.spaceGrotesk(
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
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _selectedOrderId == order['orderId']
              ? const Color(0xFF6366F1)
              : const Color.fromARGB(255, 46, 57, 84),
        ),
      ),
      child: InkWell(
        onTap: () => _selectOrder(order['orderId']),
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
                  'Route #${order['orderId'] ?? 'N/A'}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor(
                            order['orderStatus']?['urgencyLevel'] ?? 'Medium')
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    order['orderStatus']?['urgencyLevel'] ?? 'Medium',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.sp,
                      color: _getUrgencyColor(
                          order['orderStatus']?['urgencyLevel'] ?? 'Medium'),
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
                  color: Colors.orange,
                ),
                SizedBox(width: 4.w),
                Text(
                  ' → ',
                  style: GoogleFonts.spaceGrotesk(
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
                        'Unknown Customer',
                    style: GoogleFonts.spaceGrotesk(
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
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Text(
                  ' • ${order['orderMetrics']?['totalItems'] ?? 0} items',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_calculateDistance(order).toStringAsFixed(1)} km',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.sp,
              color: Colors.white70,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
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
                  'Failed to load routes',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                ElevatedButton(
                  onPressed: _fetchTrackingData,
                  child: const Text('Retry'),
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
                'Failed to load tracking data',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchTrackingData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final initial = _currentLatLng ?? const LatLng(31.9000, 35.2000);

    return Row(
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
                // Live routes indicator
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
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
                          'LIVE ROUTES',
                          style: GoogleFonts.spaceGrotesk(
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
                  right: 16.w,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROUTE LEGEND',
                          style: GoogleFonts.spaceGrotesk(
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
                              'Delivery Man',
                              style: GoogleFonts.spaceGrotesk(
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
                              'Customer',
                              style: GoogleFonts.spaceGrotesk(
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
                              'Admin',
                              style: GoogleFonts.spaceGrotesk(
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
                          'Route Colors',
                          style: GoogleFonts.spaceGrotesk(
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

        // Control Panel
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
    );
  }
}
