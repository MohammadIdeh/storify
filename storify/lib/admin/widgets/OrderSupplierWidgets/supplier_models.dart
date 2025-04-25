// lib/admin/models/supplier_models.dart
import 'dart:convert';

class Supplier {
  final int id;
  final String name;
  final String? email;
  final String? phoneNumber;

  Supplier({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    // Handle simpler format from the supplier/suppliers endpoint
    return Supplier(
      id: json['id'],
      name: json['name'] ?? 'Unknown Supplier',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
    );
  }
}

// Rest of the models remain the same
class SupplierProduct {
  final int productId;
  final String name;
  final double costPrice;
  final double sellPrice;
  final int quantity;
  final String? image;
  final String? description;
  final int supplierId; // Track which supplier this belongs to

  SupplierProduct({
    required this.productId,
    required this.name,
    required this.costPrice,
    required this.sellPrice,
    required this.quantity,
    this.image,
    this.description,
    required this.supplierId,
  });

  factory SupplierProduct.fromJson(Map<String, dynamic> json, int supplierId) {
    // Parse numeric values safely
    double costPrice = 0.0;
    if (json['costPrice'] != null) {
      costPrice = json['costPrice'] is num
          ? (json['costPrice'] as num).toDouble()
          : double.tryParse(json['costPrice'].toString()) ?? 0.0;
    }

    double sellPrice = 0.0;
    if (json['sellPrice'] != null) {
      sellPrice = json['sellPrice'] is num
          ? (json['sellPrice'] as num).toDouble()
          : double.tryParse(json['sellPrice'].toString()) ?? 0.0;
    }

    int quantity = 0;
    if (json['quantity'] != null) {
      quantity = json['quantity'] is num
          ? (json['quantity'] as num).toInt()
          : int.tryParse(json['quantity'].toString()) ?? 0;
    }

    return SupplierProduct(
      productId: json['productId'],
      name: json['name'] ?? 'Unknown Product',
      costPrice: costPrice,
      sellPrice: sellPrice,
      quantity: quantity,
      image: json['image'],
      description: json['description'] ?? '',
      supplierId: supplierId,
    );
  }
}

class CartItem {
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final int supplierId;
  final String supplierName;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    required this.supplierId,
    required this.supplierName,
  });

  CartItem copyWith({
    int? productId,
    String? name,
    double? price,
    int? quantity,
    String? image,
    int? supplierId,
    String? supplierName,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
    );
  }

  double get total => price * quantity;
}

// Order request model
class OrderRequest {
  final int supplierId;
  final List<OrderItem> items;

  OrderRequest({
    required this.supplierId,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderItem {
  final int productId;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}
