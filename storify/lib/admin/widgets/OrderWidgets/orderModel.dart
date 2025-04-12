// lib/admin/models/order_model.dart
class OrderItem {
  final String orderId;
  final String storeName;
  final String phoneNo;
  final String orderDate; // e.g. "12-7-2024 22:16"
  final int totalProducts;
  final double totalAmount;
  final String status; // e.g. "Awaiting", "Accepted", "Declined"

  OrderItem({
    required this.orderId,
    required this.storeName,
    required this.phoneNo,
    required this.orderDate,
    required this.totalProducts,
    required this.totalAmount,
    required this.status,
  });

  // Allow modifications such as updating the status.
  OrderItem copyWith({String? status}) {
    return OrderItem(
      orderId: orderId,
      storeName: storeName,
      phoneNo: phoneNo,
      orderDate: orderDate,
      totalProducts: totalProducts,
      totalAmount: totalAmount,
      status: status ?? this.status,
    );
  }
}
