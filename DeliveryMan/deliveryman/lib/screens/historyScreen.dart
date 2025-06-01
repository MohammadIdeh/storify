import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRefresh;

  const HistoryScreen({
    Key? key,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  void _viewOrderDetails(BuildContext context, Order order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        )
        .then((_) => onRefresh());
  }

  Future<void> _refreshHistory(BuildContext context) async {
    final orderService = Provider.of<OrderService>(context, listen: false);
    await orderService.fetchCompletedOrders();
  }

  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context);
    final orders = orderService.completedOrders;

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
                  Icons.history,
                  size: 64,
                  color: Color(0xFF6941C6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Delivery History',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your completed deliveries will appear here.\nStart completing orders to build your history.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: const Color(0xAAFFFFFF),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF304050),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6941C6).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF6941C6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Complete your first delivery!',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: const Color(0xFF6941C6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refreshHistory(context),
      color: const Color(0xFF6941C6),
      backgroundColor: const Color(0xFF304050),
      child: Column(
        children: [
          // Header with stats
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF304050),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6941C6).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6941C6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF6941C6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completed Deliveries',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: const Color(0xAAFFFFFF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${orders.length} ${orders.length == 1 ? 'delivery' : 'deliveries'}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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
                    onViewDetails: () => _viewOrderDetails(context, order),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
