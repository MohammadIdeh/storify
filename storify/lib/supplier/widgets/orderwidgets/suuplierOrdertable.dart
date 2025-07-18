import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import 'package:storify/supplier/widgets/orderwidgets/OrderDetails_Model.dart';

class SupplierOrderTable extends StatefulWidget {
  final List<Order> orders;
  final String filter; // "Total", "Active", "Completed", "Cancelled"
  final String searchQuery;
  final Function(Order?) onOrderSelected;
  final Order? selectedOrder;

  const SupplierOrderTable({
    Key? key,
    required this.orders,
    this.filter = "Total",
    this.searchQuery = "",
    required this.onOrderSelected,
    this.selectedOrder,
  }) : super(key: key);

  @override
  State<SupplierOrderTable> createState() => _SupplierOrderTableState();
}

class _SupplierOrderTableState extends State<SupplierOrderTable> {
  // Pagination controls.
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  // Apply filter based on the selected filter value with the new status mappings.
  List<Order> get _filteredOrders {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    List<Order> filtered = widget.orders;
    if (widget.filter != l10n.totalOrders) {
      if (widget.filter == l10n.activeOrders) {
        filtered = filtered
            .where((order) =>
                order.status == "Accepted" ||
                order.status == "Pending" ||
                order.status == "PartiallyAccepted")
            .toList();
      } else if (widget.filter == l10n.completedOrders) {
        filtered =
            filtered.where((order) => order.status == "Delivered").toList();
      } else if (widget.filter == l10n.cancelledOrders) {
        filtered =
            filtered.where((order) => order.status == "Declined").toList();
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
  List<Order> get _visibleOrders {
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Rest of the build method remains the same
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
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            l10n.noOrdersToDisplay,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 14.sp,
                                    color: Colors.white38,
                                  )
                                : GoogleFonts.spaceGrotesk(
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
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return const Color.fromARGB(255, 105, 65, 198)
                                  .withOpacity(0.12);
                            }
                            return Colors.transparent;
                          },
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
                        headingTextStyle: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                        dataTextStyle: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13.sp,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13.sp,
                              ),
                        columns: [
                          DataColumn(label: Text(l10n.orderIdHeader)),
                          DataColumn(label: Text(l10n.orderDateHeader)),
                          DataColumn(label: Text(l10n.totalProductsHeader)),
                          DataColumn(label: Text(l10n.totalAmountHeader)),
                          DataColumn(label: Text(l10n.statusHeader)),
                        ],
                        rows: _visibleOrders.map((order) {
                          // Pre-format total amount string
                          final String totalAmountStr =
                              "\$" + order.totalAmount.toStringAsFixed(2);

                          // Check if this row is selected
                          final bool isSelected = widget.selectedOrder !=
                                  null &&
                              widget.selectedOrder!.orderId == order.orderId;

                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: (selected) {
                              if (selected == true) {
                                // If same order is clicked again, toggle selection
                                if (isSelected) {
                                  widget.onOrderSelected(null);
                                } else {
                                  widget.onOrderSelected(order);
                                }
                              }
                            },
                            cells: [
                              DataCell(Text(
                                order.orderId,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13.sp,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13.sp,
                                      ),
                              )),
                              DataCell(Text(
                                order.orderDate,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13.sp,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13.sp,
                                      ),
                              )),
                              DataCell(Text(
                                order.totalProducts.toString(),
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13.sp,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13.sp,
                                      ),
                              )),
                              DataCell(Text(
                                totalAmountStr,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13.sp,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13.sp,
                                      ),
                              )),
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Previous page button
                        IconButton(
                          icon: Icon(
                              Icons
                                  .arrow_back, // Always arrow_back for previous
                              size: 20.sp,
                              color: Colors.white70),
                          onPressed: _currentPage > 1
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                }
                              : null,
                        ),
                        // Page buttons.
                        ...List.generate(totalPages, (index) {
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
                                    horizontal: 16.w, vertical: 12.h),
                              ),
                              onPressed: () {
                                setState(() {
                                  _currentPage = pageIndex;
                                });
                              },
                              child: Text(
                                "$pageIndex",
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                              ),
                            ),
                          );
                        }),
                        // Next page button
                        IconButton(
                          icon: Icon(
                              Icons
                                  .arrow_forward, // Always arrow_forward for next
                              size: 20.sp,
                              color: Colors.white70),
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    // Get localized status text
    String displayStatus;
    switch (status) {
      case "Accepted":
        displayStatus = l10n.acceptedStatus;
        break;
      case "Pending":
        displayStatus = l10n.pendingStatus;
        break;
      case "Delivered":
        displayStatus = l10n.deliveredStatus;
        break;
      case "Declined":
        displayStatus = l10n.declinedStatus;
        break;
      case "PartiallyAccepted":
        displayStatus = l10n.partiallyAcceptedStatus;
        break;
      default:
        displayStatus = status;
    }

    Color textColor;
    Color borderColor;
    if (status == "Accepted") {
      textColor = const Color.fromARGB(255, 0, 196, 255); // cyan
      borderColor = textColor;
    } else if (status == "Pending") {
      textColor = const Color.fromARGB(255, 255, 232, 29); // yellow
      borderColor = textColor;
    } else if (status == "Delivered") {
      textColor = const Color.fromARGB(178, 0, 224, 116); // green
      borderColor = textColor;
    } else if (status == "Declined") {
      textColor = const Color.fromARGB(255, 229, 62, 62); // red
      borderColor = textColor;
    } else if (status == "PartiallyAccepted") {
      textColor = const Color.fromARGB(255, 255, 136, 0); // orange
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
        displayStatus,
        style: isArabic
            ? GoogleFonts.cairo(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              )
            : GoogleFonts.spaceGrotesk(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
      ),
    );
  }
}
