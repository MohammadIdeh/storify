import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/OrderWidgets/orderModel.dart';
import '../../screens/vieworder.dart' show Vieworder;

class Ordertable extends StatefulWidget {
  final List<OrderItem> orders;
  final String filter; // "Total", "Active", "Completed", "Cancelled"
  final String searchQuery;
  const Ordertable({
    Key? key,
    required this.orders,
    this.filter = "Total",
    this.searchQuery = "",
  }) : super(key: key);

  @override
  State<Ordertable> createState() => _OrdertableState();
}

class _OrdertableState extends State<Ordertable> {
  // Pagination controls.
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  // Apply filter based on the selected filter value.
  List<OrderItem> get _filteredOrders {
    List<OrderItem> filtered = widget.orders;
    if (widget.filter != "Total") {
      String targetStatus = "";
      if (widget.filter == "Active") {
        targetStatus = "Awaiting";
      } else if (widget.filter == "Completed") {
        targetStatus = "Accepted";
      } else if (widget.filter == "Cancelled") {
        targetStatus = "Declined";
      }
      filtered =
          filtered.where((order) => order.status == targetStatus).toList();
    }
    // Filter by search query on orderId.
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered
          .where((order) => order.orderId.contains(widget.searchQuery))
          .toList();
    }
    return filtered;
  }

  // Calculate which orders are shown on the current page.
  List<OrderItem> get _visibleOrders {
    final totalItems = _filteredOrders.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > totalItems
        ? totalItems
        : startIndex + _itemsPerPage;
    return _filteredOrders.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _filteredOrders.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    // Styling variables.
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Table with horizontal scrolling.
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
                    columns: const [
                      DataColumn(label: Text("Order ID")),
                      DataColumn(label: Text("Store Name")),
                      DataColumn(label: Text("Phone No")),
                      DataColumn(label: Text("Order Date")),
                      DataColumn(label: Text("Total Products")),
                      DataColumn(label: Text("Total Amount")),
                      DataColumn(label: Text("Status")),
                    ],
                    rows: _visibleOrders.map((order) {
                      return DataRow(
                        onSelectChanged: (selected) async {
                          if (selected == true) {
                            // Push the details screen with a fade transition.
                            final updatedOrder =
                                await Navigator.of(context).push<OrderItem>(
                              PageRouteBuilder(
                                pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                    Vieworder(
                                        order:
                                            order), // pass the current row's order
                                transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) =>
                                    FadeTransition(
                                        opacity: animation, child: child),
                                transitionDuration:
                                    const Duration(milliseconds: 400),
                              ),
                            );

                            // If the order status was changed, update the orders list.
                            if (updatedOrder != null) {
                              setState(() {
                                final index = widget.orders.indexWhere(
                                    (o) => o.orderId == order.orderId);
                                if (index != -1) {
                                  widget.orders[index] = updatedOrder;
                                }
                              });
                            }
                          }
                        },
                        cells: [
                          DataCell(Text(order.orderId)),
                          DataCell(Text(order.storeName)),
                          DataCell(Text(order.phoneNo)),
                          DataCell(Text(order.orderDate)),
                          DataCell(Text("${order.totalProducts}")),
                          DataCell(Text(
                              "\$${order.totalAmount.toStringAsFixed(2)}")),
                          DataCell(_buildStatusPill(order.status)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Pagination Row.
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      "Total $totalItems Orders",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Left arrow button.
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
                    // Page buttons.
                    Row(
                      children: List.generate(totalPages, (index) {
                        final pageIndex = index + 1;
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 10.h),
                            ),
                            onPressed: () {
                              setState(() {
                                _currentPage = pageIndex;
                              });
                            },
                            child: Text(
                              "$pageIndex",
                              style: GoogleFonts.spaceGrotesk(
                                color:
                                    isSelected ? Colors.white : Colors.white70,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    // Right arrow button.
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

  /// Builds a pill-like widget for order status.
  Widget _buildStatusPill(String status) {
    Color textColor;
    Color borderColor;
    if (status == "Accepted") {
      textColor = const Color.fromARGB(178, 0, 224, 116);
      borderColor = textColor;
    } else if (status == "Declined") {
      textColor = const Color.fromARGB(255, 229, 62, 62);
      borderColor = textColor;
    } else if (status == "Awaiting") {
      textColor = const Color.fromARGB(255, 255, 177, 62);
      borderColor = textColor;
    } else {
      textColor = Colors.white70;
      borderColor = Colors.white54;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
