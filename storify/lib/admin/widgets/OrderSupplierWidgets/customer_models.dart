// lib/admin/widgets/OrderSupplierWidgets/customer_models.dart
import 'dart:convert';

class Customer {
  final int id;
  final String address;
  final String latitude;
  final String longitude;
  final String accountBalance;
  final int orderCount;
  final CustomerUser user;

  Customer({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.accountBalance,
    required this.orderCount,
    required this.user,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      address: json['address'] ?? 'No address',
      latitude: json['latitude'] ?? '0.0',
      longitude: json['longitude'] ?? '0.0',
      accountBalance: json['accountBalance'] ?? '0.00',
      orderCount: json['orderCount'] ?? 0,
      user: CustomerUser.fromJson(json['user']),
    );
  }
}

class CustomerUser {
  final int userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String isActive;
  final String registrationDate;
  final String? profilePicture;

  CustomerUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
    required this.registrationDate,
    this.profilePicture,
  });

  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    return CustomerUser(
      userId: json['userId'],
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? 'No email',
      phoneNumber: json['phoneNumber'] ?? 'No phone',
      isActive: json['isActive'] ?? 'Unknown',
      registrationDate: json['registrationDate'] ?? '',
      profilePicture: json['profilePicture'],
    );
  }
}

class CustomerOrderHistory {
  final String message;
  final Customer customer;
  final List<CustomerOrder> orders;

  CustomerOrderHistory({
    required this.message,
    required this.customer,
    required this.orders,
  });

  factory CustomerOrderHistory.fromJson(Map<String, dynamic> json) {
    return CustomerOrderHistory(
      message: json['message'] ?? '',
      customer: Customer.fromJson(json['customer']),
      orders: (json['orders'] as List?)
              ?.map((order) => CustomerOrder.fromJson(order))
              .toList() ??
          [],
    );
  }
}

class CustomerOrder {
  final int id;
  final int customerId;
  final String status;
  final String? paymentMethod;
  final double totalCost;
  final double discount;
  final double amountPaid;
  final String? note;
  final String? preparationStartedAt;
  final String? preparationCompletedAt;
  final String? deliveryStartTime;
  final String? deliveryEndTime;
  final String? cancelledAt;
  final String? cancellationReason;
  final String createdAt;
  final String updatedAt;
  final List<CustomerOrderItem> items;
  final CustomerOrderEmployee? deliveryEmployee;
  final CustomerUser? cancelledByUser;

  CustomerOrder({
    required this.id,
    required this.customerId,
    required this.status,
    this.paymentMethod,
    required this.totalCost,
    required this.discount,
    required this.amountPaid,
    this.note,
    this.preparationStartedAt,
    this.preparationCompletedAt,
    this.deliveryStartTime,
    this.deliveryEndTime,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.deliveryEmployee,
    this.cancelledByUser,
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
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

    return CustomerOrder(
      id: json['id'],
      customerId: json['customerId'],
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      totalCost: totalCost,
      discount: discount,
      amountPaid: amountPaid,
      note: json['note'],
      preparationStartedAt: json['preparationStartedAt'],
      preparationCompletedAt: json['preparationCompletedAt'],
      deliveryStartTime: json['deliveryStartTime'],
      deliveryEndTime: json['deliveryEndTime'],
      cancelledAt: json['cancelledAt'],
      cancellationReason: json['cancellationReason'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      items: (json['items'] as List?)
              ?.map((item) => CustomerOrderItem.fromJson(item))
              .toList() ??
          [],
      deliveryEmployee: json['deliveryEmployee'] != null
          ? CustomerOrderEmployee.fromJson(json['deliveryEmployee'])
          : null,
      cancelledByUser: json['cancelledByUser'] != null
          ? CustomerUser.fromJson(json['cancelledByUser'])
          : null,
    );
  }

  String get formattedDate {
    try {
      final DateTime date = DateTime.parse(createdAt);
      return "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return createdAt;
    }
  }
}

class CustomerOrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final double subtotal;
  final String createdAt;
  final String updatedAt;
  final CustomerOrderProduct product;
  final List<CustomerOrderBatchDetail> batchDetails;

  CustomerOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
    required this.batchDetails,
  });

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) {
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

    return CustomerOrderItem(
      id: json['id'],
      orderId: json['orderId'],
      productId: json['productId'],
      quantity: json['quantity'],
      price: price,
      subtotal: subtotal,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      product: CustomerOrderProduct.fromJson(json['product']),
      batchDetails: (json['batchDetails'] as List?)
              ?.map((batch) => CustomerOrderBatchDetail.fromJson(batch))
              .toList() ??
          [],
    );
  }
}

class CustomerOrderProduct {
  final int productId;
  final String name;
  final String? image;
  final String? description;
  final double sellPrice;

  CustomerOrderProduct({
    required this.productId,
    required this.name,
    this.image,
    this.description,
    required this.sellPrice,
  });

  factory CustomerOrderProduct.fromJson(Map<String, dynamic> json) {
    double sellPrice = 0.0;
    if (json['sellPrice'] != null) {
      sellPrice = json['sellPrice'] is num
          ? (json['sellPrice'] as num).toDouble()
          : double.tryParse(json['sellPrice'].toString()) ?? 0.0;
    }

    return CustomerOrderProduct(
      productId: json['productId'],
      name: json['name'] ?? 'Unknown Product',
      image: json['image'],
      description: json['description'],
      sellPrice: sellPrice,
    );
  }
}

class CustomerOrderBatchDetail {
  final int batchId;
  final String? batchNumber;
  final int quantity;
  final String prodDate;
  final String expDate;

  CustomerOrderBatchDetail({
    required this.batchId,
    this.batchNumber,
    required this.quantity,
    required this.prodDate,
    required this.expDate,
  });

  factory CustomerOrderBatchDetail.fromJson(Map<String, dynamic> json) {
    return CustomerOrderBatchDetail(
      batchId: json['batchId'],
      batchNumber: json['batchNumber'],
      quantity: json['quantity'],
      prodDate: json['prodDate'],
      expDate: json['expDate'],
    );
  }
}

class CustomerOrderEmployee {
  final int id;
  final int userId;
  final String? currentLatitude;
  final String? currentLongitude;
  final bool isAvailable;
  final String? lastLocationUpdate;
  final String createdAt;
  final String updatedAt;
  final CustomerUser user;

  CustomerOrderEmployee({
    required this.id,
    required this.userId,
    this.currentLatitude,
    this.currentLongitude,
    required this.isAvailable,
    this.lastLocationUpdate,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory CustomerOrderEmployee.fromJson(Map<String, dynamic> json) {
    return CustomerOrderEmployee(
      id: json['id'],
      userId: json['userId'],
      currentLatitude: json['currentLatitude'],
      currentLongitude: json['currentLongitude'],
      isAvailable: json['isAvailable'] ?? false,
      lastLocationUpdate: json['lastLocationUpdate'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      user: CustomerUser.fromJson(json['user']),
    );
  }
}

class CustomersResponse {
  final String message;
  final List<Customer> customers;

  CustomersResponse({
    required this.message,
    required this.customers,
  });

  factory CustomersResponse.fromJson(Map<String, dynamic> json) {
    return CustomersResponse(
      message: json['message'] ?? '',
      customers: (json['customers'] as List?)
              ?.map((customer) => Customer.fromJson(customer))
              .toList() ??
          [],
    );
  }
}
