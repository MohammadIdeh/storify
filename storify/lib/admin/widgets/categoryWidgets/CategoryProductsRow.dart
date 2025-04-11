// category_products_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ProductDetailCard.dart';
import 'model.dart'; // Contains ProductDetail

class CategoryProductsRow extends StatefulWidget {
  final String categoryName;
  final List<ProductDetail> products;
  final VoidCallback? onClose; // Callback to hide the row.
  final ValueChanged<ProductDetail>
      onProductDelete; // Callback when a product is deleted.

  const CategoryProductsRow({
    super.key,
    required this.categoryName,
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
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.categoryName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          debugPrint(
                              "Filtering: $_searchQuery => ${_filteredProducts.map((p) => p.name).toList()}");
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
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _filteredProducts
                    .map((prod) => SizedBox(
                          width: 250,
                          // Use a ValueKey based on the product name or other unique identifier.
                          key: ValueKey(prod.name),
                          child: ProductDetailCard(
                            product: prod,
                            onUpdate: (updatedProduct) {
                              // Handle update...
                              print("Updated product: ${updatedProduct.name}");
                            },
                            onDelete: () {
                              widget.onProductDelete(prod);
                            },
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
