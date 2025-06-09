// lib/admin/widgets/OrderSupplierWidgets/low_stock_models.dart
import 'dart:convert';

class LowStockResponse {
  final bool success;
  final String message;
  final List<LowStockItem> lowStockItems;
  final int count;
  final LowStockSummary summary;

  LowStockResponse({
    required this.success,
    required this.message,
    required this.lowStockItems,
    required this.count,
    required this.summary,
  });

  factory LowStockResponse.fromJson(Map<String, dynamic> json) {
    return LowStockResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      lowStockItems: (json['data'] as List?)
              ?.map((item) => LowStockItem.fromJson(item))
              .toList() ??
          [],
      count: json['count'] ?? 0,
      summary: LowStockSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class LowStockSummary {
  final int totalLowStockProducts;
  final int itemsWithActiveSuppliers;
  final int itemsFilteredOut;
  final int totalUniqueSuppliers;

  LowStockSummary({
    required this.totalLowStockProducts,
    required this.itemsWithActiveSuppliers,
    required this.itemsFilteredOut,
    required this.totalUniqueSuppliers,
  });

  factory LowStockSummary.fromJson(Map<String, dynamic> json) {
    return LowStockSummary(
      totalLowStockProducts: json['totalLowStockProducts'] ?? 0,
      itemsWithActiveSuppliers: json['itemsWithActiveSuppliers'] ?? 0,
      itemsFilteredOut: json['itemsFilteredOut'] ?? 0,
      totalUniqueSuppliers: json['totalUniqueSuppliers'] ?? 0,
    );
  }
}

class LowStockItem {
  final LowStockProduct product;
  final LastOrder? lastOrder;
  final int stockDeficit;
  final String alertLevel;
  final bool hasActiveSuppliers;
  final int activeSupplierCount;
  final List<LowStockSupplier> suppliers;
  final List<String> supplierNames;
  bool isSelected;
  int? customQuantity; // Custom quantity for this item
  LowStockSupplier? customSupplier; // Custom supplier for this item

  LowStockItem({
    required this.product,
    this.lastOrder,
    required this.stockDeficit,
    required this.alertLevel,
    required this.hasActiveSuppliers,
    required this.activeSupplierCount,
    required this.suppliers,
    required this.supplierNames,
    this.isSelected = false,
    this.customQuantity,
    this.customSupplier,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      product: LowStockProduct.fromJson(json),
      lastOrder: json['lastOrder'] != null
          ? LastOrder.fromJson(json['lastOrder'])
          : null,
      stockDeficit: json['stockDeficit'] ?? 0,
      alertLevel: json['alertLevel'] ?? 'LOW',
      hasActiveSuppliers: json['hasActiveSuppliers'] ?? false,
      activeSupplierCount: json['activeSupplierCount'] ?? 0,
      suppliers: (json['suppliers'] as List?)
              ?.map((supplier) => LowStockSupplier.fromJson(supplier))
              .toList() ??
          [],
      supplierNames: (json['supplierNames'] as List?)
              ?.map((name) => name.toString())
              .toList() ??
          [],
      isSelected: false,
    );
  }

  LowStockItem copyWith({
    LowStockProduct? product,
    LastOrder? lastOrder,
    int? stockDeficit,
    String? alertLevel,
    bool? hasActiveSuppliers,
    int? activeSupplierCount,
    List<LowStockSupplier>? suppliers,
    List<String>? supplierNames,
    bool? isSelected,
    int? customQuantity,
    LowStockSupplier? customSupplier,
  }) {
    return LowStockItem(
      product: product ?? this.product,
      lastOrder: lastOrder ?? this.lastOrder,
      stockDeficit: stockDeficit ?? this.stockDeficit,
      alertLevel: alertLevel ?? this.alertLevel,
      hasActiveSuppliers: hasActiveSuppliers ?? this.hasActiveSuppliers,
      activeSupplierCount: activeSupplierCount ?? this.activeSupplierCount,
      suppliers: suppliers ?? this.suppliers,
      supplierNames: supplierNames ?? this.supplierNames,
      isSelected: isSelected ?? this.isSelected,
      customQuantity: customQuantity ?? this.customQuantity,
      customSupplier: customSupplier ?? this.customSupplier,
    );
  }

  // Get the effective quantity (custom or default based on deficit)
  int get effectiveQuantity => customQuantity ?? stockDeficit;

  // Get the effective supplier (custom or default from last order or first supplier)
  LowStockSupplier? get effectiveSupplier {
    if (customSupplier != null) {
      return customSupplier;
    }

    // Try to find supplier from last order
    if (lastOrder != null && suppliers.isNotEmpty) {
      try {
        return suppliers.firstWhere(
          (supplier) => supplier.supplierName == lastOrder!.supplierName,
        );
      } catch (e) {
        // If not found, return first supplier
        return suppliers.isNotEmpty ? suppliers.first : null;
      }
    }

    // Return first supplier if available
    return suppliers.isNotEmpty ? suppliers.first : null;
  }
}

class LowStockProduct {
  final int productId;
  final String name;
  final int quantity;
  final int lowStock;
  final String category;

  LowStockProduct({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.lowStock,
    required this.category,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      productId: json['productId'] ?? 0,
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      lowStock: json['lowStock'] ?? 0,
      category: json['category'] ?? '',
    );
  }
}

class LowStockSupplier {
  final int supplierId;
  final String supplierName;
  final String supplierEmail;
  final String supplierPhone;
  final double priceSupplier;
  final String relationshipStatus;

  LowStockSupplier({
    required this.supplierId,
    required this.supplierName,
    required this.supplierEmail,
    required this.supplierPhone,
    required this.priceSupplier,
    required this.relationshipStatus,
  });

  factory LowStockSupplier.fromJson(Map<String, dynamic> json) {
    return LowStockSupplier(
      supplierId: json['supplierId'] ?? 0,
      supplierName: json['supplierName'] ?? '',
      supplierEmail: json['supplierEmail'] ?? '',
      supplierPhone: json['supplierPhone'] ?? '',
      priceSupplier: (json['priceSupplier'] as num?)?.toDouble() ?? 0.0,
      relationshipStatus: json['relationshipStatus'] ?? 'Active',
    );
  }

  // Add equality operator and hashCode for dropdown comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LowStockSupplier &&
          runtimeType == other.runtimeType &&
          supplierId == other.supplierId;

  @override
  int get hashCode => supplierId.hashCode;

  @override
  String toString() =>
      'LowStockSupplier(id: $supplierId, name: $supplierName, email: $supplierEmail, status: $relationshipStatus)';
}

class LastOrder {
  final int orderId;
  final int quantity;
  final double costPrice;
  final String orderDate;
  final String orderStatus;
  final String supplierName;
  final int daysSinceLastOrder;

  LastOrder({
    required this.orderId,
    required this.quantity,
    required this.costPrice,
    required this.orderDate,
    required this.orderStatus,
    required this.supplierName,
    required this.daysSinceLastOrder,
  });

  factory LastOrder.fromJson(Map<String, dynamic> json) {
    return LastOrder(
      orderId: json['orderId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      orderDate: json['orderDate'] ?? '',
      orderStatus: json['orderStatus'] ?? '',
      supplierName: json['supplierName'] ?? '',
      daysSinceLastOrder: json['daysSinceLastOrder'] ?? 0,
    );
  }
}

// Keep existing models for backward compatibility and other API calls
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
