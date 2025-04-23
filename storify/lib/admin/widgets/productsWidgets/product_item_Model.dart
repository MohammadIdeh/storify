// product_item_Model.dart
class ProductItemInformation {
  final int productId;
  final String image;
  final String name;
  final double costPrice;
  final double sellPrice;
  final int qty;
  final int categoryId;
  final String status;
  final String? barcode;
  final String? warranty;
  final String? prodDate;
  final String? expDate;
  final String? description;
  final dynamic category; // Keep this as dynamic to handle different formats
  final List<dynamic> suppliers;

  ProductItemInformation({
    required this.productId,
    required this.image,
    required this.name,
    required this.costPrice,
    required this.sellPrice,
    required this.qty,
    required this.categoryId,
    required this.category,
    required this.status,
    this.barcode,
    this.warranty,
    this.prodDate,
    this.expDate,
    this.description,
    required this.suppliers,
  });

  // Factory constructor to create from API JSON
  factory ProductItemInformation.fromJson(Map<String, dynamic> json) {
    return ProductItemInformation(
      productId: json['productId'] ?? 0,
      image: json['image'] ?? 'assets/images/image3.png',
      name: json['name'] ?? '',
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellPrice: (json['sellPrice'] ?? 0).toDouble(),
      qty: json['quantity'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
      category: json['category'] ??
          {'categoryName': 'Uncategorized', 'categoryID': 0},
      status: json['status'] ?? 'Inactive',
      barcode: json['barcode'],
      warranty: json['warranty'],
      prodDate: json['prodDate'],
      expDate: json['expDate'],
      description: json['description'],
      suppliers: json['suppliers'] ?? [],
    );
  }

  // Helper to determine availability from status
  bool get availability => status == 'Active';

  // Helper to get category name safely
  String get categoryName {
    try {
      if (category == null) return 'Uncategorized';

      if (category is Map) {
        var name = category['categoryName'];
        return name != null ? name.toString() : 'Uncategorized';
      } else if (category is String) {
        return category;
      }
    } catch (e) {
      print('Error getting categoryName: $e');
    }
    return 'Uncategorized';
  }

  // Create a copy with updated fields
  ProductItemInformation copyWith({
    int? productId,
    String? image,
    String? name,
    double? costPrice,
    double? sellPrice,
    int? qty,
    int? categoryId,
    dynamic category,
    String? status,
    String? barcode,
    String? warranty,
    String? prodDate,
    String? expDate,
    String? description,
    List<dynamic>? suppliers,
  }) {
    return ProductItemInformation(
      productId: productId ?? this.productId,
      image: image ?? this.image,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      qty: qty ?? this.qty,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      status: status ?? this.status,
      barcode: barcode ?? this.barcode,
      warranty: warranty ?? this.warranty,
      prodDate: prodDate ?? this.prodDate,
      expDate: expDate ?? this.expDate,
      description: description ?? this.description,
      suppliers: suppliers ?? this.suppliers,
    );
  }

  // Convert to JSON for API updates
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'costPrice': costPrice,
      'sellPrice': sellPrice,
      'quantity': qty,
      'categoryId': categoryId,
      'status': status,
      'barcode': barcode,
      'warranty': warranty,
      'prodDate': prodDate,
      'expDate': expDate,
      'image': image,
      'description': description,
    };
  }
}

// Category model for dropdown
class Category {
  final int categoryId;
  final String categoryName;

  Category({required this.categoryId, required this.categoryName});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryID'] ?? 0,
      categoryName: json['categoryName'] ?? '',
    );
  }
}
