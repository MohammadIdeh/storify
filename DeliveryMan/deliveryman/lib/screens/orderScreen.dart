import 'package:deliveryman/widgets/DeliveryCompletionDialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRefresh;

  const OrdersScreen({
    Key? key,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  void _startSingleDelivery(BuildContext context, Order order) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    // Check if order can be started
    if (!order.canStart || order.isInProgress) {
      _showMessage(
          context, 'This order cannot be started at the moment.', true);
      return;
    }

    // Get current location
    final currentPosition = locationService.currentPosition;
    if (currentPosition == null) {
      _showMessage(
          context, 'Unable to get current location. Please enable GPS.', true);
      return;
    }

    try {
      // Clear any existing selection and select this order
      orderService.clearSelection();
      orderService.toggleOrderSelection(order);

      // Start batch delivery with single order (gets Google Directions)
      final result = await orderService.startBatchDelivery(currentPosition);

      if (result.success) {
        // Start location tracking
        locationService.startTracking(order.id);
        // Refresh data
        onRefresh();

        if (context.mounted) {
          _showMessage(context, 'Delivery started successfully!', false);
        }
      } else {
        if (context.mounted) {
          _showMessage(
              context,
              result.errorMessage ??
                  'Failed to start delivery. Please try again.',
              true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'An error occurred: ${e.toString()}', true);
      }
    }
  }

  void _startBatchDelivery(BuildContext context) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    if (orderService.selectedCount == 0) {
      _showMessage(
          context, 'Please select at least one order to start delivery.', true);
      return;
    }

    // Get current location
    final currentPosition = locationService.currentPosition;
    if (currentPosition == null) {
      _showMessage(
          context, 'Unable to get current location. Please enable GPS.', true);
      return;
    }

    // Show confirmation dialog for batch delivery
    final confirmed =
        await _showBatchConfirmationDialog(context, orderService.selectedCount);
    if (!confirmed) return;

    try {
      final result = await orderService.startBatchDelivery(currentPosition);

      if (result.success) {
        // Start location tracking for the first order
        final firstOrderId = result.successfulOrders.first;
        locationService.startTracking(firstOrderId);

        // Refresh data
        onRefresh();

        if (context.mounted) {
          String message = result.successfulOrders.length ==
                  orderService.selectedCount
              ? 'Batch delivery started for ${result.successfulOrders.length} orders with optimized routes!'
              : 'Started ${result.successfulOrders.length} of ${orderService.selectedCount} orders. Some failed to start.';

          _showMessage(context, message, result.failedOrders.isNotEmpty);
        }
      } else {
        if (context.mounted) {
          _showMessage(
              context,
              result.errorMessage ??
                  'Failed to start batch delivery. Please try again.',
              true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'An error occurred: ${e.toString()}', true);
      }
    }
  }

  Future<bool> _showBatchConfirmationDialog(
      BuildContext context, int orderCount) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF304050),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
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
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Start Batch Delivery',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are about to start delivery for $orderCount ${orderCount == 1 ? 'order' : 'orders'}.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: const Color(0xAAFFFFFF),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6941C6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF6941C6).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.route,
                            color: Color(0xFF6941C6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Google Maps will optimize routes for shortest travel time',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xFF6941C6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF6941C6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Real-time traffic data will be considered for accurate ETAs',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xFF6941C6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: const Color(0xAAFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6941C6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Start Delivery',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // For orderScreen.dart - replace _showDeliveryCompletionDialog:
  void _showDeliveryCompletionDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DeliveryCompletionDialog(
        order: order,
        onComplete: (deliveryData) async {
          // Close dialog immediately
          Navigator.of(dialogContext).pop();

          // Store context reference
          final currentContext = context;

          // Show loading indicator
          showDialog(
            context: currentContext,
            barrierDismissible: false,
            builder: (loadingContext) => WillPopScope(
              onWillPop: () async => false,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
                ),
              ),
            ),
          );

          try {
            // Complete delivery
            final orderService =
                Provider.of<OrderService>(currentContext, listen: false);
            final locationService =
                Provider.of<LocationService>(currentContext, listen: false);

            final success = await orderService.completeDelivery(deliveryData);

            // Close loading dialog
            if (currentContext.mounted) {
              Navigator.of(currentContext).pop();
            }

            if (success) {
              if (orderService.activeOrders.length <= 1) {
                locationService.stopTracking();
              }
              onRefresh();

              if (currentContext.mounted) {
                _showMessage(
                    currentContext, 'Order completed successfully!', false);
              }
            } else {
              if (currentContext.mounted) {
                _showMessage(
                    currentContext,
                    orderService.lastError ?? 'Failed to complete delivery',
                    true);
              }
            }
          } catch (e) {
            // Close loading dialog on error
            if (currentContext.mounted) {
              Navigator.of(currentContext).pop();
            }

            if (currentContext.mounted) {
              _showMessage(
                  currentContext, 'An error occurred: ${e.toString()}', true);
            }
          }
        },
        onCancel: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showMessage(BuildContext context, String message, bool isError) {
    if (!context.mounted) return;

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  void _viewOrderDetails(BuildContext context, Order order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        )
        .then((_) => onRefresh());
  }

  Future<void> _refreshOrders(BuildContext context) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    try {
      await orderService.fetchAssignedOrders();
    } catch (e) {
      if (context.mounted) {
        _showMessage(
            context, 'Failed to refresh orders: ${e.toString()}', true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderService>(
      builder: (context, orderService, child) {
        final orders = orderService.assignedOrders;
        final hasError = orderService.lastError != null;
        final availableOrders =
            orders.where((o) => o.canStart && !o.isInProgress).toList();
        final activeOrders = orders.where((o) => o.isInProgress).toList();

        if (isLoading && orders.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
            ),
          );
        }

        // Show error state if there's an error and no orders
        if (hasError && orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF304050),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error Loading Orders',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    orderService.lastError ?? 'An unknown error occurred',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: const Color(0xAAFFFFFF),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomButton(
                        text: 'Retry',
                        onPressed: () {
                          orderService.clearError();
                          onRefresh();
                        },
                        width: 120,
                        backgroundColor: const Color(0xFF6941C6),
                      ),
                      const SizedBox(width: 16),
                      CustomButton(
                        text: 'Clear Error',
                        onPressed: () => orderService.clearError(),
                        width: 120,
                        backgroundColor: const Color(0xFF304050),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Show empty state if no orders
        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF304050),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      size: 64,
                      color: Color(0xFF6941C6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Active Deliveries',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You don\'t have any assigned deliveries at the moment.\nCheck back later for new assignments.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: const Color(0xAAFFFFFF),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Refresh Orders',
                    onPressed: onRefresh,
                    width: 160,
                    backgroundColor: const Color(0xFF6941C6),
                  ),
                ],
              ),
            ),
          );
        }

        // Show orders list
        return RefreshIndicator(
          onRefresh: () => _refreshOrders(context),
          color: const Color(0xFF6941C6),
          backgroundColor: const Color(0xFF304050),
          child: Column(
            children: [
              // Show error banner if there's an error but we have orders
              if (hasError)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          orderService.lastError!,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        onPressed: () => orderService.clearError(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              // Multi-selection header with Google Maps integration note
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF304050),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6941C6).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Statistics row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6941C6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.assignment,
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
                                'Smart Delivery System',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: const Color(0xAAFFFFFF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${orders.length} total • ${availableOrders.length} ready • ${activeOrders.length} active',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Google Maps badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.route,
                                color: Color(0xFF4CAF50),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Google Maps',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  color: const Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Selection mode toggle
                        if (availableOrders.isNotEmpty &&
                            !orderService.hasActiveDeliveries)
                          IconButton(
                            icon: Icon(
                              orderService.isSelectionMode
                                  ? Icons.close
                                  : Icons.checklist,
                              color: orderService.isSelectionMode
                                  ? Colors.redAccent
                                  : const Color(0xFF6941C6),
                            ),
                            onPressed: () => orderService.toggleSelectionMode(),
                            tooltip: orderService.isSelectionMode
                                ? 'Exit Selection'
                                : 'Multi-Select',
                          ),
                      ],
                    ),

                    // Multi-selection controls
                    if (orderService.isSelectionMode) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF6941C6), thickness: 0.5),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected: ${orderService.selectedCount}/5',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    color: const Color(0xAAFFFFFF),
                                  ),
                                ),
                                if (orderService.selectedCount > 0)
                                  Text(
                                    'Real-time route optimization enabled',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (availableOrders.isNotEmpty)
                            TextButton(
                              onPressed: () =>
                                  orderService.selectAllAvailable(),
                              child: Text(
                                'Select All',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: const Color(0xFF6941C6),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (orderService.selectedCount > 0)
                            ElevatedButton(
                              onPressed: () => _startBatchDelivery(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6941C6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.route,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Start ${orderService.selectedCount}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Orders list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderCard(
                        order: order,
                        isSelectionMode: orderService.isSelectionMode,
                        onSelectionChanged: orderService.isSelectionMode
                            ? (selected) =>
                                orderService.toggleOrderSelection(order)
                            : null,
                        onViewDetails: () => _viewOrderDetails(context, order),
                        onStartDelivery: !orderService.isSelectionMode &&
                                order.canStart &&
                                !order.isInProgress &&
                                !orderService.hasActiveDeliveries
                            ? () => _startSingleDelivery(context, order)
                            : null,
                        onMarkAsDelivered: order.isInProgress
                            ? () =>
                                _showDeliveryCompletionDialog(context, order)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
