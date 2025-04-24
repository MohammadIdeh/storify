import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/screens/productOverview.dart';
import 'package:storify/admin/widgets/productsWidgets/exportPopUp.dart';
import 'package:storify/admin/widgets/productsWidgets/product_item_Model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductslistTable extends StatefulWidget {
  final int selectedFilterIndex; // 0: All, 1: Active, 2: UnActive
  final String searchQuery;
  final VoidCallback? onOperationCompleted; // New callback for notifying parent
  
  const ProductslistTable({
    super.key,
    required this.selectedFilterIndex,
    required this.searchQuery,
    this.onOperationCompleted, // Optional callback
  });

  @override
  State<ProductslistTable> createState() => ProductslistTableState();
}

class ProductslistTableState extends State<ProductslistTable> {
  List<ProductItemInformation> _allProducts = [];
  bool _isLoading = true;
  String? _error;

  int _currentPage = 1;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final int _itemsPerPage = 9;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Public method to refresh products (can be called from parent)
  void refreshProducts() {
    _fetchProducts();
  }

  // Helper method to notify parent when operations complete
  void _notifyOperationCompleted() {
    if (widget.onOperationCompleted != null) {
      widget.onOperationCompleted!();
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://finalproject-a5ls.onrender.com/product/products'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['products'] != null) {
          setState(() {
            _allProducts = (data['products'] as List)
                .map((product) => ProductItemInformation.fromJson(product))
                .toList();
            _isLoading = false;
          });
          
          // Notify parent that products have been loaded
          // This ensures dashboard stats are in sync with product list
          _notifyOperationCompleted();
        } else {
          setState(() {
            _error = 'Invalid data format';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load products. Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  /// Returns filtered, searched, and sorted products.
  List<ProductItemInformation> get filteredProducts {
    List<ProductItemInformation> temp = List.from(_allProducts);
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
      } else if (_sortColumnIndex == 3) {
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
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color.fromARGB(255, 105, 65, 198),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading products',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _fetchProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
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
                      DataColumn(
                        label: _buildSortableColumnLabel("Qty", 3),
                        onSort: (columnIndex, _) {
                          _onSort(3);
                        },
                      ),
                      // Category Column
                      const DataColumn(label: Text("Category")),
                      // Availability Column
                      const DataColumn(label: Text("Availability")),
                    ],
                    rows: visibleProducts.map((product) {
                      return DataRow(
                        onSelectChanged: (selected) async {
                          if (selected == true) {
                            final updatedProduct = await Navigator.of(context)
                                .push<ProductItemInformation>(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        Productoverview(product: product),
                                transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) =>
                                    FadeTransition(
                                        opacity: animation, child: child),
                                transitionDuration:
                                    const Duration(milliseconds: 400),
                              ),
                            );
                            // If updatedProduct is not null, update your data source.
                            if (updatedProduct != null) {
                              setState(() {
                                final index = _allProducts.indexWhere(
                                    (p) => p.productId == product.productId);
                                if (index != -1) {
                                  _allProducts[index] = updatedProduct;
                                }
                              });
                              
                              // Notify parent that a product was updated
                              // This will trigger the dashboard stats refresh
                              _notifyOperationCompleted();
                            }
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
                          DataCell(Text("${product.qty}")),
                          // Category cell
                          DataCell(Text(product.categoryName)),
                          // Availability cell
                          DataCell(
                              _buildAvailabilityPill(product.availability)),
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