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

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isMapInitialized = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMap() {
    if (!_isMapInitialized || !mounted) return;

    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final currentOrder = orderService.currentOrder;
    final currentPosition = locationService.currentPosition;
    final activeRoutes = orderService.activeRoutes;

    setState(() {
      _markers = {};
      _polylines = {};

      // Add marker for delivery person's current location
      if (currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position:
                LatLng(currentPosition.latitude, currentPosition.longitude),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'Delivery person current position',
            ),
          ),
        );
      }

      // Add markers for all assigned orders with different colors based on status
      final assignedOrders = orderService.assignedOrders;
      for (final order in assignedOrders) {
        _markers.add(
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

      // Add polylines for active routes (using Google Directions real roads)
      if (activeRoutes.isNotEmpty) {
        for (int i = 0; i < activeRoutes.length; i++) {
          final route = activeRoutes[i];
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route_${route.order.id}'),
              color: route.routeColor,
              width: 5,
              points:
                  route.routePoints, // Real road points from Google Directions
              // No patterns for solid lines
            ),
          );
        }

        // Fit all active routes on map
        _fitActiveRoutesOnMap(activeRoutes, currentPosition);
      } else if (currentOrder != null && currentPosition != null) {
        // Single order route - still use Google Directions if available
        _addSingleOrderRoute(currentOrder, currentPosition);
      } else if (currentPosition != null) {
        // Only current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(currentPosition.latitude, currentPosition.longitude),
            15,
          ),
        );
      } else if (currentOrder != null) {
        // Only destination
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(currentOrder.latitude, currentOrder.longitude),
            15,
          ),
        );
      }
    });
  }

  void _addSingleOrderRoute(Order order, Position currentPosition) {
    // For single orders, create a simple polyline
    // In a real implementation, you could also call Google Directions here
    _polylines.add(
      Polyline(
        polylineId: PolylineId('route_${order.id}'),
        color: const Color(0xFF6941C6),
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        points: [
          LatLng(currentPosition.latitude, currentPosition.longitude),
          LatLng(order.latitude, order.longitude),
        ],
      ),
    );

    // Show both current location and destination
    _fitTwoPointsOnMap(
      currentPosition.latitude,
      currentPosition.longitude,
      order.latitude,
      order.longitude,
    );
  }

  void _fitActiveRoutesOnMap(
      List<RouteInfo> routes, Position? currentPosition) {
    if (routes.isEmpty) return;

    List<LatLng> allPoints = [];

    // Add current position if available
    if (currentPosition != null) {
      allPoints
          .add(LatLng(currentPosition.latitude, currentPosition.longitude));
    }

    // Add all route points
    for (final route in routes) {
      allPoints.addAll(route.routePoints);
    }

    if (allPoints.length < 2) return;

    // Calculate bounds
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

    // Add padding
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
      _updateMap();
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

          // Show loading
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

          // Close loading dialog
          if (context.mounted) {
            Navigator.of(context).pop();
          }

          if (success) {
            // Stop tracking if no more active orders
            if (orderService.activeOrders.length <= 1) {
              locationService.stopTracking();
            }
            widget.onRefresh();
            _updateMap();

            if (context.mounted) {
              _showMessage('Order completed successfully!', false);
            }
          } else {
            if (context.mounted) {
              _showMessage(
                  orderService.lastError ?? 'Failed to complete delivery',
                  true);
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

    // Calculate total time and distance
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
                      'Batch Delivery Active',
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
            ],
          ),
          const SizedBox(height: 12),
          // Route legend with time estimates
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
    return Consumer2<LocationService, OrderService>(
      builder: (context, locationService, orderService, child) {
        final currentOrder = orderService.currentOrder;
        final assignedOrders = orderService.assignedOrders;
        final isBatchActive = orderService.isBatchDeliveryActive;

        // Update map when orders change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateMap();
        });

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
                    : const LatLng(
                        31.9539, 35.9106), // Default to Amman, Jordan
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
              mapToolbarEnabled: false,
              zoomControlsEnabled: true,
              // IMPORTANT: Enable map interaction
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
            ),

            // Batch delivery panel (when active)
            if (isBatchActive)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildBatchDeliveryPanel(orderService),
              ),

            // Orders overview panel at the top (when not in batch mode)
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
                      if (orderService.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF6941C6)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Current order info overlay at the bottom
            if (currentOrder != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 100, // Account for bottom nav
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

            // No active order overlay
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
