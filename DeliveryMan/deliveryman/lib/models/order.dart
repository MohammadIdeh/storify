enum OrderStatus { pending, assigned, inProgress, delivered, cancelled }

class Customer {
  final int id;
  final String address;
  final double latitude;
  final double longitude;
  final double accountBalance;
  final CustomerUser user;

  Customer({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.accountBalance,
    required this.user,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      address: json['address'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      accountBalance: double.parse(json['accountBalance'].toString()),
      user: CustomerUser.fromJson(json['user']),
    );
  }
}

class CustomerUser {
  final int userId;
  final String name;
  final String phoneNumber;

  CustomerUser({
    required this.userId,
    required this.name,
    required this.phoneNumber,
  });

  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    return CustomerUser(
      userId: json['userId'] as int,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final double subtotal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Product product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      productId: json['productId'] as int,
      quantity: json['quantity'] as int,
      price: double.parse(json['Price'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      product: Product.fromJson(json['product']),
    );
  }
}

class Product {
  final int productId;
  final String name;
  final String image;

  Product({
    required this.productId,
    required this.name,
    required this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] as int,
      name: json['name'] as String,
      image: json['image'] as String,
    );
  }
}

class Order {
  final int id;
  final int customerId;
  final OrderStatus status;
  final String? paymentMethod;
  final double totalCost;
  final double discount;
  final double amountPaid;
  final String? note;
  final int deliveryEmployeeId;
  final int estimatedDeliveryTime;
  final DateTime? deliveryStartTime;
  final DateTime? deliveryEndTime;
  final DateTime assignedAt;
  final String? deliveryDelayReason;
  final String? deliveryNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Customer customer;
  final List<OrderItem> items;
  final bool canStart;
  final bool isInProgress;
  
  // New properties for multi-order delivery
  bool isSelected;
  int? routeIndex; // For color coding on map
  String? routeColor; // Hex color for this order's route

  Order({
    required this.id,
    required this.customerId,
    required this.status,
    this.paymentMethod,
    required this.totalCost,
    required this.discount,
    required this.amountPaid,
    this.note,
    required this.deliveryEmployeeId,
    required this.estimatedDeliveryTime,
    this.deliveryStartTime,
    this.deliveryEndTime,
    required this.assignedAt,
    this.deliveryDelayReason,
    this.deliveryNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.customer,
    required this.items,
    required this.canStart,
    required this.isInProgress,
    this.isSelected = false,
    this.routeIndex,
    this.routeColor,
  });

  // Convenience getters for backward compatibility
  String get customerName => customer.user.name;
  String get address => customer.address;
  double get latitude => customer.latitude;
  double get longitude => customer.longitude;
  double get amount => totalCost;
  String? get notes => note;

  // Create a copy of the order with updated selection state
  Order copyWith({
    bool? isSelected,
    int? routeIndex,
    String? routeColor,
    OrderStatus? status,
    bool? canStart,
    bool? isInProgress,
  }) {
    return Order(
      id: id,
      customerId: customerId,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      totalCost: totalCost,
      discount: discount,
      amountPaid: amountPaid,
      note: note,
      deliveryEmployeeId: deliveryEmployeeId,
      estimatedDeliveryTime: estimatedDeliveryTime,
      deliveryStartTime: deliveryStartTime,
      deliveryEndTime: deliveryEndTime,
      assignedAt: assignedAt,
      deliveryDelayReason: deliveryDelayReason,
      deliveryNotes: deliveryNotes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customer: customer,
      items: items,
      canStart: canStart ?? this.canStart,
      isInProgress: isInProgress ?? this.isInProgress,
      isSelected: isSelected ?? this.isSelected,
      routeIndex: routeIndex ?? this.routeIndex,
      routeColor: routeColor ?? this.routeColor,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      customerId: json['customerId'] as int,
      status: _parseStatus(json['status']),
      paymentMethod: json['paymentMethod'] as String?,
      totalCost: double.parse(json['totalCost'].toString()),
      discount: double.parse(json['discount'].toString()),
      amountPaid: double.parse(json['amountPaid'].toString()),
      note: json['note'] as String?,
      deliveryEmployeeId: json['deliveryEmployeeId'] as int,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] as int,
      deliveryStartTime: json['deliveryStartTime'] != null 
          ? DateTime.parse(json['deliveryStartTime']) 
          : null,
      deliveryEndTime: json['deliveryEndTime'] != null 
          ? DateTime.parse(json['deliveryEndTime']) 
          : null,
      assignedAt: DateTime.parse(json['assignedAt']),
      deliveryDelayReason: json['deliveryDelayReason'] as String?,
      deliveryNotes: json['deliveryNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      customer: Customer.fromJson(json['customer']),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      canStart: json['canStart'] as bool,
      isInProgress: json['isInProgress'] as bool,
    );
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'assigned':
        return OrderStatus.assigned;
      case 'in_progress':
      case 'inprogress':
        return OrderStatus.inProgress;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  // Convert OrderStatus to string for API calls
  static String statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.pending:
      default:
        return 'Pending';
    }
  }
}

// Route optimization and delivery batch management
class DeliveryBatch {
  final List<Order> orders;
  final List<RoutePoint> optimizedRoute;
  final double totalDistance;
  final int estimatedDuration; // in minutes

  DeliveryBatch({
    required this.orders,
    required this.optimizedRoute,
    required this.totalDistance,
    required this.estimatedDuration,
  });
}

class RoutePoint {
  final double latitude;
  final double longitude;
  final Order? order; // null for starting point (delivery person location)
  final int sequenceIndex;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    this.order,
    required this.sequenceIndex,
  });
}

// Predefined route colors for different orders
class RouteColors {
  static const List<String> colors = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#FFA07A', // Light Salmon
    '#98D8C8', // Mint
    '#F7DC6F', // Yellow
    '#BB8FCE', // Purple
    '#85C1E9', // Light Blue
    '#F8C471', // Orange
    '#82E0AA', // Light Green
  ];

  static String getColorForIndex(int index) {
    return colors[index % colors.length];
  }
}