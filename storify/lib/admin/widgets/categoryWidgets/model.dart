// model.dart
class ProductDetail {
  String image;
  String name;
  double costPrice;
  double sellingPrice;
  double myPrice;

  ProductDetail({
    required this.image,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.myPrice,
  });
}

// category_item.dart
class CategoryItem {
  final String image; // e.g., 'assets/images/image3.png'
  final String name; // e.g., 'Fruits'
  int products; // remove final so it can be updated
  bool isActive; // whether category is enabled or not

  CategoryItem({
    required this.image,
    required this.name,
    required this.products,
    required this.isActive,
  });
}
