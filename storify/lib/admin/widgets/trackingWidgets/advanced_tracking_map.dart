import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart'; // Added missing import
import 'dart:convert';
import 'dart:async';

class AdvancedTrackingMap extends StatefulWidget {
  final bool showAsCards;

  const AdvancedTrackingMap({super.key, this.showAsCards = false});

  @override
  State<AdvancedTrackingMap> createState() => _AdvancedTrackingMapState();
}

class _AdvancedTrackingMapState extends State<AdvancedTrackingMap> {
  GoogleMapController? mapController; // Made nullable
  LatLng? _currentLatLng;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _refreshTimer;

  // Data from API
  Map<String, dynamic>? _trackingData;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

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
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLatLng = loc;
      });
    }).catchError((error) {
      // Handle location permission errors gracefully
      setState(() {
        _currentLatLng = const LatLng(31.9000, 35.2000); // Default location
      });
    });
    _fetchTrackingData();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchTrackingData();
    });
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
        _updateMapMarkers();
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

  void _updateMapMarkers() {
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

          // Add delivery location marker
          _markers.add(
            Marker(
              markerId: MarkerId('delivery_${order['orderId']}'),
              position: LatLng(deliveryLat, deliveryLng),
              icon: _getMarkerIcon(urgency),
              infoWindow: InfoWindow(
                title: 'Order #${order['orderId']} - Delivery',
                snippet:
                    '${order['customer']?['personalInfo']?['name']} - \$${order['orderMetrics']?['totalValue']}',
                onTap: () => _selectOrder(order['orderId']),
              ),
              onTap: () => _selectOrder(order['orderId']),
            ),
          );

          // Add customer location marker
          _markers.add(
            Marker(
              markerId: MarkerId('customer_${order['orderId']}'),
              position: LatLng(customerLat, customerLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
              infoWindow: InfoWindow(
                title:
                    'Customer - ${order['customer']?['personalInfo']?['name']}',
                snippet:
                    'Delivery Address: ${order['customer']?['deliveryAddress']?['fullAddress']}',
                onTap: () => _selectOrder(order['orderId']),
              ),
              onTap: () => _selectOrder(order['orderId']),
            ),
          );

          // Add route polyline between delivery and customer
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route_${order['orderId']}'),
              points: [
                LatLng(deliveryLat, deliveryLng),
                LatLng(customerLat, customerLng),
              ],
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

    // Add admin current location marker with distinctive color (Gold)
    if (_currentLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('adminLocation'),
          position: _currentLatLng!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: const InfoWindow(
            title: '👑 Admin Location',
            snippet: 'Control Center',
          ),
        ),
      );
    }

    setState(() {});
  }

  BitmapDescriptor _getMarkerIcon(String urgency) {
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
              Text(
                'Real-Time Summary',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
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
                    'Total Orders',
                    (summary['totalOrders'] ?? 0).toString(),
                    Icons.local_shipping,
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
                    'Avg Order Value',
                    '\$${(summary['averageOrderValue'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.trending_up,
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
            'Urgency Breakdown',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildUrgencyChip('High', urgencyData['high'] ?? 0, Colors.red),
              SizedBox(width: 8.w),
              _buildUrgencyChip(
                  'Medium', urgencyData['medium'] ?? 0, Colors.orange),
              SizedBox(width: 8.w),
              _buildUrgencyChip('Low', urgencyData['low'] ?? 0, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
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
            'Tracking Controls',
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
                  icon: Icon(
                      _showAllOrders ? Icons.visibility : Icons.visibility_off),
                  label: Text(_showAllOrders ? 'Tracking All' : 'Track All'),
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
                  onPressed: _fetchTrackingData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
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
              _buildFilterChip('All', 'all'),
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
                Icons.local_shipping_outlined,
                size: 48.sp,
                color: Colors.white54,
              ),
              SizedBox(height: 12.h),
              Text(
                'No Active Orders',
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
                      'Order #${order['orderId'] ?? 'N/A'}',
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
                    Icons.shopping_bag_outlined,
                    size: 14.sp,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${order['orderMetrics']?['totalItems'] ?? 0}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      color: Colors.white70,
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
              Text(
                'Order #${order['orderId'] ?? 'N/A'}',
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

          // Status Badge
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
            child: Text(
              (order['orderStatus']?['current'] ?? 'pending')
                  .toString()
                  .toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(
                    order['orderStatus']?['current'] ?? 'pending'),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Customer Info
          _buildDetailSection('Customer Information', [
            _buildDetailRow(
                'Name', order['customer']?['personalInfo']?['name'] ?? 'N/A'),
            _buildDetailRow(
                'Phone', order['customer']?['personalInfo']?['phone'] ?? 'N/A'),
            _buildDetailRow(
                'Email', order['customer']?['personalInfo']?['email'] ?? 'N/A'),
            _buildDetailRow('Address',
                order['customer']?['deliveryAddress']?['fullAddress'] ?? 'N/A'),
          ]),

          SizedBox(height: 16.h),

          // Order Metrics
          _buildDetailSection('Order Details', [
            _buildDetailRow('Total Value',
                '\$${order['orderMetrics']?['totalValue'] ?? 0}'),
            _buildDetailRow(
                'Items', '${order['orderMetrics']?['totalItems'] ?? 0}'),
            _buildDetailRow(
                'Payment Status', order['paymentDetails']?['status'] ?? 'N/A'),
            _buildDetailRow(
                'Urgency', order['orderStatus']?['urgencyLevel'] ?? 'N/A'),
            _buildDetailRow('Order Age',
                order['orderStatus']?['orderAge']?['formatted'] ?? 'N/A'),
          ]),

          SizedBox(height: 16.h),

          // Items
          if (order['items'] != null)
            _buildDetailSection(
              'Items',
              (order['items'] as List)
                  .map<Widget>(
                      (item) => _buildItemRow(item as Map<String, dynamic>))
                  .toList(),
            ),

          SizedBox(height: 16.h),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _focusOnOrder(order),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Focus on Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
            ],
          ),
        ],
      ),
    );
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
          Text(
            'Active Orders (${filteredOrders.length})',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
                Text(
                  'Order #${order['orderId'] ?? 'N/A'}',
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
            Text(
              order['customer']?['personalInfo']?['name'] ?? 'Unknown Customer',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.sp,
                color: Colors.white70,
              ),
            ),
            Text(
              '\$${order['orderMetrics']?['totalValue'] ?? 0} • ${order['orderMetrics']?['totalItems'] ?? 0} items',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.sp,
                color: const Color(0xFF10B981),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Age: ${order['orderStatus']?['orderAge']?['formatted'] ?? 'Unknown'}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.sp,
                color: Colors.white54,
              ),
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

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          if (item['productDetails']?['image'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: Image.network(
                item['productDetails']['image'],
                width: 40.w,
                height: 40.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 40.w,
                  height: 40.h,
                  color: Colors.grey,
                  child: const Icon(Icons.image, color: Colors.white),
                ),
              ),
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'] ?? 'Unknown Product',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Qty: ${item['quantity'] ?? 0} × \$${item['itemPrice'] ?? 0} = \$${item['subtotal'] ?? 0}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.sp,
                    color: Colors.white70,
                  ),
                ),
              ],
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

  void _focusOnOrder(Map<String, dynamic> order) {
    final location = order['locationData']?['deliveryLocation'];
    if (location != null && mapController != null) {
      final lat = location['latitude']?.toDouble();
      final lng = location['longitude']?.toDouble();
      if (lat != null && lng != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
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
                  'Failed to load orders',
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
                // Real-time indicator
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
                          'LIVE TRACKING',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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
                          'ROUTES',
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
                            Container(
                              width: 12.w,
                              height: 2.h,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(1.r),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Delivery → Customer',
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
                              'Admin Location',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 8.sp,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
