import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../widgets/custom_button.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isUpdatingStatus = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMap();
  }

  void _updateMap() {
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final currentPosition = locationService.currentPosition;

    setState(() {
      _markers = {};

      // Add marker for delivery destination
      _markers.add(
        Marker(
          markerId: MarkerId('order_${widget.order.id}'),
          position: LatLng(widget.order.latitude, widget.order.longitude),
          infoWindow: InfoWindow(
            title: 'Delivery to ${widget.order.customerName}',
            snippet: widget.order.address,
          ),
        ),
      );

      // Add marker for current location if available
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

        // Draw a polyline between current location and destination
        _polylines = {
          Polyline(
            polylineId: PolylineId('route_${widget.order.id}'),
            color: const Color(0xFF6941C6), // primary color
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            points: [
              LatLng(currentPosition.latitude, currentPosition.longitude),
              LatLng(widget.order.latitude, widget.order.longitude),
            ],
          ),
        };

        // Show both markers
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                math.min(currentPosition.latitude, widget.order.latitude) -
                    0.01,
                math.min(currentPosition.longitude, widget.order.longitude) -
                    0.01,
              ),
              northeast: LatLng(
                math.max(currentPosition.latitude, widget.order.latitude) +
                    0.01,
                math.max(currentPosition.longitude, widget.order.longitude) +
                    0.01,
              ),
            ),
            100, // padding
          ),
        );
      } else {
        // Only show destination marker
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(widget.order.latitude, widget.order.longitude),
            15,
          ),
        );
      }
    });
  }

  Future<void> _startDelivery() async {
    setState(() {
      _isUpdatingStatus = true;
    });

    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    final success = await orderService.updateOrderStatus(
      widget.order.id,
      OrderStatus.inProgress,
    );

    if (success) {
      // Start location tracking
      locationService.startTracking(widget.order.id);

      // Refresh orders
      await orderService.fetchAssignedOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery started successfully!',
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

      Navigator.of(context).pop(); // Return to home screen
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update order status',
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

    if (mounted) {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  Future<void> _markAsDelivered() async {
    setState(() {
      _isUpdatingStatus = true;
    });

    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    final success = await orderService.updateOrderStatus(
      widget.order.id,
      OrderStatus.delivered,
    );

    if (success) {
      // Stop location tracking
      locationService.stopTracking();

      // Refresh orders
      await orderService.fetchAssignedOrders();
      await orderService.fetchCompletedOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order marked as delivered!',
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

      Navigator.of(context).pop(); // Return to home screen
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update order status',
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

    if (mounted) {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D2939), // background color
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF304050), // card color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Order Details',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6941C6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6941C6).withOpacity(0.3),
              ),
            ),
            child: Text(
              '#${widget.order.id}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6941C6),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map showing the delivery location
          Container(
            height: 280,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6941C6).withOpacity(0.3),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.order.latitude, widget.order.longitude),
                zoom: 15,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),

          // Order details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and order info header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF304050),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6941C6).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Status',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusChip(widget.order.status),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Amount',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${widget.order.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer information
                  _buildSection(
                    'Customer Information',
                    Icons.person,
                    [
                      _buildDetailItem('Customer Name',
                          widget.order.customerName, Icons.person_outline),
                      _buildDetailItem('Delivery Address', widget.order.address,
                          Icons.location_on_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Order information
                  _buildSection(
                    'Order Information',
                    Icons.receipt_long,
                    [
                      _buildDetailItem(
                        'Order Time',
                        DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(widget.order.createdAt),
                        Icons.access_time,
                      ),
                      _buildDetailItem(
                        'Order Amount',
                        '\$${widget.order.amount.toStringAsFixed(2)}',
                        Icons.attach_money,
                      ),
                    ],
                  ),

                  if (widget.order.notes != null &&
                      widget.order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      'Additional Notes',
                      Icons.note_alt,
                      [
                        _buildDetailItem('Special Instructions',
                            widget.order.notes!, Icons.note_outlined),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  if (widget.order.status == OrderStatus.accepted ||
                      widget.order.status == OrderStatus.inProgress) ...[
                    CustomButton(
                      text: widget.order.status == OrderStatus.accepted
                          ? 'Start Delivery'
                          : 'Mark as Delivered',
                      onPressed: _isUpdatingStatus
                          ? () {} // Empty function instead of null
                          : widget.order.status == OrderStatus.accepted
                              ? () => _startDelivery()
                              : () => _markAsDelivered(),
                      isLoading: _isUpdatingStatus,
                      backgroundColor:
                          widget.order.status == OrderStatus.accepted
                              ? const Color(0xFF6941C6) // primary
                              : const Color(0xFF4CAF50), // success
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF304050),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6941C6).withOpacity(0.3),
        ),
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
                child: Icon(
                  icon,
                  color: const Color(0xFF6941C6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xAAFFFFFF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xAAFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.grey;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case OrderStatus.accepted:
        color = const Color(0xFF6941C6);
        label = 'Accepted';
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.inProgress:
        color = Colors.orange;
        label = 'In Progress';
        icon = Icons.local_shipping;
        break;
      case OrderStatus.delivered:
        color = const Color(0xFF4CAF50);
        label = 'Delivered';
        icon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        color = Colors.redAccent;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
