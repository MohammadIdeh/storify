// lib/models/product_item.dart

class ProductItem {
  final String image; // e.g., 'assets/images/product.png'
  final String name;  // e.g., 'Homedics SoundSleep...'
  final double price; // e.g., 738.35
  final int qty;      // e.g., 4152
  final String category;  // e.g., 'Category'
  final bool availability; // true => Active, false => Inactive

  ProductItem({
    required this.image,
    required this.name,
    required this.price,
    required this.qty,
    required this.category,
    required this.availability,
  });
}
