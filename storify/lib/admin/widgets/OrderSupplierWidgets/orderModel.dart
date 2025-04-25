// lib/admin/models/order_model.dart
import 'dart:convert';

class OrderItem {
  final String orderId;
  final String storeName;
  final String phoneNo;
  final String orderDate;
  final int totalProducts;
  final double totalAmount;
  final String status;
  final String? note;
  final int supplierId;
  final List<dynamic> items;

  OrderItem({
    required this.orderId,
    required this.storeName,
    required this.phoneNo,
    required this.orderDate,
    required this.totalProducts,
    required this.totalAmount,
    required this.status,
    this.note,
    required this.supplierId,
    required this.items,
  });

  // Allow modifications such as updating the status.
  OrderItem copyWith({
    String? status,
    String? note,
    double? totalAmount,
  }) {
    return OrderItem(
      orderId: orderId,
      storeName: storeName,
      phoneNo: phoneNo,
      orderDate: orderDate,
      totalProducts: totalProducts,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      note: note ?? this.note,
      supplierId: supplierId,
      items: items,
    );
  }
  
  // Factory method to create an OrderItem from the API response
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Format date from API timestamp (2025-04-22T09:54:25.000Z)
    final DateTime createdDate = DateTime.parse(json['createdAt']);
    final String formattedDate = "${createdDate.day}-${createdDate.month}-${createdDate.year} ${createdDate.hour}:${createdDate.minute}";
    
    // Use the API status directly without mapping
    // The API statuses are: "Accepted", "Delivered", "Declined", "Pending"
    String status = json['status'] ?? 'Unknown';
    
    // Extract total cost
    double totalCost = 0.0;
    if (json['totalCost'] != null) {
      if (json['totalCost'] is num) {
        totalCost = (json['totalCost'] as num).toDouble();
      } else {
        totalCost = double.tryParse(json['totalCost'].toString()) ?? 0.0;
      }
    }
    
    return OrderItem(
      orderId: json['id'].toString(),
      storeName: json['supplier']['user']['name'],
      phoneNo: json['supplier']['user']['phoneNumber'],
      orderDate: formattedDate,
      totalProducts: json['items']?.length ?? 0,
      totalAmount: totalCost,
      status: status,
      note: json['note'],
      supplierId: json['supplierId'],
      items: json['items'] ?? [],
    );
  }
}