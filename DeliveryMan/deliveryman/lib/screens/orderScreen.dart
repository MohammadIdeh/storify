import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  void _startDelivery(BuildContext context, Order order) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    final success =
        await orderService.updateOrderStatus(order.id, OrderStatus.inProgress);

    if (success) {
      // Start location tracking
      locationService.startTracking(order.id);
      // Refresh data
      onRefresh();
    }
  }

  void _markAsDelivered(BuildContext context, Order order) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    final success =
        await orderService.updateOrderStatus(order.id, OrderStatus.delivered);

    if (success) {
      // Stop location tracking
      locationService.stopTracking();
      // Refresh data
      onRefresh();

      if (context.mounted) {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context);
    final orders = orderService.assignedOrders;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
        ),
      );
    }

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
                'You don\'t have any active deliveries at the moment.\nCheck back later for new assignments.',
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

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF6941C6),
      backgroundColor: const Color(0xFF304050),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OrderCard(
              order: order,
              onViewDetails: () => _viewOrderDetails(context, order),
              onStartDelivery: order.status == OrderStatus.accepted
                  ? () => _startDelivery(context, order)
                  : null,
              onMarkAsDelivered: order.status == OrderStatus.inProgress
                  ? () => _markAsDelivered(context, order)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
