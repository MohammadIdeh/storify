class Category {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String status;
  final String image;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.status,
    required this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['categoryID'],
      name: json['categoryName'],
      slug: json['slug'],
      description: json['description'],
      status: json['status'],
      image: json['image'],
    );
  }
}

class Product {
  final int id;
  final String name;
  final double sellPrice;
  final double costPrice;
  final int quantity;
  final String image;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.sellPrice,
    required this.costPrice,
    required this.quantity,
    required this.image,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['productId'],
      name: json['name'],
      sellPrice: json['sellPrice'].toDouble(),
      costPrice: json['costPrice'].toDouble(),
      quantity: json['quantity'],
      image: json['image'],
      description: json['description'],
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.sellPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'quantity': quantity,
    };
  }
}

class Order {
  final List<CartItem> items;

  Order({
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
