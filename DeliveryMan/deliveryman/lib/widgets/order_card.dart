import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'custom_button.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onViewDetails;
  final VoidCallback? onStartDelivery;
  final VoidCallback? onMarkAsDelivered;
  final bool showCompletedBadge;
  final bool? isSelectionMode;
  final ValueChanged<bool>? onSelectionChanged;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onViewDetails,
    this.onStartDelivery,
    this.onMarkAsDelivered,
    this.showCompletedBadge = false,
    this.isSelectionMode,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool showSelection = isSelectionMode == true;
    final bool isSelected = order.isSelected;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Card(
        elevation: 0,
        color: showSelection && isSelected
            ? const Color(0xFF6941C6).withOpacity(0.1)
            : const Color(0xFF304050),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: showSelection && isSelected
                ? const Color(0xFF6941C6)
                : const Color(0xFF6941C6).withOpacity(0.3),
            width: showSelection && isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: showSelection && onSelectionChanged != null
              ? () => onSelectionChanged!(!isSelected)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with order ID, status, and selection checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Selection checkbox
                        if (showSelection) ...[
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6941C6)
                                    : Colors.grey,
                                width: 2,
                              ),
                              color: isSelected
                                  ? const Color(0xFF6941C6)
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6941C6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getOrderIcon(order.status),
                            color: const Color(0xFF6941C6),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
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
                              DateFormat('MMM dd, hh:mm a')
                                  .format(order.createdAt),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xAAFFFFFF),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusChip(order.status),
                        if (showCompletedBadge) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'COMPLETED',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4CAF50),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Customer and delivery info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2939),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6941C6).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.person_outline,
                        'Customer',
                        order.customerName,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Phone',
                        order.customer.user.phoneNumber,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Delivery Address',
                        order.address,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              Icons.attach_money,
                              'Amount',
                              '\$${order.totalCost.toStringAsFixed(2)}',
                              valueColor: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoRow(
                              Icons.shopping_bag,
                              'Items',
                              '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                            ),
                          ),
                        ],
                      ),
                      if (order.estimatedDeliveryTime > 0) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.schedule,
                          'Est. Delivery Time',
                          '${order.estimatedDeliveryTime} minutes',
                        ),
                      ],
                    ],
                  ),
                ),

                // Order Items Preview
                if (order.items.isNotEmpty) ...[
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 16,
                              color: Color(0xFF6941C6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Order Items (${order.items.length})',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xFF6941C6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...order.items.take(3).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: const Color(0xFF304050),
                                    ),
                                    child: item.product.image.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: Image.network(
                                              item.product.image,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white54,
                                                size: 12,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.shopping_bag,
                                            color: Colors.white54,
                                            size: 12,
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.product.name}',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${item.subtotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      color: const Color(0xFF4CAF50),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (order.items.length > 3)
                          Text(
                            '+ ${order.items.length - 3} more items',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              color: const Color(0xAAFFFFFF),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Notes if any
                if (order.note != null && order.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6941C6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6941C6).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: Color(0xFF6941C6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Notes',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: const Color(0xFF6941C6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.note!,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Timing information
                if (order.assignedAt != order.createdAt) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF304050),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6941C6).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xAAFFFFFF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Assigned: ${DateFormat('MMM dd, hh:mm a').format(order.assignedAt)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            color: const Color(0xAAFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons (only show if not in selection mode)
                if (!showSelection)
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'View Details',
                          onPressed: onViewDetails,
                          backgroundColor: const Color(0xFF1D2939),
                        ),
                      ),
                      if (order.canStart &&
                          !order.isInProgress &&
                          onStartDelivery != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Start Delivery',
                            onPressed: onStartDelivery!,
                            backgroundColor: const Color(0xFF6941C6), // primary
                          ),
                        ),
                      ],
                      if (order.isInProgress && onMarkAsDelivered != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Mark Delivered',
                            onPressed: onMarkAsDelivered!,
                            backgroundColor: const Color(0xFF4CAF50), // success
                          ),
                        ),
                      ],
                    ],
                  ),

                // Selection mode info
                if (showSelection)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6941C6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? const Color(0xFF6941C6)
                              : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSelected
                              ? 'Selected for batch delivery'
                              : 'Tap to select',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: isSelected
                                ? const Color(0xFF6941C6)
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6941C6),
        ),
        const SizedBox(width: 8),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getOrderIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.assigned:
        return Icons.assignment;
      case OrderStatus.inProgress:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}
