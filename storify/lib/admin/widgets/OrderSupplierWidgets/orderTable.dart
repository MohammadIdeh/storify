// lib/admin/widgets/OrderSupplierWidgets/orderTable.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderModel.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import '../../screens/vieworder.dart' show Vieworder;

class Ordertable extends StatefulWidget {
  final List<OrderItem> orders;
  final String filter; // "Total", "Active", "Completed", "Cancelled"
  final String searchQuery;
  final bool isSupplierMode; // Added parameter to determine the mode
  final String?
      selectedActiveStatus; // NEW: Selected active status for customer orders

  const Ordertable({
    Key? key,
    required this.orders,
    this.filter = "Total",
    this.searchQuery = "",
    this.isSupplierMode = true, // Default to supplier mode
    this.selectedActiveStatus, // NEW parameter
  }) : super(key: key);

  @override
  State<Ordertable> createState() => _OrdertableState();
}

class _OrdertableState extends State<Ordertable> {
  // Pagination controls.
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final isArabic = LocalizationHelper.isArabic(context);

    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } else {
      return GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }

  EdgeInsets _getDirectionalPadding({
    double start = 0,
    double top = 0,
    double end = 0,
    double bottom = 0,
  }) {
    final isRtl = LocalizationHelper.isRTL(context);
    if (isRtl) {
      return EdgeInsets.fromLTRB(end, top, start, bottom);
    }
    return EdgeInsets.fromLTRB(start, top, end, bottom);
  }

  // Apply filter based on the selected filter value with the new status mappings.
  List<OrderItem> get _filteredOrders {
    List<OrderItem> filtered = widget.orders;

    if (widget.filter != "Total") {
      if (widget.filter == "Active") {
        if (widget.isSupplierMode) {
          // Supplier mode: use original logic
          filtered = filtered
              .where((order) =>
                  order.status == "Accepted" ||
                  order.status == "Pending" ||
                  order.status == "Prepared" ||
                  order.status == "on_theway" ||
                  order.status == "PartiallyAccepted")
              .toList();
        } else {
          // Customer mode: check if specific active status is selected
          if (widget.selectedActiveStatus != null) {
            // Filter by specific active status
            filtered = filtered
                .where((order) => order.status == widget.selectedActiveStatus)
                .toList();
          } else {
            // Show all active statuses
            filtered = filtered
                .where((order) =>
                    order.status == "Accepted" ||
                    order.status == "Assigned" ||
                    order.status == "Preparing" ||
                    order.status == "Prepared" ||
                    order.status == "on_theway")
                .toList();
          }
        }
      } else if (widget.filter == "Completed") {
        filtered = filtered
            .where((order) =>
                order.status == "Delivered" || order.status == "Shipped")
            .toList();
      } else if (widget.filter == "Cancelled") {
        filtered = filtered
            .where((order) =>
                order.status == "Declined" ||
                order.status == "Rejected" ||
                order.status == "DeclinedByAdmin")
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

  String _getLocalizedStatus(String status) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    switch (status) {
      case "Accepted":
        return l10n.orderStatusAccepted;
      case "Pending":
        return l10n.orderStatusPending;
      case "Delivered":
        return l10n.orderStatusDelivered;
      case "Shipped":
        return l10n.orderStatusShipped;
      case "Declined":
        return l10n.orderStatusDeclined;
      case "Rejected":
        return l10n.orderStatusRejected;
      case "DeclinedByAdmin":
        return l10n.orderStatusDeclinedByAdmin;
      case "PartiallyAccepted":
        return l10n.orderStatusPartiallyAccepted;
      case "Prepared":
        return l10n.orderStatusPrepared;
      case "on_theway":
        return l10n.orderStatusOnTheWay;
      case "Assigned":
        return l10n.orderStatusAssigned;
      case "Preparing":
        return l10n.orderStatusPreparing;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    final totalItems = _filteredOrders.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    // Styling variables.
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: LayoutBuilder(
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
                            l10n.noOrdersFound,
                            style: _getTextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            l10n.noOrdersToDisplay,
                            style: _getTextStyle(
                              fontSize: 14.sp,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                // Empty state for filtered results
                else if (_filteredOrders.isEmpty)
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
                            Icons.filter_list_off,
                            size: 64.sp,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            l10n.noOrdersMatchFilter,
                            style: _getTextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            widget.selectedActiveStatus != null
                                ? l10n.noOrdersWithStatus(
                                    widget.selectedActiveStatus!)
                                : l10n.adjustFilterCriteria,
                            style: _getTextStyle(
                              fontSize: 14.sp,
                              color: Colors.white38,
                            ),
                            textAlign: TextAlign.center,
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
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
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
                        headingTextStyle: _getTextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        dataTextStyle: _getTextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        columns: [
                          DataColumn(label: Text(l10n.orderId)),
                          // Change column name based on mode
                          DataColumn(
                              label: Text(widget.isSupplierMode
                                  ? l10n.supplierName
                                  : l10n.customerName)),
                          DataColumn(label: Text(l10n.phoneNumber)),
                          DataColumn(label: Text(l10n.orderDate)),
                          DataColumn(label: Text(l10n.totalProducts)),
                          DataColumn(label: Text(l10n.totalAmount)),
                          DataColumn(label: Text(l10n.status)),
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
                                      isSupplierMode: widget
                                          .isSupplierMode, // Pass the mode
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
                if (widget.orders.isNotEmpty && _filteredOrders.isNotEmpty)
                  Padding(
                    padding: _getDirectionalPadding(
                      start: 8.w,
                      end: 8.w,
                      top: 16.h,
                      bottom: 16.h,
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        Text(
                          l10n.totalOrdersCount(totalItems),
                          style: _getTextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // Left/Right arrow buttons (direction aware)
                        IconButton(
                          icon: Icon(
                            isRtl ? Icons.arrow_forward : Icons.arrow_back,
                            size: 20.sp,
                            color: Colors.white70,
                          ),
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
                                    color:
                                        const Color.fromARGB(255, 34, 53, 62),
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
                                  style: _getTextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        // Right/Left arrow button (direction aware)
                        IconButton(
                          icon: Icon(
                            isRtl ? Icons.arrow_back : Icons.arrow_forward,
                            size: 20.sp,
                            color: Colors.white70,
                          ),
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
      ),
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
      case "DeclinedByAdmin":
        textColor = const Color.fromARGB(255, 255, 70, 70); // bright red
        borderColor = textColor;
        break;
      case "PartiallyAccepted":
        textColor = const Color.fromARGB(255, 255, 136, 0); // orange
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
      // NEW: Additional customer order statuses
      case "Assigned":
        textColor = const Color.fromARGB(255, 76, 175, 80); // green
        borderColor = textColor;
        break;
      case "Preparing":
        textColor = const Color.fromARGB(255, 255, 193, 7); // amber
        borderColor = textColor;
        break;
      default:
        textColor = Colors.white70;
        borderColor = Colors.white54;
        break;
    }

    // Get localized status text
    final String displayStatus = _getLocalizedStatus(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        displayStatus,
        style: _getTextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
