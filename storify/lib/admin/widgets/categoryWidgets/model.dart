// model.dart with field name correction
class ProductDetail {
  final dynamic productID; // Store any ID type
  String image;
  String name;
  double costPrice;
  double sellingPrice;

  ProductDetail({
    this.productID,
    required this.image,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
  });

  // Factory constructor to create from API JSON response
  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    // Verbose debugging to track the exact shape of JSON we're receiving
    print('=== ProductDetail.fromJson called with: ===');
    json.forEach((key, value) {
      print(' $key: $value (${value?.runtimeType})');
    });

    // The crucial fix: Check for 'productId' (lowercase 'i') which is the field name in your API
    // Also check other common ID formats as fallbacks
    dynamic id;
    String idSource = 'none';

    if (json.containsKey('productId')) {
      // <-- This is the key fix - lowercase 'i'
      id = json['productId'];
      idSource = 'productId';
    } else if (json.containsKey('productID')) {
      id = json['productID'];
      idSource = 'productID';
    } else if (json.containsKey('_id')) {
      id = json['_id'];
      idSource = '_id';
    } else if (json.containsKey('id')) {
      id = json['id'];
      idSource = 'id';
    } else if (json.containsKey('product_id')) {
      id = json['product_id'];
      idSource = 'product_id';
    }

    print(
        'Extracted productID: $id (${id?.runtimeType}) from field: $idSource');

    return ProductDetail(
      productID: id,
      image: json['image'] ?? 'assets/images/image3.png',
      name: json['name'] ?? json['productName'] ?? 'Unknown Product',
      costPrice: _parseDouble(json['costPrice'] ?? json['cost'] ?? 0),
      sellingPrice: _parseDouble(json['sellPrice'] ?? json['price'] ?? 0),
    );
  }

  // Helper to parse numeric values from API which might be strings or numbers
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  String toString() {
    return 'ProductDetail(id: $productID, name: $name)';
  }
}

class CategoryItem {
  final int categoryID;
  final String categoryName;
  final String slug;
  final String description;
  late final String status; // "Active" or "NotActive"
  final String image;
  int products; // This isn't part of the API response, but we'll keep it

  CategoryItem({
    required this.categoryID,
    required this.categoryName,
    required this.slug,
    required this.description,
    required this.status,
    required this.image,
    this.products = 0, // Default to 0 products since API doesn't provide this
  });

  // Helper getter to convert status string to bool for the UI
  bool get isActive => status == "Active";

  // Factory constructor to create from JSON
  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      categoryID: json['categoryID'],
      categoryName: json['categoryName'],
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      status: json['status'],
      image: json['image'],
    );
  }
}
