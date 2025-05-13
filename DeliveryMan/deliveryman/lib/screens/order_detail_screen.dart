import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../utils/constants.dart';
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
            color: AppColors.primary,
            width: 5,
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
      Navigator.of(context).pop(); // Return to home screen
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update order status'),
          backgroundColor: AppColors.error,
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
        const SnackBar(
          content: Text('Order marked as delivered'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(); // Return to home screen
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update order status'),
          backgroundColor: AppColors.error,
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
      appBar: AppBar(
        title: Text('Order #${widget.order.id}'),
      ),
      body: Column(
        children: [
          // Map showing the delivery location
          SizedBox(
            height: 300,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and order ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${widget.order.id}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      _buildStatusChip(widget.order.status),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Customer information
                  _buildSectionTitle('Customer Information'),
                  _buildInfoRow(
                    Icons.person,
                    'Name',
                    widget.order.customerName,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on,
                    'Address',
                    widget.order.address,
                  ),
                  const SizedBox(height: 16),

                  // Order information
                  _buildSectionTitle('Order Information'),
                  _buildInfoRow(
                    Icons.access_time,
                    'Order Time',
                    DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(widget.order.createdAt),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.attach_money,
                    'Amount',
                    '\$${widget.order.amount.toStringAsFixed(2)}',
                  ),

                  if (widget.order.notes != null &&
                      widget.order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Additional Notes'),
                    _buildInfoRow(
                      Icons.note,
                      'Notes',
                      widget.order.notes!,
                    ),
                  ],

                  const SizedBox(height: 32),

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
                      isLoading:
                          _isUpdatingStatus, // This will control the visual loading state
                      backgroundColor:
                          widget.order.status == OrderStatus.accepted
                              ? AppColors.primary
                              : AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.white70,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.grey;
        label = 'Pending';
        break;
      case OrderStatus.accepted:
        color = Colors.blue;
        label = 'Accepted';
        break;
      case OrderStatus.inProgress:
        color = Colors.orange;
        label = 'In Progress';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        label = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
