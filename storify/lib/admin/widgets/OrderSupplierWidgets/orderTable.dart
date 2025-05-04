// lib/admin/widgets/OrderSupplierWidgets/orderTable.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderModel.dart';
import '../../screens/vieworder.dart' show Vieworder;

class Ordertable extends StatefulWidget {
  final List<OrderItem> orders;
  final String filter; // "Total", "Active", "Completed", "Cancelled"
  final String searchQuery;
  final bool isSupplierMode; // Added parameter to determine the mode

  const Ordertable({
    Key? key,
    required this.orders,
    this.filter = "Total",
    this.searchQuery = "",
    this.isSupplierMode = true, // Default to supplier mode
  }) : super(key: key);

  @override
  State<Ordertable> createState() => _OrdertableState();
}

class _OrdertableState extends State<Ordertable> {
  // Pagination controls.
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  // Apply filter based on the selected filter value with the new status mappings.
  List<OrderItem> get _filteredOrders {
    List<OrderItem> filtered = widget.orders;
    if (widget.filter != "Total") {
      if (widget.filter == "Active") {
        filtered = filtered
            .where((order) =>
                order.status == "Accepted" ||
                order.status == "Pending" ||
                order.status == "Prepared" ||
                order.status == "on_theway")
            .toList();
      } else if (widget.filter == "Completed") {
        filtered = filtered
            .where((order) =>
                order.status == "Delivered" || order.status == "Shipped")
            .toList();
      } else if (widget.filter == "Cancelled") {
        filtered = filtered
            .where((order) =>
                order.status == "Declined" || order.status == "Rejected")
            .toList();
      }
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

    // Check if there are any orders before trying to slice
    if (totalItems == 0) {
      return [];
    }

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
              // Empty state for no orders
              if (widget.orders.isEmpty)
                Container(
                  height: 300.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 50, 69),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64.sp,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No orders found',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'There are no orders to display',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
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
                      columns: [
                        const DataColumn(label: Text("Order ID")),
                        // Change column name based on mode
                        DataColumn(
                            label: Text(widget.isSupplierMode
                                ? "Supplier Name"
                                : "Customer Name")),
                        const DataColumn(label: Text("Phone No")),
                        const DataColumn(label: Text("Order Date")),
                        const DataColumn(label: Text("Total Products")),
                        const DataColumn(label: Text("Total Amount")),
                        const DataColumn(label: Text("Status")),
                      ],
                      rows: _visibleOrders.map((order) {
                        // Pre-format total amount string
                        final String totalAmountStr =
                            "\$" + order.totalAmount.toStringAsFixed(2);

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
                                    order: order,
                                    isSupplierMode:
                                        widget.isSupplierMode, // Pass the mode
                                  ),
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
                            DataCell(Text(order.totalProducts.toString())),
                            DataCell(Text(totalAmountStr)),
                            DataCell(_buildStatusPill(order.status)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Pagination Row - only show if there are orders
              if (widget.orders.isNotEmpty)
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
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
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
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

    switch (status) {
      case "Accepted":
        textColor = const Color.fromARGB(255, 0, 196, 255); // cyan
        borderColor = textColor;
        break;
      case "Pending":
        textColor = const Color.fromARGB(255, 255, 232, 29); // yellow
        borderColor = textColor;
        break;
      case "Delivered":
      case "Shipped":
        textColor = const Color.fromARGB(178, 0, 224, 116); // green
        borderColor = textColor;
        break;
      case "Declined":
      case "Rejected":
        textColor = const Color.fromARGB(255, 229, 62, 62); // red
        borderColor = textColor;
        break;
      case "Prepared":
        textColor = const Color.fromARGB(255, 255, 150, 30); // orange
        borderColor = textColor;
        break;
      case "on_theway":
        textColor = const Color.fromARGB(255, 130, 80, 223); // purple
        borderColor = textColor;
        break;
      default:
        textColor = Colors.white70;
        borderColor = Colors.white54;
        break;
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
