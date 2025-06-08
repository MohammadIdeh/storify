// lib/admin/widgets/OrderSupplierWidgets/low_stock_models.dart
import 'dart:convert';

class LowStockResponse {
  final String message;
  final List<LowStockItem> lowStockItems;

  LowStockResponse({
    required this.message,
    required this.lowStockItems,
  });

  factory LowStockResponse.fromJson(Map<String, dynamic> json) {
    return LowStockResponse(
      message: json['message'] ?? '',
      lowStockItems: (json['lowStockItems'] as List?)
              ?.map((item) => LowStockItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class LowStockItem {
  final LowStockProduct product;
  final LastOrder? lastOrder;
  final int stockDeficit;
  final String alertLevel;
  bool isSelected;
  int? customQuantity; // Custom quantity for this item
  SupplierInfo? customSupplier; // Custom supplier for this item

  LowStockItem({
    required this.product,
    this.lastOrder,
    required this.stockDeficit,
    required this.alertLevel,
    this.isSelected = false,
    this.customQuantity,
    this.customSupplier,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      product: LowStockProduct.fromJson(json['product']),
      lastOrder: json['lastOrder'] != null
          ? LastOrder.fromJson(json['lastOrder'])
          : null,
      stockDeficit: json['stockDeficit'] ?? 0,
      alertLevel: json['alertLevel'] ?? 'LOW',
      isSelected: false,
    );
  }

  LowStockItem copyWith({
    LowStockProduct? product,
    LastOrder? lastOrder,
    int? stockDeficit,
    String? alertLevel,
    bool? isSelected,
    int? customQuantity,
    SupplierInfo? customSupplier,
  }) {
    return LowStockItem(
      product: product ?? this.product,
      lastOrder: lastOrder ?? this.lastOrder,
      stockDeficit: stockDeficit ?? this.stockDeficit,
      alertLevel: alertLevel ?? this.alertLevel,
      isSelected: isSelected ?? this.isSelected,
      customQuantity: customQuantity ?? this.customQuantity,
      customSupplier: customSupplier ?? this.customSupplier,
    );
  }

  // Get the effective quantity (custom or default based on deficit)
  int get effectiveQuantity => customQuantity ?? stockDeficit;

  // Get the effective supplier (custom or default from last order)
  SupplierInfo? get effectiveSupplier =>
      customSupplier ??
      (lastOrder != null
          ? SupplierInfo(
              id: lastOrder!.supplier.id,
              name: lastOrder!.supplier.user.name,
              email: lastOrder!.supplier.user.email,
            )
          : null);
}

class LowStockProduct {
  final int productId;
  final String name;
  final int quantity;
  final int lowStock;
  final double costPrice;
  final double sellPrice;
  final String? image;
  final ProductCategory category;

  LowStockProduct({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.lowStock,
    required this.costPrice,
    required this.sellPrice,
    this.image,
    required this.category,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      productId: json['productId'] ?? 0,
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      lowStock: json['lowStock'] ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (json['sellPrice'] as num?)?.toDouble() ?? 0.0,
      image: json['image'],
      category: ProductCategory.fromJson(json['category'] ?? {}),
    );
  }
}

class ProductCategory {
  final int categoryID;
  final String categoryName;

  ProductCategory({
    required this.categoryID,
    required this.categoryName,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      categoryID: json['categoryID'] ?? 0,
      categoryName: json['categoryName'] ?? '',
    );
  }
}

class LastOrder {
  final int orderId;
  final String orderDate;
  final int quantity;
  final double costPrice;
  final String status;
  final OrderSupplier supplier;

  LastOrder({
    required this.orderId,
    required this.orderDate,
    required this.quantity,
    required this.costPrice,
    required this.status,
    required this.supplier,
  });

  factory LastOrder.fromJson(Map<String, dynamic> json) {
    return LastOrder(
      orderId: json['orderId'] ?? 0,
      orderDate: json['orderDate'] ?? '',
      quantity: json['quantity'] ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      supplier: OrderSupplier.fromJson(json['supplier'] ?? {}),
    );
  }
}

class OrderSupplier {
  final int id;
  final int userId;
  final String accountBalance;
  final SupplierUser user;

  OrderSupplier({
    required this.id,
    required this.userId,
    required this.accountBalance,
    required this.user,
  });

  factory OrderSupplier.fromJson(Map<String, dynamic> json) {
    return OrderSupplier(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      accountBalance: json['accountBalance'] ?? '0.00',
      user: SupplierUser.fromJson(json['user'] ?? {}),
    );
  }
}

class SupplierUser {
  final int userId;
  final String name;
  final String email;

  SupplierUser({
    required this.userId,
    required this.name,
    required this.email,
  });

  factory SupplierUser.fromJson(Map<String, dynamic> json) {
    return SupplierUser(
      userId: json['userId'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

// Product suppliers response models
class ProductSuppliersResponse {
  final String message;
  final ProductInfo product;
  final List<SupplierInfo> suppliers;

  ProductSuppliersResponse({
    required this.message,
    required this.product,
    required this.suppliers,
  });

  factory ProductSuppliersResponse.fromJson(Map<String, dynamic> json) {
    return ProductSuppliersResponse(
      message: json['message'] ?? '',
      product: ProductInfo.fromJson(json['product'] ?? {}),
      suppliers: (json['suppliers'] as List?)
              ?.map((supplier) => SupplierInfo.fromJson(supplier))
              .toList() ??
          [],
    );
  }
}

class ProductInfo {
  final int id;
  final String name;

  ProductInfo({
    required this.id,
    required this.name,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class SupplierInfo {
  final int id;
  final String name;
  final String email;

  SupplierInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  factory SupplierInfo.fromJson(Map<String, dynamic> json) {
    return SupplierInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  // Add equality operator and hashCode for dropdown comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SupplierInfo(id: $id, name: $name, email: $email)';
}

// Generate orders request models
class GenerateOrdersRequest {
  final List<int>? selectedProductIds;
  final bool selectAll;
  final Map<String, int>? customQuantities; // Product ID -> Custom Quantity
  final int? customSupplierId; // Single supplier for ALL items
  final Map<String, int>? customSuppliers; // Product ID -> Custom Supplier ID

  GenerateOrdersRequest({
    this.selectedProductIds,
    required this.selectAll,
    this.customQuantities,
    this.customSupplierId,
    this.customSuppliers,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (selectAll) {
      json['selectAll'] = true;
      // Add custom quantities if provided
      if (customQuantities != null && customQuantities!.isNotEmpty) {
        json['customQuantities'] = customQuantities;
      }
      // Add custom supplier for all if provided
      if (customSupplierId != null) {
        json['customSupplierId'] = customSupplierId;
      }
      // Add custom suppliers mapping if provided
      if (customSuppliers != null && customSuppliers!.isNotEmpty) {
        json['customSuppliers'] = customSuppliers;
      }
    } else {
      json['selectedProductIds'] = selectedProductIds ?? [];
      json['selectAll'] = false;

      // Add custom quantities if provided
      if (customQuantities != null && customQuantities!.isNotEmpty) {
        json['customQuantities'] = customQuantities;
      }
      // Add custom supplier for all if provided
      if (customSupplierId != null) {
        json['customSupplierId'] = customSupplierId;
      }
      // Add custom suppliers mapping if provided
      if (customSuppliers != null && customSuppliers!.isNotEmpty) {
        json['customSuppliers'] = customSuppliers;
      }
    }

    return json;
  }

  @override
  String toString() {
    return 'GenerateOrdersRequest(selectAll: $selectAll, selectedProductIds: $selectedProductIds, customQuantities: $customQuantities, customSupplierId: $customSupplierId, customSuppliers: $customSuppliers)';
  }
}

class GenerateOrdersResponse {
  final String message;
  final Map<String, dynamic>? data;

  GenerateOrdersResponse({
    required this.message,
    this.data,
  });

  factory GenerateOrdersResponse.fromJson(Map<String, dynamic> json) {
    return GenerateOrdersResponse(
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}
