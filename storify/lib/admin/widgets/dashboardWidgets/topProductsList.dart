import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_models.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_service.dart';
// Import your models and service

class ProductsTable extends StatefulWidget {
  const ProductsTable({Key? key}) : super(key: key);

  @override
  State<ProductsTable> createState() => _ProductsTableState();
}

class _ProductsTableState extends State<ProductsTable> {
  // API Data
  List<Product> _products = [];
  Pagination? _pagination;

  // Loading and error states
  bool _isLoading = true;
  String? _error;

  // Pagination
  int _currentPage = 1;
  final int _limit = 10;

  // DataTable sorting state
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DashboardService.getTopProducts(
        page: page,
        limit: _limit,
      );

      setState(() {
        _products = response.products;
        _pagination = response.pagination;
        _currentPage = page;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      switch (columnIndex) {
        case 0: // Product ID
          _products.sort((a, b) => a.productId.compareTo(b.productId));
          break;
        case 1: // Name
          _products.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case 2: // Vendor
          _products.sort((a, b) =>
              a.vendor.toLowerCase().compareTo(b.vendor.toLowerCase()));
          break;
        case 3: // Total Sold
          _products.sort((a, b) => a.totalSold.compareTo(b.totalSold));
          break;
        case 4: // Stock
          _products.sort((a, b) => a.stock.compareTo(b.stock));
          break;
      }

      if (!ascending) {
        _products = _products.reversed.toList();
      }
    });
  }

  void _goToPage(int page) {
    if (page >= 1 && _pagination != null && page <= _pagination!.totalPages) {
      _fetchProducts(page: page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Data table
        _buildTable(),

        // Pagination controls
        if (_pagination != null && _pagination!.totalPages > 1)
          _buildPaginationControls(),
      ],
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return Container(
        height: 400.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF9D67FF),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 400.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                'Error loading products',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => _fetchProducts(page: _currentPage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D67FF),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No products found',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }

    // Main container background
    final Color backgroundColor = const Color.fromARGB(0, 0, 0, 0);
    // Heading row color
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    // Divider and border color/thickness
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
      ),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(headingColor),
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
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
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
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: Text("Product ID"),
          ),
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: Text("Name"),
          ),
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: Text("Vendor"),
          ),
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: Text("Total Sold"),
          ),
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: Text("Stock"),
          ),
        ],
        rows: _products.map((product) {
          return DataRow(
            cells: [
              DataCell(Text("${product.productId}")),
              DataCell(
                Row(
                  children: [
                    // Product icon (placeholder)

                    Expanded(
                      child: Text(
                        product.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  product.vendor,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "\$${product.totalSold.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStockColor(product.stock).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "${product.stock} items",
                    style: TextStyle(
                      color: _getStockColor(product.stock),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Text(
            "Page $_currentPage of ${_pagination!.totalPages} • ${_pagination!.totalItems} total items",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
          ),

          // Navigation buttons
          Row(
            children: [
              // Previous button
              IconButton(
                onPressed: _pagination!.hasPreviousPage
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: _pagination!.hasPreviousPage
                      ? Colors.white
                      : Colors.white30,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _pagination!.hasPreviousPage
                      ? const Color(0xFF9D67FF)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),

              SizedBox(width: 8.w),

              // Page numbers (show current and adjacent pages)
              ..._buildPageNumbers(),

              SizedBox(width: 8.w),

              // Next button
              IconButton(
                onPressed: _pagination!.hasNextPage
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  color:
                      _pagination!.hasNextPage ? Colors.white : Colors.white30,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _pagination!.hasNextPage
                      ? const Color(0xFF9D67FF)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageWidgets = [];
    int totalPages = _pagination!.totalPages;

    // Show up to 5 page numbers around current page
    int start = (_currentPage - 2).clamp(1, totalPages);
    int end = (start + 4).clamp(1, totalPages);

    // Adjust start if we're near the end
    if (end == totalPages) {
      start = (totalPages - 4).clamp(1, totalPages);
    }

    for (int i = start; i <= end; i++) {
      pageWidgets.add(
        GestureDetector(
          onTap: () => _goToPage(i),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: i == _currentPage
                  ? const Color(0xFF9D67FF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: i == _currentPage
                    ? const Color(0xFF9D67FF)
                    : Colors.white30,
              ),
            ),
            child: Text(
              "$i",
              style: GoogleFonts.spaceGrotesk(
                color: i == _currentPage ? Colors.white : Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return pageWidgets;
  }

  Color _getStockColor(int stock) {
    if (stock <= 10) return Colors.red;
    if (stock <= 50) return Colors.orange;
    return Colors.green;
  }
}
