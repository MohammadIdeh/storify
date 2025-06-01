// lib/admin/models/delivery_models.dart
import 'dart:convert';

/// Model for a prepared order from the prepared orders API
class PreparedOrder {
  final int id;
  final int customerId;
  final String status;
  final String? paymentMethod;
  final double totalCost;
  final double discount;
  final double amountPaid;
  final String? note;
  final int? deliveryEmployeeId;
  final String? estimatedDeliveryTime;
  final String? deliveryStartTime;
  final String? deliveryEndTime;
  final String? assignedAt;
  final String? deliveryDelayReason;
  final String? deliveryNotes;
  final String createdAt;
  final String updatedAt;
  final PreparedOrderCustomer customer;
  final List<PreparedOrderItem> items;

  PreparedOrder({
    required this.id,
    required this.customerId,
    required this.status,
    this.paymentMethod,
    required this.totalCost,
    required this.discount,
    required this.amountPaid,
    this.note,
    this.deliveryEmployeeId,
    this.estimatedDeliveryTime,
    this.deliveryStartTime,
    this.deliveryEndTime,
    this.assignedAt,
    this.deliveryDelayReason,
    this.deliveryNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.customer,
    required this.items,
  });

  factory PreparedOrder.fromJson(Map<String, dynamic> json) {
    double totalCost = 0.0;
    if (json['totalCost'] != null) {
      totalCost = json['totalCost'] is num
          ? (json['totalCost'] as num).toDouble()
          : double.tryParse(json['totalCost'].toString()) ?? 0.0;
    }

    double discount = 0.0;
    if (json['discount'] != null) {
      discount = json['discount'] is num
          ? (json['discount'] as num).toDouble()
          : double.tryParse(json['discount'].toString()) ?? 0.0;
    }

    double amountPaid = 0.0;
    if (json['amountPaid'] != null) {
      amountPaid = json['amountPaid'] is num
          ? (json['amountPaid'] as num).toDouble()
          : double.tryParse(json['amountPaid'].toString()) ?? 0.0;
    }

    return PreparedOrder(
      id: json['id'],
      customerId: json['customerId'],
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      totalCost: totalCost,
      discount: discount,
      amountPaid: amountPaid,
      note: json['note'],
      deliveryEmployeeId: json['deliveryEmployeeId'],
      estimatedDeliveryTime: json['estimatedDeliveryTime'],
      deliveryStartTime: json['deliveryStartTime'],
      deliveryEndTime: json['deliveryEndTime'],
      assignedAt: json['assignedAt'],
      deliveryDelayReason: json['deliveryDelayReason'],
      deliveryNotes: json['deliveryNotes'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      customer: PreparedOrderCustomer.fromJson(json['customer']),
      items: (json['items'] as List)
          .map((item) => PreparedOrderItem.fromJson(item))
          .toList(),
    );
  }
}

/// Customer information in prepared order
class PreparedOrderCustomer {
  final int id;
  final String address;
  final String latitude;
  final String longitude;
  final String accountBalance;
  final PreparedOrderUser user;

  PreparedOrderCustomer({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.accountBalance,
    required this.user,
  });

  factory PreparedOrderCustomer.fromJson(Map<String, dynamic> json) {
    return PreparedOrderCustomer(
      id: json['id'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      accountBalance: json['accountBalance'],
      user: PreparedOrderUser.fromJson(json['user']),
    );
  }
}

/// User information in prepared order customer
class PreparedOrderUser {
  final int userId;
  final String name;
  final String phoneNumber;

  PreparedOrderUser({
    required this.userId,
    required this.name,
    required this.phoneNumber,
  });

  factory PreparedOrderUser.fromJson(Map<String, dynamic> json) {
    return PreparedOrderUser(
      userId: json['userId'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
    );
  }
}

/// Order item in prepared order
class PreparedOrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final double subtotal;
  final String createdAt;
  final String updatedAt;
  final PreparedOrderProduct product;

  PreparedOrderItem({
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

  factory PreparedOrderItem.fromJson(Map<String, dynamic> json) {
    double price = 0.0;
    if (json['Price'] != null) {
      price = json['Price'] is num
          ? (json['Price'] as num).toDouble()
          : double.tryParse(json['Price'].toString()) ?? 0.0;
    }

    double subtotal = 0.0;
    if (json['subtotal'] != null) {
      subtotal = json['subtotal'] is num
          ? (json['subtotal'] as num).toDouble()
          : double.tryParse(json['subtotal'].toString()) ?? 0.0;
    }

    return PreparedOrderItem(
      id: json['id'],
      orderId: json['orderId'],
      productId: json['productId'],
      quantity: json['quantity'],
      price: price,
      subtotal: subtotal,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      product: PreparedOrderProduct.fromJson(json['product']),
    );
  }
}

/// Product information in prepared order item
class PreparedOrderProduct {
  final int productId;
  final String name;
  final String? image;

  PreparedOrderProduct({
    required this.productId,
    required this.name,
    this.image,
  });

  factory PreparedOrderProduct.fromJson(Map<String, dynamic> json) {
    return PreparedOrderProduct(
      productId: json['productId'],
      name: json['name'],
      image: json['image'],
    );
  }
}

/// Model for delivery employee
class DeliveryEmployee {
  final int id;
  final int userId;
  final bool isAvailable;
  final String? currentLatitude;
  final String? currentLongitude;
  final String? lastLocationUpdate;
  final DeliveryEmployeeUser user;

  DeliveryEmployee({
    required this.id,
    required this.userId,
    required this.isAvailable,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    required this.user,
  });

  factory DeliveryEmployee.fromJson(Map<String, dynamic> json) {
    return DeliveryEmployee(
      id: json['id'],
      userId: json['userId'],
      isAvailable: json['isAvailable'],
      currentLatitude: json['currentLatitude'],
      currentLongitude: json['currentLongitude'],
      lastLocationUpdate: json['lastLocationUpdate'],
      user: DeliveryEmployeeUser.fromJson(json['user']),
    );
  }
}

/// User information for delivery employee
class DeliveryEmployeeUser {
  final int userId;
  final String name;
  final String email;
  final String phoneNumber;

  DeliveryEmployeeUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  factory DeliveryEmployeeUser.fromJson(Map<String, dynamic> json) {
    return DeliveryEmployeeUser(
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
    );
  }
}

/// Request model for assigning orders
class AssignOrdersRequest {
  final int deliveryEmployeeId;
  final List<int> orderIds;
  final int estimatedTime;
  final String? notes;

  AssignOrdersRequest({
    required this.deliveryEmployeeId,
    required this.orderIds,
    required this.estimatedTime,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'deliveryEmployeeId': deliveryEmployeeId,
      'orderIds': orderIds,
      'estimatedTime': estimatedTime,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Response model for assigned orders
class AssignOrdersResponse {
  final String message;
  final List<AssignedOrderInfo> assignedOrders;
  final int deliveryEmployeeId;
  final int estimatedTime;

  AssignOrdersResponse({
    required this.message,
    required this.assignedOrders,
    required this.deliveryEmployeeId,
    required this.estimatedTime,
  });

  factory AssignOrdersResponse.fromJson(Map<String, dynamic> json) {
    return AssignOrdersResponse(
      message: json['message'],
      assignedOrders: (json['assignedOrders'] as List)
          .map((order) => AssignedOrderInfo.fromJson(order))
          .toList(),
      deliveryEmployeeId: json['deliveryEmployeeId'],
      estimatedTime: json['estimatedTime'],
    );
  }
}

/// Individual assigned order info
class AssignedOrderInfo {
  final int orderId;
  final CustomerLocation customerLocation;

  AssignedOrderInfo({
    required this.orderId,
    required this.customerLocation,
  });

  factory AssignedOrderInfo.fromJson(Map<String, dynamic> json) {
    return AssignedOrderInfo(
      orderId: json['orderId'],
      customerLocation: CustomerLocation.fromJson(json['customerLocation']),
    );
  }
}

/// Customer location info
class CustomerLocation {
  final String latitude;
  final String longitude;

  CustomerLocation({
    required this.latitude,
    required this.longitude,
  });

  factory CustomerLocation.fromJson(Map<String, dynamic> json) {
    return CustomerLocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
