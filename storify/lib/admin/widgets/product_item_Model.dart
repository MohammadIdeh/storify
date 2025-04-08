// product_item.dart
class ProductItemInformation {
  String image; // This will hold a URL or a base64 string for web.
  String name;
  double price;
  int qty;
  String category;
  bool availability; // true = Active, false = UnActive

  ProductItemInformation({
    required this.image,
    required this.name,
    required this.price,
    required this.qty,
    required this.category,
    required this.availability,
  });
}
