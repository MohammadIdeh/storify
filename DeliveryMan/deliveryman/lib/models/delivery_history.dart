// lib/models/delivery_history.dart

class DeliveryHistoryStats {
  final int totalDeliveries;
  final double totalRevenue;
  final int avgDeliveryTime;

  DeliveryHistoryStats({
    required this.totalDeliveries,
    required this.totalRevenue,
    required this.avgDeliveryTime,
  });

  factory DeliveryHistoryStats.fromJson(Map<String, dynamic> json) {
    return DeliveryHistoryStats(
      totalDeliveries: json['totalDeliveries'] as int,
      totalRevenue: double.parse(json['totalRevenue'].toString()),
      avgDeliveryTime: json['avgDeliveryTime'] as int,
    );
  }
}

class DeliveryHistoryOrder {
  final int id;
  final String status;
  final double totalCost;
  final double discount;

  DeliveryHistoryOrder({
    required this.id,
    required this.status,
    required this.totalCost,
    required this.discount,
  });

  factory DeliveryHistoryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryHistoryOrder(
      id: json['id'] as int,
      status: json['status'] as String,
      totalCost: double.parse(json['totalCost'].toString()),
      discount: double.parse(json['discount'].toString()),
    );
  }
}

class DeliveryHistoryCustomer {
  final int id;
  final String address;
  final String name;
  final String phoneNumber;

  DeliveryHistoryCustomer({
    required this.id,
    required this.address,
    required this.name,
    required this.phoneNumber,
  });

  factory DeliveryHistoryCustomer.fromJson(Map<String, dynamic> json) {
    return DeliveryHistoryCustomer(
      id: json['id'] as int,
      address: json['address'] as String,
      name: json['user']['name'] as String,
      phoneNumber: json['user']['phoneNumber'] as String,
    );
  }
}

class DeliveryHistoryItem {
  final int id;
  final int deliveryEmployeeId;
  final int orderId;
  final int customerId;
  final DateTime assignedTime;
  final DateTime startTime;
  final DateTime endTime;
  final int estimatedTime;
  final int actualTime;
  final String paymentMethod;
  final double totalAmount;
  final double amountPaid;
  final double debtAmount;
  final String deliveryNotes;
  final double customerLatitude;
  final double customerLongitude;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeliveryHistoryOrder order;
  final DeliveryHistoryCustomer customer;

  DeliveryHistoryItem({
    required this.id,
    required this.deliveryEmployeeId,
    required this.orderId,
    required this.customerId,
    required this.assignedTime,
    required this.startTime,
    required this.endTime,
    required this.estimatedTime,
    required this.actualTime,
    required this.paymentMethod,
    required this.totalAmount,
    required this.amountPaid,
    required this.debtAmount,
    required this.deliveryNotes,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.order,
    required this.customer,
  });

  // Convenience getters
  Duration get deliveryDuration => endTime.difference(startTime);
  bool get wasOnTime => actualTime <= estimatedTime;
  double get timeDifferenceMinutes => (actualTime - estimatedTime).toDouble();
  bool get wasFullyPaid => amountPaid >= totalAmount;
  double get efficiency =>
      estimatedTime > 0 ? (estimatedTime / actualTime) * 100 : 100;

  factory DeliveryHistoryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryHistoryItem(
      id: json['id'] as int,
      deliveryEmployeeId: json['deliveryEmployeeId'] as int,
      orderId: json['orderId'] as int,
      customerId: json['customerId'] as int,
      assignedTime: DateTime.parse(json['assignedTime']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      estimatedTime: json['estimatedTime'] as int,
      actualTime: json['actualTime'] as int,
      paymentMethod: json['paymentMethod'] as String,
      totalAmount: double.parse(json['totalAmount'].toString()),
      amountPaid: double.parse(json['amountPaid'].toString()),
      debtAmount: double.parse(json['debtAmount'].toString()),
      deliveryNotes: json['deliveryNotes'] as String,
      customerLatitude: double.parse(json['customerLatitude'].toString()),
      customerLongitude: double.parse(json['customerLongitude'].toString()),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      order: DeliveryHistoryOrder.fromJson(json['order']),
      customer: DeliveryHistoryCustomer.fromJson(json['customer']),
    );
  }
}

class DeliveryHistoryResponse {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final DeliveryHistoryStats stats;
  final List<DeliveryHistoryItem> deliveries;

  DeliveryHistoryResponse({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.stats,
    required this.deliveries,
  });

  factory DeliveryHistoryResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryHistoryResponse(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
      stats: DeliveryHistoryStats.fromJson(json['stats']),
      deliveries: (json['deliveries'] as List<dynamic>)
          .map((delivery) => DeliveryHistoryItem.fromJson(delivery))
          .toList(),
    );
  }
}
