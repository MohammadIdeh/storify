import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderModel.dart';

class Vieworder extends StatefulWidget {
  final OrderItem order;
  final bool isSupplierMode; // Added parameter to determine mode

  const Vieworder({
    super.key,
    required this.order,
    this.isSupplierMode = true, // Default to supplier mode
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
    // ... remaining line items
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
                // Top row: "Back" button and "Order Details" with buttons.
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
                    // Show action buttons based on mode
                    if (!widget.isSupplierMode) // Only for Customer mode
                      // "Print Invoice" button.
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 36, 50, 69),
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
                            // Items table and pagination remain unchanged
                            // ... (original code for items table)

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
                                SizedBox(width: 20.w),
                                // Only show confirm/decline buttons for Customer orders and Awaiting status
                                if (!widget.isSupplierMode &&
                                    _localOrder.status == "Awaiting") ...[
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
                              // Change text based on mode
                              widget.isSupplierMode
                                  ? "Supplier info"
                                  : "Customer info",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            _buildInfoRow(
                                "Name",
                                widget.isSupplierMode
                                    ? widget.order.storeName
                                    : "Alex Rose"),
                            _buildInfoRow("Phone", widget.order.phoneNo),
                            _buildInfoRow(
                                "Email",
                                widget.isSupplierMode
                                    ? "supplier@email.com"
                                    : "alex@gmail.com"),
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
                            _buildInfoRow("Name", "Branch Name"),
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

  // Helper methods remain the same
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    // Original implementation
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
    // Original implementation
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
    // Original implementation
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
