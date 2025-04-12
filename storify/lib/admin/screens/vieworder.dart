import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/OrderWidgets/orderModel.dart';

class Vieworder extends StatefulWidget {
  final OrderItem order;

  const Vieworder({
    super.key,
    required this.order,
  });

  @override
  State<Vieworder> createState() => _VieworderState();
}

class _VieworderState extends State<Vieworder> {
  late OrderItem _localOrder;

  // Fake line items to show in the "Items" table.
  // In a real app, these could come from the order itself (API or database).
  final List<OrderLineItem> _lineItems = [
    OrderLineItem(
      name: "Chicken Dumplings",
      extra: "Extra Onions, Sauce",
      size: "Large",
      unitPrice: 10.0,
      quantity: 1,
    ),
    OrderLineItem(
      name: "Tuna Salad",
      extra: "Spicy",
      size: "1l",
      unitPrice: 35.0,
      quantity: 1,
    ),
    OrderLineItem(
      name: "Cheese Burger",
      extra: "Extra Cheese",
      size: "1",
      unitPrice: 5.50,
      quantity: 2,
    ),
    OrderLineItem(
      name: "Hot & Sour Soup",
      extra: "Medium Spicy",
      size: "2",
      unitPrice: 8.00,
      quantity: 1,
    ),
    OrderLineItem(
      name: "Steak Sandwich",
      extra: "N/A",
      size: "Large",
      unitPrice: 15.0,
      quantity: 1,
    ),
    // Additional items to test pagination:
    OrderLineItem(
      name: "Steak Sandwich",
      extra: "N/A",
      size: "Large",
      unitPrice: 15.0,
      quantity: 1,
    ),
    OrderLineItem(
      name: "Steak Sandwich",
      extra: "N/A",
      size: "Large",
      unitPrice: 15.0,
      quantity: 1,
    ),
    OrderLineItem(
      name: "Extra Item",
      extra: "New Addition",
      size: "Medium",
      unitPrice: 12.0,
      quantity: 1,
    ),
  ];

  // Pagination variables for line items table.
  int _lineItemsCurrentPage = 1;
  final int _lineItemsPerPage = 7;

  /// Computes the visible line items for the current page.
  List<OrderLineItem> get _visibleLineItems {
    final totalItems = _lineItems.length;
    final totalPages = (totalItems / _lineItemsPerPage).ceil();
    if (_lineItemsCurrentPage > totalPages && totalPages > 0) {
      _lineItemsCurrentPage = 1;
    }
    final startIndex = (_lineItemsCurrentPage - 1) * _lineItemsPerPage;
    int endIndex = startIndex + _lineItemsPerPage;
    if (endIndex > totalItems) endIndex = totalItems;
    return _lineItems.sublist(startIndex, endIndex);
  }

  @override
  void initState() {
    super.initState();
    // Make a local copy so we can modify status, etc.
    _localOrder = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the overall summary based on all line items.
    double subTotal = _lineItems.fold(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    double discount = 10.0; // fixed example
    double serviceCharge = 5.0; // fixed example
    double grandTotal = subTotal - discount + serviceCharge;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: "Back" button and "Order Details".
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 29, 41, 57),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1.5,
                            color: Color.fromARGB(255, 47, 71, 82),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        fixedSize: Size(120.w, 50.h),
                        elevation: 1,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/back.svg',
                            width: 18.w,
                            height: 18.h,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Back',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color.fromARGB(255, 105, 123, 123),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Text(
                      "Order Details",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 246, 246, 246),
                      ),
                    ),
                    const Spacer(),
                    // "Cancel" button.
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1.5,
                            color: Color.fromARGB(255, 47, 71, 82),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        fixedSize: Size(120.w, 50.h),
                        elevation: 1,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 105, 123, 123),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // "Print Invoice" button.
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1.5,
                            color: Color.fromARGB(255, 47, 71, 82),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        fixedSize: Size(220.w, 50.h),
                        elevation: 1,
                      ),
                      onPressed: () {
                        // Print Invoice action placeholder.
                      },
                      child: Text(
                        'Print Invoice',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 105, 123, 123),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                // Main content row: left (items table) + right (order details).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Items table (flex = 2).
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 36, 50, 69),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30.r),
                            topRight: Radius.circular(30.r),
                            bottomRight: Radius.circular(30.r),
                            bottomLeft: Radius.circular(30.r),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Items",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            // Wrap the DataTable in a LayoutBuilder to enforce full width.
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Define colors and border styles.
                                final Color customHeaderColor =
                                    const Color.fromARGB(76, 22, 67,
                                        102); // your custom header color
                                final BorderSide dividerSide = BorderSide(
                                  color: const Color.fromARGB(255, 48, 62, 82),
                                  width: 1,
                                );
                                final BorderSide dividerSide2 = BorderSide(
                                  color: const Color.fromARGB(255, 36, 50, 69),
                                  width: 2,
                                );

                                return ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth),
                                      child: DataTable(
                                        dataRowColor: WidgetStateProperty
                                            .resolveWith<Color?>(
                                          (Set<WidgetState> states) =>
                                              Colors.transparent,
                                        ),
                                        showCheckboxColumn: false,
                                        // Set header background to a different color.
                                        headingRowColor:
                                            MaterialStateProperty.all<Color>(
                                                customHeaderColor),
                                        // Apply borders around the table and between cells.
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
                                        headingTextStyle:
                                            GoogleFonts.spaceGrotesk(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        dataTextStyle: GoogleFonts.spaceGrotesk(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13.sp,
                                        ),
                                        // Define columns.
                                        columns: const [
                                          DataColumn(label: Text("No.")),
                                          DataColumn(label: Text("Item")),
                                          DataColumn(label: Text("Size")),
                                          DataColumn(label: Text("Unit Price")),
                                          DataColumn(label: Text("Quantity")),
                                          DataColumn(label: Text("Total")),
                                        ],
                                        // Build rows from your visible line items.
                                        rows: _visibleLineItems
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          final totalPrice =
                                              item.unitPrice * item.quantity;
                                          return DataRow(
                                            cells: [
                                              DataCell(Text("${index + 1}")),
                                              DataCell(
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(item.name),
                                                    if (item.extra.isNotEmpty)
                                                      Text(
                                                        item.extra,
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color: Colors.white54,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(Text(item.size)),
                                              DataCell(
                                                  Text("\$${item.unitPrice}")),
                                              DataCell(
                                                  Text("${item.quantity}")),
                                              DataCell(Text(
                                                  "\$${totalPrice.toStringAsFixed(2)}")),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 10.h),
                            // Pagination Row for line items.
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final totalItems = _lineItems.length;
                                final totalPages =
                                    (totalItems / _lineItemsPerPage).ceil();
                                return Row(
                                  children: [
                                    const Spacer(),
                                    Text(
                                      "Total $totalItems items",
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    IconButton(
                                      icon: Icon(Icons.arrow_back,
                                          size: 20.sp, color: Colors.white70),
                                      onPressed: _lineItemsCurrentPage > 1
                                          ? () {
                                              setState(() {
                                                _lineItemsCurrentPage--;
                                              });
                                            }
                                          : null,
                                    ),
                                    Row(
                                      children:
                                          List.generate(totalPages, (index) {
                                        final pageIndex = index + 1;
                                        final bool isSelected = (pageIndex ==
                                            _lineItemsCurrentPage);
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 4.w),
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: isSelected
                                                  ? const Color.fromARGB(
                                                      255, 105, 65, 198)
                                                  : Colors.transparent,
                                              side: BorderSide(
                                                color: const Color.fromARGB(
                                                    255, 34, 53, 62),
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 14.w,
                                                  vertical: 10.h),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _lineItemsCurrentPage =
                                                    pageIndex;
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
                                    IconButton(
                                      icon: Icon(Icons.arrow_forward,
                                          size: 20.sp, color: Colors.white70),
                                      onPressed:
                                          _lineItemsCurrentPage < totalPages
                                              ? () {
                                                  setState(() {
                                                    _lineItemsCurrentPage++;
                                                  });
                                                }
                                              : null,
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: 20.h),
                            // Summary Rows (Subtotal, Discount, Service Charge, Grand Total)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildSummaryRow("Subtotal",
                                      "\$${subTotal.toStringAsFixed(2)}"),
                                  _buildSummaryRow("Discount(10)",
                                      "-\$${discount.toStringAsFixed(2)}"),
                                  _buildSummaryRow("Service Charge(5)",
                                      "\$${serviceCharge.toStringAsFixed(2)}"),
                                  SizedBox(height: 5.h),
                                  _buildSummaryRow("Grand Total",
                                      "\$${grandTotal.toStringAsFixed(2)}",
                                      isBold: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    // Right side: Order Info, Payment, Customer Info, Branch Info (flex = 1).
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 36, 50, 69),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Order Info",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            _buildInfoRow("Order ID", widget.order.orderId),
                            _buildInfoRow(
                                "Delivery Date", widget.order.orderDate),
                            _buildInfoRow("Delivery Time", "22:16"),
                            SizedBox(height: 6.h),
                            _buildInfoRow("Payment Status", "Delivered"),
                            _buildInfoRow("Payment Method", "Cash"),
                            Divider(color: Colors.white24, height: 20.h),
                            Row(
                              children: [
                                Text(
                                  "Status:",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white54,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                _buildStatusPill(_localOrder.status),
                                SizedBox(
                                  width: 20.w,
                                ),
                                if (_localOrder.status == "Awaiting") ...[
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 0, 224, 116),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          final updated = _localOrder.copyWith(
                                              status: "Accepted");
                                          Navigator.pop(context, updated);
                                        },
                                        child: Text(
                                          "Confirm",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 229, 62, 62),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          final updated = _localOrder.copyWith(
                                              status: "Declined");
                                          Navigator.pop(context, updated);
                                        },
                                        child: Text(
                                          "Decline",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              "Customer info",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            _buildInfoRow("Name", "Alex Rose"),
                            _buildInfoRow("Phone", widget.order.phoneNo),
                            _buildInfoRow("Email", "alex@gmail.com"),
                            Divider(color: Colors.white24, height: 20.h),
                            Text(
                              "Branch info",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            _buildInfoRow("Name", widget.order.storeName),
                            _buildInfoRow("Phone", "972694737544"),
                            _buildInfoRow(
                                "Address", "19th St, Ummra, Jeddah 1230"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "$label ",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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

// Optionally define a model for line items.
class OrderLineItem {
  final String name;
  final String extra;
  final String size;
  final double unitPrice;
  final int quantity;

  OrderLineItem({
    required this.name,
    required this.extra,
    required this.size,
    required this.unitPrice,
    required this.quantity,
  });
}
