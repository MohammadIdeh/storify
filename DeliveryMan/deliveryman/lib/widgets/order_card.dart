import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../utils/constants.dart';
import 'custom_button.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onViewDetails;
  final VoidCallback? onStartDelivery;
  final VoidCallback? onMarkAsDelivered;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onViewDetails,
    this.onStartDelivery,
    this.onMarkAsDelivered,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Customer', order.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Delivery Address', order.address),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Order Time',
              DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.attach_money,
              'Amount',
              '\$${order.amount.toStringAsFixed(2)}',
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.note, 'Notes', order.notes!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'View Details',
                    onPressed: onViewDetails,
                    backgroundColor: AppColors.secondary,
                  ),
                ),
                if (order.status == OrderStatus.accepted &&
                    onStartDelivery != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Start Delivery',
                      onPressed: onStartDelivery!,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
                if (order.status == OrderStatus.inProgress &&
                    onMarkAsDelivered != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Mark Delivered',
                      onPressed: onMarkAsDelivered!,
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ],
              ],
            ),
          ],
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
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
