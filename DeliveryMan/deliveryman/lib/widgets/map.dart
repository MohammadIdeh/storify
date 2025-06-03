import 'dart:async';
import 'dart:math' as math;

import 'package:deliveryman/screens/order_detail_screen.dart';
import 'package:deliveryman/widgets/DeliveryCompletionDialog.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../widgets/custom_button.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback onRefresh;

  const MapScreen({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isMapInitialized = false;
  Timer? _mapUpdateTimer;

  // Cache for better performance
  Position? _lastKnownPosition;
  List<Order> _lastKnownOrders = [];

  // Route loading states
  bool _isLoadingRoute = false;
  Map<int, bool> _orderRouteLoading = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _mapUpdateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _updateMapIfNeeded();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapUpdateTimer?.cancel();
    super.dispose();
  }

  void _updateMapIfNeeded() {
    if (!_isMapInitialized || !mounted) return;

    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    final currentPosition = locationService.currentPosition;
    final currentOrders = orderService.assignedOrders;

    bool shouldUpdate = false;

    if (currentPosition != _lastKnownPosition) {
      shouldUpdate = true;
      _lastKnownPosition = currentPosition;
    }

    if (currentOrders.length != _lastKnownOrders.length ||
        !_ordersEqual(currentOrders, _lastKnownOrders)) {
      shouldUpdate = true;
      _lastKnownOrders = List.from(currentOrders);
    }

    if (shouldUpdate) {
      _updateMap();
    }
  }

  bool _ordersEqual(List<Order> orders1, List<Order> orders2) {
    if (orders1.length != orders2.length) return false;
    for (int i = 0; i < orders1.length; i++) {
      if (orders1[i].id != orders2[i].id ||
          orders1[i].status != orders2[i].status) {
        return false;
      }
    }
    return true;
  }

  void _updateMap() {
    if (!_isMapInitialized || !mounted) return;

    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final currentOrder = orderService.currentOrder;
    final currentPosition = locationService.currentPosition;
    final activeRoutes = orderService.activeRoutes;

    if (mounted) {
      setState(() {
        _markers = _buildMarkers(currentPosition, orderService.assignedOrders);
        _polylines = _buildPolylines(
            activeRoutes, currentOrder, currentPosition, orderService);
      });

      _updateCameraPosition(activeRoutes, currentOrder, currentPosition);
    }
  }

  Set<Marker> _buildMarkers(Position? currentPosition, List<Order> orders) {
    final markers = <Marker>{};

    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(currentPosition.latitude, currentPosition.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Delivery person current position',
          ),
        ),
      );
    }

    for (final order in orders) {
      markers.add(
        Marker(
          markerId: MarkerId('order_${order.id}'),
          position: LatLng(order.latitude, order.longitude),
          icon: _getMarkerIcon(order),
          infoWindow: InfoWindow(
            title: 'Order #${order.id}',
            snippet:
                '${order.customerName} - \$${order.totalCost.toStringAsFixed(2)}',
          ),
          onTap: () => _showOrderInfoBottomSheet(order),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(
      List<RouteInfo> activeRoutes,
      Order? currentOrder,
      Position? currentPosition,
      OrderService orderService) {
    final polylines = <Polyline>{};

    if (activeRoutes.isNotEmpty) {
      // Use real Google Directions routes for batch delivery
      for (int i = 0; i < activeRoutes.length; i++) {
        final route = activeRoutes[i];
        polylines.add(
          Polyline(
            polylineId: PolylineId('route_${route.order.id}'),
            color: route.routeColor,
            width: 6, // Slightly thicker for visibility
            points:
                route.routePoints, // Real road points from Google Directions
            // NO PATTERNS = Solid line following real roads
          ),
        );
      }
    } else if (currentOrder != null && currentPosition != null) {
      // For single orders, get real route from Google Directions
      _loadSingleOrderRoute(currentOrder, currentPosition, orderService);
    }

    return polylines;
  }

  Future<void> _loadSingleOrderRoute(
      Order order, Position currentPosition, OrderService orderService) async {
    // Avoid multiple simultaneous requests for the same order
    if (_orderRouteLoading[order.id] == true) return;

    setState(() {
      _orderRouteLoading[order.id] = true;
    });

    try {
      final origin =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      final destination = LatLng(order.latitude, order.longitude);

      print('🗺️ Loading real route for Order #${order.id}');

      // Get real route from Google Directions
      final directionsResponse =
          await orderService.getDirectionsFromGoogle(origin, destination);

      if (directionsResponse != null && mounted) {
        setState(() {
          _polylines.removeWhere(
              (polyline) => polyline.polylineId.value == 'route_${order.id}');

          // Add real route polyline
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route_${order.id}'),
              color: const Color(0xFF6941C6),
              width: 5,
              points: directionsResponse.points, // Real road points!
              // NO PATTERNS = Solid line following real roads
            ),
          );
        });

        print(
            '✅ Real route loaded: ${directionsResponse.points.length} points, ${directionsResponse.distanceKm.toStringAsFixed(1)}km');
      } else {
        // Fallback to straight line only if Directions fails
        print('⚠️ Google Directions failed, using straight line');
        if (mounted) {
          setState(() {
            _polylines.removeWhere(
                (polyline) => polyline.polylineId.value == 'route_${order.id}');

            _polylines.add(
              Polyline(
                polylineId: PolylineId('route_${order.id}'),
                color: const Color(0xFF6941C6).withOpacity(0.7),
                width: 4,
                patterns: [
                  PatternItem.dash(15),
                  PatternItem.gap(8)
                ], // Dashed only for fallback
                points: [
                  LatLng(currentPosition.latitude, currentPosition.longitude),
                  LatLng(order.latitude, order.longitude),
                ],
              ),
            );
          });
        }
      }
    } catch (e) {
      print('❌ Error loading route: $e');
    } finally {
      if (mounted) {
        setState(() {
          _orderRouteLoading[order.id] = false;
        });
      }
    }
  }

  void _updateCameraPosition(List<RouteInfo> activeRoutes, Order? currentOrder,
      Position? currentPosition) {
    if (activeRoutes.isNotEmpty) {
      _fitActiveRoutesOnMap(activeRoutes, currentPosition);
    } else if (currentOrder != null && currentPosition != null) {
      _fitTwoPointsOnMap(
        currentPosition.latitude,
        currentPosition.longitude,
        currentOrder.latitude,
        currentOrder.longitude,
      );
    } else if (currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          15,
        ),
      );
    }
  }

  void _fitActiveRoutesOnMap(
      List<RouteInfo> routes, Position? currentPosition) {
    if (routes.isEmpty) return;

    List<LatLng> allPoints = [];

    if (currentPosition != null) {
      allPoints
          .add(LatLng(currentPosition.latitude, currentPosition.longitude));
    }

    for (final route in routes) {
      allPoints.addAll(route.routePoints);
    }

    if (allPoints.length < 2) return;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final point in allPoints) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    const double padding = 0.01;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _fitTwoPointsOnMap(double lat1, double lng1, double lat2, double lng2) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(lat1, lat2) - 0.01,
        math.min(lng1, lng2) - 0.01,
      ),
      northeast: LatLng(
        math.max(lat1, lat2) + 0.01,
        math.max(lng1, lng2) + 0.01,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  BitmapDescriptor _getMarkerIcon(Order order) {
    if (order.isInProgress) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else if (order.canStart) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapInitialized = true;
    _updateMap();
  }

  void _startDelivery(Order order) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    final success =
        await orderService.updateOrderStatus(order.id, OrderStatus.inProgress);

    if (success) {
      locationService.startTracking(order.id);
      widget.onRefresh();
    } else {
      if (!mounted) return;
      _showMessage(orderService.lastError ?? 'Failed to start delivery', true);
    }
  }

  void _showDeliveryCompletionDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeliveryCompletionDialog(
        order: order,
        onComplete: (deliveryData) async {
          Navigator.of(context).pop();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
              ),
            ),
          );

          final orderService =
              Provider.of<OrderService>(context, listen: false);
          final locationService =
              Provider.of<LocationService>(context, listen: false);

          final success = await orderService.completeDelivery(deliveryData);

          if (context.mounted) {
            Navigator.of(context).pop();
          }

          if (success) {
            if (orderService.activeOrders.length <= 1) {
              locationService.stopTracking();
            }
            widget.onRefresh();

            if (context.mounted) {
              _showMessage('Order completed successfully!', false);
            }
          } else {
            if (context.mounted) {
              _showMessage(
                orderService.lastError ?? 'Failed to complete delivery',
                true,
              );
            }
          }
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showMessage(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _viewOrderDetails(Order order) {
    Navigator.of(context)
        .push(
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)))
        .then((_) => widget.onRefresh());
  }

  void _showOrderInfoBottomSheet(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF304050),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6941C6).withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6941C6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF6941C6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        order.customerName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: const Color(0xAAFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildOrderStatusChip(order),
              ],
            ),
            const SizedBox(height: 16),

            // Route status indicator
            if (_orderRouteLoading[order.id] == true)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6941C6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading real route...',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF6941C6),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF6941C6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.address,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: const Color(0xAAFFFFFF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${order.totalCost.toStringAsFixed(2)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xAAFFFFFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'View Details',
                    onPressed: () {
                      Navigator.pop(context);
                      _viewOrderDetails(order);
                    },
                    backgroundColor: const Color(0xFF1D2939),
                  ),
                ),
                const SizedBox(width: 12),
                if (order.canStart && !order.isInProgress)
                  Expanded(
                    child: CustomButton(
                      text: 'Start',
                      onPressed: () {
                        Navigator.pop(context);
                        _startDelivery(order);
                      },
                      backgroundColor: const Color(0xFF6941C6),
                    ),
                  ),
                if (order.isInProgress)
                  Expanded(
                    child: CustomButton(
                      text: 'Complete',
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeliveryCompletionDialog(order);
                      },
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChip(Order order) {
    Color color;
    String label;

    if (order.isInProgress) {
      color = Colors.orange;
      label = 'Active';
    } else if (order.canStart) {
      color = const Color(0xFF6941C6);
      label = 'Ready';
    } else {
      color = Colors.grey;
      label = 'Waiting';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBatchDeliveryPanel(OrderService orderService) {
    final activeRoutes = orderService.activeRoutes;
    if (activeRoutes.isEmpty) return const SizedBox.shrink();

    final totalTime =
        activeRoutes.fold<int>(0, (sum, route) => sum + route.estimatedTime);
    final totalDistance =
        activeRoutes.fold<double>(0, (sum, route) => sum + route.distance);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF304050).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6941C6).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6941C6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.route,
                  color: Color(0xFF6941C6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real Road Routes Active',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${activeRoutes.length} routes • ${totalDistance.toStringAsFixed(1)}km • ~${totalTime}min',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xAAFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              // Google Maps badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Real Roads',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activeRoutes.asMap().entries.map((entry) {
            final index = entry.key;
            final route = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: route.routeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: route.routeColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: route.routeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${route.order.id} - ${route.order.customerName}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${route.distance.toStringAsFixed(1)}km • ~${route.estimatedTime}min',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            color: const Color(0xAAFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (route.order.isInProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'IN PROGRESS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 8,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<LocationService, OrderService>(
      builder: (context, locationService, orderService, child) {
        final currentOrder = orderService.currentOrder;
        final assignedOrders = orderService.assignedOrders;
        final isBatchActive = orderService.isBatchDeliveryActive;

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: locationService.currentPosition != null
                    ? LatLng(
                        locationService.currentPosition!.latitude,
                        locationService.currentPosition!.longitude,
                      )
                    : const LatLng(31.9539, 35.9106),
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
              mapToolbarEnabled: false,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              // Performance optimizations
              compassEnabled: false,
              mapType: MapType.normal,
              trafficEnabled: true, // Enable traffic for better route planning
              buildingsEnabled: false,
              indoorViewEnabled: false,
            ),
            if (isBatchActive)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildBatchDeliveryPanel(orderService),
              ),
            if (assignedOrders.isNotEmpty && !isBatchActive)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF304050).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6941C6).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6941C6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.map,
                          color: Color(0xFF6941C6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Overview',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${assignedOrders.length} orders • ${assignedOrders.where((o) => o.isInProgress).length} active',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingRoute)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6941C6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6941C6)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Loading Route',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  color: const Color(0xFF6941C6),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (currentOrder != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF304050),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6941C6).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6941C6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delivery_dining,
                                color: Color(0xFF6941C6),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBatchActive
                                        ? 'Batch Delivery'
                                        : 'Active Delivery',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      color: const Color(0xAAFFFFFF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    currentOrder.customerName,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: currentOrder.canStart &&
                                        !currentOrder.isInProgress
                                    ? const Color(0xFF6941C6)
                                    : const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                currentOrder.canStart &&
                                        !currentOrder.isInProgress
                                    ? 'Ready'
                                    : 'In Progress',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Color(0xFF6941C6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentOrder.address,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: const Color(0xAAFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'View Details',
                                onPressed: () =>
                                    _viewOrderDetails(currentOrder),
                                backgroundColor: const Color(0xFF1D2939),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: currentOrder.canStart &&
                                        !currentOrder.isInProgress
                                    ? 'Start Delivery'
                                    : 'Complete',
                                onPressed: currentOrder.canStart &&
                                        !currentOrder.isInProgress
                                    ? () => _startDelivery(currentOrder)
                                    : () => _showDeliveryCompletionDialog(
                                        currentOrder),
                                backgroundColor: currentOrder.canStart &&
                                        !currentOrder.isInProgress
                                    ? const Color(0xFF6941C6)
                                    : const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (currentOrder == null && assignedOrders.isEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 120,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF304050),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6941C6).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_searching,
                        color: Color(0xFF6941C6),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Active Deliveries',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        textAlign: TextAlign.center,
                        'Check the Orders tab for new assignments',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: const Color(0xAAFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
