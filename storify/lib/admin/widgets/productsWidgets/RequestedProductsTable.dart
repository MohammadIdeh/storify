import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/productsWidgets/RequestedProductDetail.dart';
import 'package:storify/admin/widgets/productsWidgets/RequestedProductModel.dart';

class RequestedProductsTable extends StatefulWidget {
  final int selectedFilterIndex; // 0: All, 1: Pending, 2: Accepted, 3: Declined
  final String searchQuery;
  final VoidCallback? onOperationCompleted; // Callback for notifying parent

  const RequestedProductsTable({
    super.key,
    required this.selectedFilterIndex,
    required this.searchQuery,
    this.onOperationCompleted,
  });

  @override
  State<RequestedProductsTable> createState() => RequestedProductsTableState();
}

class RequestedProductsTableState extends State<RequestedProductsTable> {
  List<RequestedProductModel> _allProducts = [];
  bool _isLoading = true;
  String? _error;

  int _currentPage = 1;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final int _itemsPerPage = 5; // Show 5 items per page

  final List<String> _statusFilters = [
    "All",
    "Pending",
    "Accepted",
    "Declined"
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequestedProducts();
  }

  // Public method to refresh products (can be called from parent)
  void refreshProducts() {
    _fetchRequestedProducts();
  }

  // Helper method to notify parent when operations complete
  void _notifyOperationCompleted() {
    if (widget.onOperationCompleted != null) {
      widget.onOperationCompleted!();
    }
  }

  Future<void> _fetchRequestedProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get auth headers from AuthService
      final headers = await AuthService.getAuthHeaders();
      print('📤 Fetching requested products');
      print('🔑 Using auth headers: $headers');

      final response = await http.get(
        Uri.parse('https://finalproject-a5ls.onrender.com/request-product/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['productRequests'] != null) {
          setState(() {
            _allProducts = (data['productRequests'] as List)
                .map((product) => RequestedProductModel.fromJson(product))
                .toList();
            _isLoading = false;
          });

          // Notify parent that products have been loaded
          _notifyOperationCompleted();
        } else {
          setState(() {
            _error = 'Invalid data format';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error =
              'Failed to load requested products. Error: ${response.statusCode}';
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
  List<RequestedProductModel> get filteredProducts {
    List<RequestedProductModel> temp = List.from(_allProducts);

    // Filter by status
    if (widget.selectedFilterIndex > 0 &&
        widget.selectedFilterIndex < _statusFilters.length) {
      String statusFilter = _statusFilters[widget.selectedFilterIndex];
      temp = temp.where((p) => p.status == statusFilter).toList();
    }

    // Search by name or ID (case-insensitive)
    if (widget.searchQuery.isNotEmpty) {
      temp = temp
          .where((p) =>
              p.name.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
              p.id.toString().contains(widget.searchQuery))
          .toList();
    }

    // Apply sorting if set
    if (_sortColumnIndex != null) {
      if (_sortColumnIndex == 0) {
        // Sort by ID
        temp.sort((a, b) => a.id.compareTo(b.id));
      } else if (_sortColumnIndex == 1) {
        // Sort by Date
        temp.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else if (_sortColumnIndex == 3) {
        // Sort by Cost Price
        temp.sort((a, b) => a.costPrice.compareTo(b.costPrice));
      } else if (_sortColumnIndex == 4) {
        // Sort by Sell Price
        temp.sort((a, b) => a.sellPrice.compareTo(b.sellPrice));
      }
      if (!_sortAscending) {
        temp = temp.reversed.toList();
      }
    } else {
      // Default sort by newest first if no sorting is specified
      temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading requested products',
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
              onPressed: _fetchRequestedProducts,
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
    final visibleProducts = filteredProducts.isEmpty
        ? []
        : filteredProducts.sublist(startIndex, endIndex);

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
          clipBehavior: Clip.antiAlias,
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
                      // ID Column (sortable)
                      DataColumn(
                        label: _buildSortableColumnLabel("ID", 0),
                        onSort: (columnIndex, _) {
                          _onSort(0);
                        },
                      ),
                      // Date Column (sortable)
                      DataColumn(
                        label: _buildSortableColumnLabel("Date Requested", 1),
                        onSort: (columnIndex, _) {
                          _onSort(1);
                        },
                      ),
                      // Image & Name Column
                      const DataColumn(label: Text("Image & Name")),
                      // Cost Price Column (sortable)
                      DataColumn(
                        label: _buildSortableColumnLabel("Cost Price", 3),
                        onSort: (columnIndex, _) {
                          _onSort(3);
                        },
                      ),
                      // Sell Price Column (sortable)
                      DataColumn(
                        label: _buildSortableColumnLabel("Sell Price", 4),
                        onSort: (columnIndex, _) {
                          _onSort(4);
                        },
                      ),
                      // Category Column
                      const DataColumn(label: Text("Category")),
                      // Supplier Column
                      const DataColumn(label: Text("Supplier")),
                      // Status Column
                      const DataColumn(label: Text("Status")),
                    ],
                    rows: visibleProducts.map((product) {
                      return DataRow(
                        onSelectChanged: (selected) async {
                          if (selected == true) {
                            final updatedProduct = await Navigator.of(context)
                                .push<RequestedProductModel>(
                              PageRouteBuilder(
                                pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                    RequestedProductDetail(product: product),
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
                                final index = _allProducts
                                    .indexWhere((p) => p.id == product.id);
                                if (index != -1) {
                                  _allProducts[index] = updatedProduct;
                                }
                              });

                              // Notify parent that a product was updated
                              _notifyOperationCompleted();
                            }
                          }
                        },
                        cells: [
                          // ID cell
                          DataCell(Text("${product.id}")),
                          // Date cell
                          DataCell(Text(
                            "${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}",
                          )),
                          // Image & Name cell
                          DataCell(
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: product.image != null
                                      ? Image.network(
                                          product.image!,
                                          width: 50.w,
                                          height: 50.h,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
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
                                        )
                                      : Container(
                                          width: 50.w,
                                          height: 50.h,
                                          color: Colors.grey.shade800,
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.white70,
                                            size: 24.sp,
                                          ),
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
                          // Category cell
                          DataCell(Text(product.category.categoryName)),
                          // Supplier cell
                          DataCell(Text(product.supplier.user.name)),
                          // Status cell with admin note tooltip if exists
                          DataCell(_buildStatusPill(
                              product.status, product.adminNote)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Pagination row
              if (visibleProducts.isNotEmpty)
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
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

  /// Status pill with different colors based on status and tooltip for admin note.
  Widget _buildStatusPill(String status, String? adminNote) {
    late Color bgColor;

    switch (status) {
      case "Pending":
        bgColor = Colors.amber; // amber/yellow for pending
        break;
      case "Accepted":
        bgColor = const Color.fromARGB(178, 0, 224, 116); // green for accepted
        break;
      case "Declined":
        bgColor = const Color.fromARGB(255, 229, 62, 62); // red for declined
        break;
      default:
        bgColor = Colors.grey; // default
    }

    final statusPill = Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: bgColor,
        ),
      ),
    );

    // If there's an admin note, wrap the status pill with a tooltip
    if (adminNote != null && adminNote.isNotEmpty) {
      return Tooltip(
        message: "Admin Note: $adminNote",
        preferBelow: true,
        showDuration: const Duration(seconds: 3),
        decoration: BoxDecoration(
          color: const Color.fromARGB(230, 36, 50, 69),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: const Color.fromARGB(255, 105, 65, 198),
            width: 1.5,
          ),
        ),
        textStyle: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 14.sp,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: statusPill,
      );
    }

    // If no admin note, just return the status pill
    return statusPill;
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
