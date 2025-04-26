// lib/models/order_model.dart
class Order {
  final int id;
  final int supplierId;
  final String status;
  final String? note;
  final double totalAmount;
  final String createdAt;
  final String updatedAt;
  final List<OrderProduct> products;
  final String? deliveryAddress;
  final String? paymentMethod;

  // Computed properties
  String get orderId => "ORD-${id.toString().padLeft(3, '0')}";
  int get totalProducts => products.length;
  double get subtotal => totalAmount;
  double get deliveryFee => 0.0; // Could be calculated or from API
  String get orderDate => _formatDate(createdAt);


  Order({
    required this.id,
    required this.supplierId,
    required this.status,
    this.note,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.products,
    this.deliveryAddress,
    this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      supplierId: json['supplierId'],
      status: json['status'],
      note: json['note'],
      totalAmount: json['totalCost'].toDouble(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      products: (json['items'] as List)
          .map((item) => OrderProduct.fromJson(item))
          .toList(),
      deliveryAddress: null, // Add if available in API
      paymentMethod: "System Order", // Default or from API
    );
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  static Order? fromOrderItem(Order order) {
    return null;
  }
}

class OrderProduct {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final double originalPrice;
  final double subtotal;
  final String name;
  final String? imageUrl;

  OrderProduct({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.originalPrice,
    required this.subtotal,
    required this.name,
    this.imageUrl,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      id: json['id'],
      orderId: json['orderId'],
      productId: json['productId'],
      quantity: json['quantity'],
      price: json['costPrice'].toDouble(),
      originalPrice: json['originalCostPrice'].toDouble(),
      subtotal: json['subtotal'].toDouble(),
      name: json['product']?['name'] ?? "Product #${json['productId']}",
      imageUrl: json['product']?['image'],
    );
  }

  double get totalPrice => quantity * price;
}