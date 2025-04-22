// category_products_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/categoryWidgets/ProductDetailCard.dart'; // Updated full path
import 'package:storify/admin/widgets/categoryWidgets/model.dart'; // Contains ProductDetail

// In category_products_row.dart, update the class parameters:
class CategoryProductsRow extends StatefulWidget {
  final String categoryName;
  final int categoryID;
  final String? description; // Add this line
  final List<ProductDetail> products;
  final VoidCallback? onClose;
  final ValueChanged<ProductDetail> onProductDelete;

  const CategoryProductsRow({
    super.key,
    required this.categoryName,
    required this.categoryID,
    this.description, // Add this parameter
    required this.products,
    this.onClose,
    required this.onProductDelete,
  });

  @override
  State<CategoryProductsRow> createState() => _CategoryProductsRowState();
}

class _CategoryProductsRowState extends State<CategoryProductsRow> {
  String _searchQuery = "";
  List<ProductDetail> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.products;
    }

    final startsWith = <ProductDetail>[];
    final contains = <ProductDetail>[];

    for (final prod in widget.products) {
      final lowerName = prod.name.toLowerCase();
      if (lowerName.startsWith(query)) {
        startsWith.add(prod);
      } else if (lowerName.contains(query)) {
        contains.add(prod);
      }
    }

    // 'startsWith' items first, then 'contains' items.
    return [...startsWith, ...contains];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.description != null &&
                          widget.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            widget.description!,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 40,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: GoogleFonts.spaceGrotesk(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search",
                      hintStyle:
                          GoogleFonts.spaceGrotesk(color: Colors.white70),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 54, 68, 88),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    fixedSize: Size(100.w, 50.h),
                    elevation: 1,
                  ),
                  onPressed: widget.onClose,
                  child: Text(
                    "Close",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.products.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No products in this category",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Products added to this category will appear here",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _filteredProducts
                        .map((prod) => SizedBox(
                              width: 250,
                              // Use a ValueKey based on the product ID or name
                              key: ValueKey(prod.productID ?? prod.name),
                              child: ProductDetailCard(
                                product: prod,
                                categoryID: widget
                                    .categoryID, // Pass categoryID to the product card
                                onUpdate: (updatedProduct) {
                                  // Handle update...
                                  print(
                                      "Updated product: ${updatedProduct.name}");
                                },
                                onDelete: () {
                                  widget.onProductDelete(prod);
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
