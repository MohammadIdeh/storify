import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Product model for the table
class ProductModel {
  final int productId;
  final String name;
  final String image;
  final double costPrice;
  final double sellPrice;

  final String categoryName;
  final bool availability;

  ProductModel({
    required this.productId,
    required this.name,
    required this.image,
    required this.costPrice,
    required this.sellPrice,
    required this.categoryName,
    required this.availability,
  });
}

class ProductsTableSupplier extends StatefulWidget {
  final int selectedFilterIndex; // 0: All, 1: Active, 2: Not Active
  final String searchQuery;

  const ProductsTableSupplier({
    super.key,
    required this.selectedFilterIndex,
    required this.searchQuery,
  });

  @override
  State<ProductsTableSupplier> createState() => _ProductsTableSupplierState();
}

class _ProductsTableSupplierState extends State<ProductsTableSupplier> {
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;

  int _currentPage = 1;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final int _itemsPerPage = 9;

  @override
  void initState() {
    super.initState();
    // Instead of fetching, load fake data
    _loadFakeData();
  }

  void _loadFakeData() {
    // Simulate loading delay
    Future.delayed(const Duration(seconds: 1), () {
      _allProducts = [
        ProductModel(
          productId: 1001,
          name: "Premium T-Shirt",
          image: "https://picsum.photos/200",
          costPrice: 15.99,
          sellPrice: 29.99,
          categoryName: "Clothing",
          availability: true,
        ),
        ProductModel(
          productId: 1002,
          name: "Wireless Headphones",
          image: "https://picsum.photos/201",
          costPrice: 45.50,
          sellPrice: 89.99,
          categoryName: "Electronics",
          availability: true,
        ),
        ProductModel(
          productId: 1003,
          name: "Ceramic Coffee Mug",
          image: "https://picsum.photos/202",
          costPrice: 4.25,
          sellPrice: 12.99,
          categoryName: "Kitchenware",
          availability: false,
        ),
        ProductModel(
          productId: 1004,
          name: "Leather Wallet",
          image: "https://picsum.photos/203",
          costPrice: 18.75,
          sellPrice: 39.99,
          categoryName: "Accessories",
          availability: true,
        ),
        ProductModel(
          productId: 1005,
          name: "Fitness Tracker",
          image: "https://picsum.photos/204",
          costPrice: 35.00,
          sellPrice: 79.99,
          categoryName: "Electronics",
          availability: true,
        ),
        ProductModel(
          productId: 1006,
          name: "Stainless Water Bottle",
          image: "https://picsum.photos/205",
          costPrice: 8.50,
          sellPrice: 24.99,
          categoryName: "Kitchenware",
          availability: false,
        ),
        ProductModel(
          productId: 1007,
          name: "Cotton Hoodie",
          image: "https://picsum.photos/206",
          costPrice: 22.99,
          sellPrice: 49.99,
          categoryName: "Clothing",
          availability: true,
        ),
        ProductModel(
          productId: 1008,
          name: "Bluetooth Speaker",
          image: "https://picsum.photos/207",
          costPrice: 32.50,
          sellPrice: 69.99,
          categoryName: "Electronics",
          availability: true,
        ),
        ProductModel(
          productId: 1009,
          name: "Smartphone Case",
          image: "https://picsum.photos/208",
          costPrice: 5.99,
          sellPrice: 19.99,
          categoryName: "Accessories",
          availability: true,
        ),
        ProductModel(
          productId: 1010,
          name: "Canvas Backpack",
          image: "https://picsum.photos/209",
          costPrice: 25.00,
          sellPrice: 54.99,
          categoryName: "Accessories",
          availability: false,
        ),
        ProductModel(
          productId: 1011,
          name: "Yoga Mat",
          image: "https://picsum.photos/210",
          costPrice: 12.75,
          sellPrice: 29.99,
          categoryName: "Fitness",
          availability: true,
        ),
        ProductModel(
          productId: 1012,
          name: "Desk Lamp",
          image: "https://picsum.photos/211",
          costPrice: 15.25,
          sellPrice: 34.99,
          categoryName: "Home Decor",
          availability: true,
        ),
      ];

      setState(() {
        _isLoading = false;
      });
    });
  }

  /// Returns filtered, searched, and sorted products.
  List<ProductModel> get filteredProducts {
    List<ProductModel> temp = List.from(_allProducts);
    // Filter by availability.
    if (widget.selectedFilterIndex == 1) {
      temp = temp.where((p) => p.availability).toList();
    } else if (widget.selectedFilterIndex == 2) {
      temp = temp.where((p) => !p.availability).toList();
    }
    // Search by name (case-insensitive, starts with).
    if (widget.searchQuery.isNotEmpty) {
      temp = temp
          .where((p) =>
              p.name.toLowerCase().startsWith(widget.searchQuery.toLowerCase()))
          .toList();
    }
    // Apply sorting if set
    if (_sortColumnIndex != null) {
      if (_sortColumnIndex == 1) {
        temp.sort((a, b) => a.costPrice.compareTo(b.costPrice));
      } else if (_sortColumnIndex == 2) {
        temp.sort((a, b) => a.sellPrice.compareTo(b.sellPrice));
      }
      if (!_sortAscending) {
        temp = temp.reversed.toList();
      }
    }
    return temp;
  }

  /// Helper: builds a header label with a sort arrow.
  Widget _buildSortableColumnLabel(String label, int colIndex) {
    bool isSorted = _sortColumnIndex == colIndex;
    Widget arrow = SizedBox.shrink();
    if (isSorted) {
      arrow = Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 14.sp,
        color: Colors.white,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(width: 4.w),
        arrow,
      ],
    );
  }

  /// Called when a sortable header is tapped.
  void _onSort(int colIndex) {
    setState(() {
      if (_sortColumnIndex == colIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = colIndex;
        _sortAscending = true;
      }
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color.fromARGB(255, 105, 65, 198),
        ),
      );
    }

    final totalItems = filteredProducts.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > totalItems
        ? totalItems
        : startIndex + _itemsPerPage;
    final visibleProducts = filteredProducts.sublist(startIndex, endIndex);

    // Heading row color
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    // Divider and border color/thickness
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          clipBehavior:
              Clip.antiAlias, // Ensures rounded corners clip child content
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
          ),
          width: constraints.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wrap DataTable in horizontal SingleChildScrollView.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) => Colors.transparent,
                    ),
                    showCheckboxColumn: false,
                    headingRowColor:
                        MaterialStateProperty.all<Color>(headingColor),
                    border: TableBorder(
                      top: dividerSide,
                      bottom: dividerSide,
                      left: dividerSide,
                      right: dividerSide,
                      horizontalInside: dividerSide2,
                      verticalInside: dividerSide2,
                    ),
                    columnSpacing: 20.w,
                    dividerThickness: 0,
                    headingTextStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13.sp,
                    ),
                    columns: [
                      // ID Column
                      const DataColumn(label: Text("ID")),
                      // Image & Name Column
                      const DataColumn(label: Text("Image & Name")),
                      // Cost Price Column (sortable)
                      DataColumn(
                        label: _buildSortableColumnLabel("Cost Price", 1),
                        onSort: (columnIndex, _) {
                          _onSort(1);
                        },
                      ),
                      // Sell Price Column (sortable)
                      DataColumn(
                        label: _buildSortableColumnLabel("Sell Price", 2),
                        onSort: (columnIndex, _) {
                          _onSort(2);
                        },
                      ),
                      // Qty Column (sortable)

                      // Category Column
                      const DataColumn(label: Text("Category")),
                      // Availability Column
                      const DataColumn(label: Text("Availability")),
                      // Actions Column (Edit, Delete)
                      const DataColumn(label: Text("Actions")),
                    ],
                    rows: visibleProducts.map((product) {
                      return DataRow(
                        onSelectChanged: (selected) {
                          if (selected == true) {
                            // For now just show a snackbar to indicate row was clicked
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Product ${product.name} selected'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        cells: [
                          // ID cell
                          DataCell(Text("${product.productId}")),
                          // Image & Name cell
                          DataCell(
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.network(
                                    product.image,
                                    width: 50.w,
                                    height: 50.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 50.w,
                                        height: 50.h,
                                        color: Colors.grey.shade800,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white70,
                                          size: 24.sp,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    product.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Cost Price cell
                          DataCell(Text(
                              "\$${product.costPrice.toStringAsFixed(2)}")),
                          // Sell Price cell
                          DataCell(Text(
                              "\$${product.sellPrice.toStringAsFixed(2)}")),
                          // Qty cell

                          // Category cell
                          DataCell(Text(product.categoryName)),
                          // Availability cell
                          DataCell(
                            _buildAvailabilityPill(product.availability),
                          ),
                          // Actions cell
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 20.sp,
                                  ),
                                  onPressed: () {
                                    // Show edit dialog/page
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Edit ${product.name}'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20.sp,
                                  ),
                                  onPressed: () {
                                    // Show delete confirmation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Delete ${product.name}'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Pagination row
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                child: Row(
                  children: [
                    Spacer(),
                    Text(
                      "Total $totalItems items",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Left arrow
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          size: 20.sp, color: Colors.white70),
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                          : null,
                    ),
                    Row(
                      children: List.generate(totalPages, (index) {
                        return _buildPageButton(index + 1);
                      }),
                    ),
                    // Right arrow
                    IconButton(
                      icon: Icon(Icons.arrow_forward,
                          size: 20.sp, color: Colors.white70),
                      onPressed: _currentPage < totalPages
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Availability pill.
  Widget _buildAvailabilityPill(bool isActive) {
    final Color bgColor = isActive
        ? const Color.fromARGB(178, 0, 224, 116) // green
        : const Color.fromARGB(255, 229, 62, 62); // red
    final String label = isActive ? "Active" : "Not Active";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: bgColor,
        ),
      ),
    );
  }

  /// Pagination button builder.
  Widget _buildPageButton(int pageIndex) {
    final bool isSelected = (pageIndex == _currentPage);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color.fromARGB(255, 105, 65, 198)
              : Colors.transparent,
          side: BorderSide(
            color: const Color.fromARGB(255, 34, 53, 62),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        ),
        onPressed: () {
          setState(() {
            _currentPage = pageIndex;
          });
        },
        child: Text(
          "$pageIndex",
          style: GoogleFonts.spaceGrotesk(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
