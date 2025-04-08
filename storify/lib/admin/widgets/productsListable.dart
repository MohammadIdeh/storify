import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/exportPopUp.dart';

class ProductslistTable extends StatefulWidget {
  final int selectedFilterIndex; // 0: All, 1: Active, 2: UnActive
  final String searchQuery;
  const ProductslistTable({
    super.key,
    required this.selectedFilterIndex,
    required this.searchQuery,
  });

  @override
  State<ProductslistTable> createState() => ProductslistTableState();
}

class ProductslistTableState extends State<ProductslistTable> {
  // Fake data.
  final List<ProductItem> _allProducts = [
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Homedics SoundSleep',
      price: 738.35,
      qty: 4152,
      category: 'Health & Sleep',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Newpoint Motorized Mixer',
      price: 520.15,
      qty: 1577,
      category: 'Health & Sleep',
      availability: false,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Orangemonkie Foldio360 Drone',
      price: 678.99,
      qty: 865,
      category: 'Health & Sleep',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Ketsicar SV 2N Kit',
      price: 943.85,
      qty: 459,
      category: 'Health & Sleep',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: '3D Printer Kit Pro',
      price: 896.81,
      qty: 560,
      category: 'Health & Sleep',
      availability: false,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'DIY Crafts Imaging Device',
      price: 600.99,
      qty: 3012,
      category: 'Crafts',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Giftana 4 in 1 Set',
      price: 106.58,
      qty: 4560,
      category: 'Gifts',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Odyssey Sound Machine',
      price: 805.98,
      qty: 8013,
      category: 'Audio',
      availability: false,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Personalized Giftana',
      price: 156.58,
      qty: 1024,
      category: 'Personal Gifts',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Ideh Deluxe Set',
      price: 850.00,
      qty: 3300,
      category: 'Home Decor',
      availability: false,
    ),
    // Additional items for pagination:
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'محمد',
      price: 299.99,
      qty: 150,
      category: 'Antiques',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Modern Lamp',
      price: 159.49,
      qty: 325,
      category: 'Lighting',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Ergonomic Chair',
      price: 489.00,
      qty: 87,
      category: 'Furniture',
      availability: false,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Wireless Headphones',
      price: 129.99,
      qty: 1120,
      category: 'Electronics',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Fitness Tracker',
      price: 79.99,
      qty: 2050,
      category: 'Wearables',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Smart Watch Pro',
      price: 249.99,
      qty: 874,
      category: 'Wearables',
      availability: false,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Bluetooth Speaker',
      price: 59.99,
      qty: 542,
      category: 'Audio',
      availability: true,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'HD Webcam',
      price: 39.99,
      qty: 375,
      category: 'Computers',
      availability: false,
    ),
    ProductItem(
      image: 'assets/images/image3.png',
      name: 'Gaming Keyboard',
      price: 89.99,
      qty: 624,
      category: 'Accessories',
      availability: true,
    ),
  ];

  int _currentPage = 1;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final int _itemsPerPage = 9;

  /// Returns filtered, searched, and sorted products.
  List<ProductItem> get filteredProducts {
    List<ProductItem> temp = List.from(_allProducts);
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
    // Apply sorting if set (1 for Price, 2 for Qty).
    if (_sortColumnIndex != null) {
      if (_sortColumnIndex == 1) {
        temp.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortColumnIndex == 2) {
        temp.sort((a, b) => a.qty.compareTo(b.qty));
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
    // Changed mainAxisAlignment to start so everything is left-aligned.
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
                      // Image & Name Column (remains unchanged).
                      const DataColumn(label: Text("Image & Name")),
                      // Price Column (header left-aligned, no numeric flag).
                      DataColumn(
                        label: _buildSortableColumnLabel("Price", 1),
                        onSort: (columnIndex, _) {
                          _onSort(1);
                        },
                      ),
                      // Qty Column (header left-aligned, no numeric flag).
                      DataColumn(
                        label: _buildSortableColumnLabel("Qty", 2),
                        onSort: (columnIndex, _) {
                          _onSort(2);
                        },
                      ),
                      // Category Column.
                      const DataColumn(label: Text("Category")),
                      // Availability Column.
                      const DataColumn(label: Text("Availability")),
                    ],
                    rows: visibleProducts.map((product) {
                      return DataRow(
                        cells: [
                          // Image & Name cell.
                          DataCell(
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.asset(
                                    product.image,
                                    width: 50.w,
                                    height: 50.h,
                                    fit: BoxFit.cover,
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
                          // Price cell.
                          DataCell(
                              Text("\$${product.price.toStringAsFixed(2)}")),
                          // Qty cell.
                          DataCell(Text("${product.qty}")),
                          // Category cell.
                          DataCell(Text(product.category)),
                          // Availability cell.
                          DataCell(
                              _buildAvailabilityPill(product.availability)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Pagination row.
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
                    SizedBox(
                      width: 10.w,
                    ),
                    // Left arrow.
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
                    // Right arrow.
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
    final String label = isActive ? "Active" : "UnActive";

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
