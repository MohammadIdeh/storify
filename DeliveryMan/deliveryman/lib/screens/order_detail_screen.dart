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

  // Check if this order can be started individually
  bool _canStartIndividually(OrderService orderService) {
    // If there's an active batch delivery and this order is not part of it, disable
    if (orderService.isBatchDeliveryActive) {
      // Check if this order is part of the active batch
      bool isInActiveBatch = orderService.activeRoutes
          .any((route) => route.order.id == widget.order.id);
      return isInActiveBatch;
    }

    // If there are active orders but this isn't one of them, it can't be started
    if (orderService.hasActiveDeliveries) {
      return widget.order.isInProgress;
    }

    // Otherwise, use the default canStart logic
    return widget.order.canStart && !widget.order.isInProgress;
  }

  // Get the reason why the order cannot be started
  String _getDisabledReason(OrderService orderService) {
    if (orderService.isBatchDeliveryActive) {
      bool isInActiveBatch = orderService.activeRoutes
          .any((route) => route.order.id == widget.order.id);
      if (!isInActiveBatch) {
        return 'This order is not part of the active batch delivery';
      }
    }

    if (orderService.hasActiveDeliveries && !widget.order.isInProgress) {
      return 'Complete current deliveries before starting new ones';
    }

    if (!widget.order.canStart) {
      return 'Order is not ready to be started';
    }

    return 'Order cannot be started at this time';
  }

  // Build batch status panel
  Widget _buildBatchStatusPanel(OrderService orderService) {
    if (!orderService.isBatchDeliveryActive) return const SizedBox.shrink();

    final activeRoutes = orderService.activeRoutes;
    final currentOrderInBatch =
        activeRoutes.any((route) => route.order.id == widget.order.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            currentOrderInBatch
                ? const Color(0xFF4CAF50).withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            currentOrderInBatch
                ? const Color(0xFF4CAF50).withOpacity(0.05)
                : Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentOrderInBatch
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
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
                  color: currentOrderInBatch
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  currentOrderInBatch ? Icons.check_circle : Icons.warning,
                  color: currentOrderInBatch
                      ? const Color(0xFF4CAF50)
                      : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Delivery Status',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentOrderInBatch
                          ? 'This order is part of the active batch'
                          : 'This order is NOT in the active batch',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: currentOrderInBatch
                            ? const Color(0xFF4CAF50)
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6941C6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${activeRoutes.length} in batch',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: const Color(0xFF6941C6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!currentOrderInBatch) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete the current batch delivery before starting individual orders',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (currentOrderInBatch) ...[
            const SizedBox(height: 12),
            // Show position in batch
            Builder(
              builder: (context) {
                final routeIndex = activeRoutes
                    .indexWhere((route) => route.order.id == widget.order.id);
                if (routeIndex == -1) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: activeRoutes[routeIndex].routeColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${routeIndex + 1}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivery position ${routeIndex + 1} of ${activeRoutes.length}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.order.isInProgress)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ACTIVE',
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
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderService>(
      builder: (context, orderService, child) {
        final canStartIndividually = _canStartIndividually(orderService);
        final disabledReason = _getDisabledReason(orderService);
        final showBatchPanel = orderService.isBatchDeliveryActive ||
            orderService.hasActiveDeliveries;

        return Scaffold(
          backgroundColor: const Color(0xFF1D2939), // background color
          appBar: AppBar(
            scrolledUnderElevation: 0,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    target:
                        LatLng(widget.order.latitude, widget.order.longitude),
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
                      // Batch status panel
                      if (showBatchPanel) _buildBatchStatusPanel(orderService),

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
                                  '\$${widget.order.totalCost.toStringAsFixed(2)}',
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
                          _buildDetailItem(
                              'Phone Number',
                              widget.order.customer.user.phoneNumber,
                              Icons.phone_outlined),
                          _buildDetailItem('Delivery Address',
                              widget.order.address, Icons.location_on_outlined),
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
                            'Assigned Time',
                            DateFormat('MMM dd, yyyy - hh:mm a')
                                .format(widget.order.assignedAt),
                            Icons.assignment_turned_in,
                          ),
                          _buildDetailItem(
                            'Total Amount',
                            '\$${widget.order.totalCost.toStringAsFixed(2)}',
                            Icons.attach_money,
                          ),
                          if (widget.order.discount > 0)
                            _buildDetailItem(
                              'Discount',
                              '\$${widget.order.discount.toStringAsFixed(2)}',
                              Icons.local_offer,
                            ),
                          _buildDetailItem(
                            'Estimated Delivery Time',
                            '${widget.order.estimatedDeliveryTime} minutes',
                            Icons.schedule,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Order Items
                      _buildSection(
                        'Order Items (${widget.order.items.length})',
                        Icons.shopping_bag,
                        [
                          ...widget.order.items
                              .map((item) => _buildOrderItem(item))
                              .toList(),
                        ],
                      ),

                      if (widget.order.note != null &&
                          widget.order.note!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          'Order Notes',
                          Icons.note_alt,
                          [
                            _buildDetailItem('Notes', widget.order.note!,
                                Icons.note_outlined),
                          ],
                        ),
                      ],

                      if (widget.order.deliveryNotes != null &&
                          widget.order.deliveryNotes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          'Delivery Notes',
                          Icons.delivery_dining,
                          [
                            _buildDetailItem(
                                'Delivery Notes',
                                widget.order.deliveryNotes!,
                                Icons.note_outlined),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action buttons with batch awareness
                      if (widget.order.canStart ||
                          widget.order.isInProgress) ...[
                        // Show disabled reason if applicable
                        if (!canStartIndividually &&
                            widget.order.canStart &&
                            !widget.order.isInProgress) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.block,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cannot Start Individually',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        disabledReason,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        CustomButton(
                          text: widget.order.canStart &&
                                  !widget.order.isInProgress
                              ? 'Start Delivery'
                              : 'Mark as Delivered',
                          onPressed: _isUpdatingStatus || !canStartIndividually
                              ? () {} // Empty function for disabled state
                              : widget.order.canStart &&
                                      !widget.order.isInProgress
                                  ? () => _startDelivery()
                                  : () => _markAsDelivered(),
                          isLoading: _isUpdatingStatus,
                          backgroundColor: !canStartIndividually &&
                                  widget.order.canStart &&
                                  !widget.order.isInProgress
                              ? Colors.grey.withOpacity(0.5) // Disabled state
                              : widget.order.canStart &&
                                      !widget.order.isInProgress
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
      },
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF6941C6).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF304050),
            ),
            child: item.product.image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag,
                    color: Colors.white54,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xAAFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${item.subtotal.toStringAsFixed(2)}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: const Color(0xFF4CAF50),
              fontWeight: FontWeight.w600,
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
      case OrderStatus.assigned:
        color = const Color(0xFF6941C6);
        label = 'Assigned';
        icon = Icons.assignment;
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
