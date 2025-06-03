import 'dart:math' as math;

import 'package:deliveryman/screens/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );

        // Move camera to current location if no active order
        if (currentOrder == null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(currentPosition.latitude, currentPosition.longitude),
              15,
            ),
          );
        }
      }

      // Add markers for all assigned orders
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

      // Add route line for current order
      if (currentOrder != null && currentPosition != null) {
        // If we have both current location and destination, show both on map
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                math.min(currentPosition.latitude, currentOrder.latitude) -
                    0.01,
                math.min(currentPosition.longitude, currentOrder.longitude) -
                    0.01,
              ),
              northeast: LatLng(
                math.max(currentPosition.latitude, currentOrder.latitude) +
                    0.01,
                math.max(currentPosition.longitude, currentOrder.longitude) +
                    0.01,
              ),
            ),
            100, // padding
          ),
        );

        // Draw route line
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route_${currentOrder.id}'),
            color: const Color(0xFF6941C6),
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            points: [
              LatLng(currentPosition.latitude, currentPosition.longitude),
              LatLng(currentOrder.latitude, currentOrder.longitude),
            ],
          ),
        );
      } else if (currentOrder != null) {
        // If we only have destination, center on that
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(currentOrder.latitude, currentOrder.longitude),
            15,
          ),
        );
      }
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderService.lastError ?? 'Failed to start delivery',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _markAsDelivered(Order order) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    final success =
        await orderService.updateOrderStatus(order.id, OrderStatus.delivered);

    if (success) {
      locationService.stopTracking();
      widget.onRefresh();
      _updateMap();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order marked as delivered',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderService.lastError ?? 'Failed to mark as delivered',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
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
                        _markAsDelivered(order);
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationService, OrderService>(
      builder: (context, locationService, orderService, child) {
        final currentOrder = orderService.currentOrder;
        final assignedOrders = orderService.assignedOrders;

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
              zoomControlsEnabled: false,
            ),

            // Orders overview panel at the top
            if (assignedOrders.isNotEmpty)
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
                                    'Active Delivery',
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
                                    : 'Mark Delivered',
                                onPressed: currentOrder.canStart &&
                                        !currentOrder.isInProgress
                                    ? () => _startDelivery(currentOrder)
                                    : () => _markAsDelivered(currentOrder),
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
