import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Model for an order history item.
class OrderHistoryItem {
  final String orderId; // e.g. "#129376483"
  final double orderPrice; // e.g. 100.58
  final String orderDate; // e.g. "1/3/2025"
  final String store; // e.g. "Abu ideh"
  final String
      status; // e.g. "Completed", "On the way", "Cancelled", "Refunded"

  OrderHistoryItem({
    required this.orderId,
    required this.orderPrice,
    required this.orderDate,
    required this.store,
    required this.status,
  });
}

class SellingHistoryWidget extends StatefulWidget {
  const SellingHistoryWidget({Key? key}) : super(key: key);

  @override
  _SellingHistoryWidgetState createState() => _SellingHistoryWidgetState();
}

class _SellingHistoryWidgetState extends State<SellingHistoryWidget> {
  // Fake data for demonstration.
  final List<OrderHistoryItem> _allOrders = [
    OrderHistoryItem(
      orderId: "#129376483",
      orderPrice: 100.58,
      orderDate: "1/3/2025",
      store: "Abu ideh",
      status: "Completed",
    ),
    OrderHistoryItem(
      orderId: "#129376484",
      orderPrice: 120.00,
      orderDate: "1/3/2025",
      store: "Abu ideh",
      status: "On the way",
    ),
    OrderHistoryItem(
      orderId: "#129376485",
      orderPrice: 90.99,
      orderDate: "1/3/2025",
      store: "Abu ideh",
      status: "Completed",
    ),
    OrderHistoryItem(
      orderId: "#129376486",
      orderPrice: 110.50,
      orderDate: "1/3/2025",
      store: "Abu ideh",
      status: "Cancelled",
    ),
    OrderHistoryItem(
      orderId: "#129376487",
      orderPrice: 99.95,
      orderDate: "1/3/2025",
      store: "Abu ideh",
      status: "Completed",
    ),
    OrderHistoryItem(
      orderId: "#129376488",
      orderPrice: 105.00,
      orderDate: "1/3/2025",
      store: "Abu ideh",
      status: "Refunded",
    ),
    // Additional items that won't be shown if we limit to 6.
    OrderHistoryItem(
      orderId: "#129376489",
      orderPrice: 85.00,
      orderDate: "1/4/2025",
      store: "Abu ideh",
      status: "Completed",
    ),
  ];

  // Maximum items per page.
  final int _itemsPerPage = 6;
  int _currentPage = 1;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  /// Optionally, you can add sorting logic similar to your previous code.
  List<OrderHistoryItem> get _sortedOrders {
    List<OrderHistoryItem> temp = List.from(_allOrders);
    if (_sortColumnIndex != null) {
      if (_sortColumnIndex == 1) {
        temp.sort((a, b) => a.orderPrice.compareTo(b.orderPrice));
      } else if (_sortColumnIndex == 2) {
        // For demo, sort by orderDate lexicographically.
        temp.sort((a, b) => a.orderDate.compareTo(b.orderDate));
      }
      if (!_sortAscending) {
        temp = temp.reversed.toList();
      }
    }
    return temp;
  }

  List<OrderHistoryItem> get _visibleOrders {
    List<OrderHistoryItem> sorted = _sortedOrders;
    final totalItems = sorted.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > totalItems
        ? totalItems
        : startIndex + _itemsPerPage;
    return sorted.sublist(startIndex, endIndex);
  }

  /// Helper: builds a color-coded pill for status.
  Widget _buildStatusPill(String status) {
    late Color borderColor;
    late Color bgColor;

    switch (status) {
      case "Completed":
        borderColor = const Color.fromARGB(255, 48, 182, 140); // greenish
        bgColor = borderColor.withOpacity(0.15);
        break;
      case "On the way":
        borderColor = const Color.fromARGB(255, 228, 0, 127); // pinkish
        bgColor = borderColor.withOpacity(0.15);
        break;
      case "Cancelled":
        borderColor = const Color.fromARGB(255, 229, 62, 62); // red
        bgColor = borderColor.withOpacity(0.15);
        break;
      case "Refunded":
        borderColor = const Color.fromARGB(255, 141, 110, 199); // purple
        bgColor = borderColor.withOpacity(0.15);
        break;
      default:
        borderColor = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.15);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: borderColor,
        ),
      ),
    );
  }

  /// Builds a header label for sorting (if needed).
  Widget _buildSortableColumnLabel(String label, int colIndex) {
    bool isSorted = _sortColumnIndex == colIndex;
    Widget arrow = SizedBox.shrink();
    if (isSorted) {
      arrow = Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 18.sp,
        color: Colors.white,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(fontSize: 18.sp, color: Colors.white),
        ),
        SizedBox(width: 4.w),
        arrow,
      ],
    );
  }

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

  /// Builds a pagination button.
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _sortedOrders.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Container(
      width: double.infinity, // Takes the maximum width
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(29.r),
      ),
      child: Column(
        children: [
          // Wrap DataTable in horizontal SingleChildScrollView.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minWidth: MediaQuery.of(context).size.width),
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all<Color>(
                    const Color.fromARGB(255, 36, 50, 69)),
                border: TableBorder(
                  top: BorderSide(
                      color: const Color.fromARGB(255, 34, 53, 62), width: 1),
                  bottom: BorderSide(
                      color: const Color.fromARGB(255, 34, 53, 62), width: 1),
                  left: BorderSide(
                      color: const Color.fromARGB(255, 34, 53, 62), width: 1),
                  right: BorderSide(
                      color: const Color.fromARGB(255, 34, 53, 62), width: 1),
                  horizontalInside: BorderSide(
                      color: const Color.fromARGB(255, 36, 50, 69), width: 2),
                  verticalInside: BorderSide(
                      color: const Color.fromARGB(255, 36, 50, 69), width: 2),
                ),
                columnSpacing: 20.w,
                dividerThickness: 0,
                headingTextStyle: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                dataTextStyle: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15.sp,
                ),
                columns: [
                  DataColumn(
                      label: Text("Order Id",
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 16.sp, color: Colors.white))),
                  DataColumn(
                    label: _buildSortableColumnLabel("Order Price", 1),
                    onSort: (columnIndex, _) {
                      _onSort(1);
                    },
                  ),
                  DataColumn(
                      label: Text("Order Date",
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 16.sp, color: Colors.white))),
                  DataColumn(
                      label: Text("Store",
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 16.sp, color: Colors.white))),
                  DataColumn(
                      label: Text("Status",
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 16.sp, color: Colors.white))),
                ],
                rows: _visibleOrders.map((order) {
                  return DataRow(
                    cells: [
                      DataCell(Text(order.orderId)),
                      DataCell(
                          Text("\$${order.orderPrice.toStringAsFixed(2)}")),
                      DataCell(Text(order.orderDate)),
                      DataCell(Text(order.store)),
                      DataCell(_buildStatusPill(order.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(
            height: 20.h,
          ),
          // Pagination row.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Left arrow.
              IconButton(
                icon:
                    Icon(Icons.arrow_back, size: 20.sp, color: Colors.white70),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
              ),
              // Page number buttons.
              ...List.generate(totalPages, (index) {
                return _buildPageButton(index + 1);
              }),
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
        ],
      ),
    );
  }
}
