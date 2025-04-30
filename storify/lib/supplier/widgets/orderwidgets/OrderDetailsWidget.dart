// lib/supplier/widgets/orderwidgets/OrderDetailsWidget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/supplier/widgets/orderwidgets/OrderDetails_Model.dart';
import 'package:storify/supplier/widgets/orderwidgets/apiService.dart';
import 'package:storify/utilis/notification_service.dart';

class OrderDetailsWidget extends StatelessWidget {
  final Order orderDetails;
  final VoidCallback onClose;
  final VoidCallback onStatusUpdate;
  final ApiService apiService;

  const OrderDetailsWidget({
    Key? key,
    required this.orderDetails,
    required this.onClose,
    required this.onStatusUpdate,
    required this.apiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color.fromARGB(255, 34, 53, 62),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          _buildHeader(),

          // Order info sections
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                _buildOrderInfo(),
                SizedBox(height: 24.h),
                _buildProductsList(),
                SizedBox(height: 24.h),
                _buildPricingSummary(),
                SizedBox(height: 16.h),
                if (orderDetails.note != null) _buildNotes(),
                SizedBox(height: 24.h),
                _buildActionButtons(context),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 41, 57),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Order Details",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              color: Colors.white70,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Order Information",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem("Order ID", orderDetails.orderId),
                  SizedBox(height: 12.h),
                  _buildInfoItem("Date", orderDetails.orderDate),
                  SizedBox(height: 12.h),
                  _buildInfoItem("Status", orderDetails.status, isStatus: true),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),
                  if (orderDetails.paymentMethod != null)
                    _buildInfoItem("Payment", orderDetails.paymentMethod!),
                ],
              ),
            ),
          ],
        ),
        if (orderDetails.deliveryAddress != null) ...[
          SizedBox(height: 12.h),
          _buildInfoItem("Delivery Address", orderDetails.deliveryAddress!),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isStatus = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 4.h),
        if (isStatus)
          _buildStatusPill(value)
        else
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
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

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Products",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 29, 41, 57),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color.fromARGB(255, 34, 53, 62),
              width: 1,
            ),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: orderDetails.products.length,
            separatorBuilder: (context, index) => Divider(
              color: const Color.fromARGB(255, 34, 53, 62),
              height: 1.h,
            ),
            itemBuilder: (context, index) {
              final product = orderDetails.products[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 36, 50, 69),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: product.imageUrl != null
                            ? Image.network(
                                product.imageUrl!,
                                width: 40.w,
                                height: 40.h,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white70,
                                size: 24.sp,
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "ID: ${product.productId}",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "\$${product.totalPrice.toStringAsFixed(2)}",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "${product.quantity} × \$${product.price.toStringAsFixed(2)}",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSummary() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 41, 57),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color.fromARGB(255, 34, 53, 62),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // _buildPriceRow(
          //     "Subtotal", "\$${orderDetails.subtotal.toStringAsFixed(2)}"),
          // SizedBox(height: 12.h),
          // _buildPriceRow("Delivery Fee",
          //     "\$${orderDetails.deliveryFee.toStringAsFixed(2)}"),
          // SizedBox(height: 12.h),
          // Divider(
          //   color: const Color.fromARGB(255, 34, 53, 62),
          //   height: 1.h,
          // ),
          // SizedBox(height: 12.h),
          _buildPriceRow(
            "Total",
            "\$${orderDetails.totalAmount.toStringAsFixed(2)}",
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.white : Colors.white70,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.spaceGrotesk(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal
                ? const Color.fromARGB(255, 105, 65, 198)
                : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notes",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 29, 41, 57),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color.fromARGB(255, 34, 53, 62),
              width: 1,
            ),
          ),
          child: Text(
            orderDetails.note!,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.sp,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Actions depend on the current status
    List<Widget> actions = [];

    if (orderDetails.status == "Pending") {
      // For pending orders, allow accept or decline
      actions = [
        Expanded(
          child: _buildActionButton(
            "Decline",
            const Color.fromARGB(255, 229, 62, 62),
            () => _showDeclineDialog(context),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildActionButton(
            "Accept",
            const Color.fromARGB(255, 105, 65, 198),
            () => _updateOrderStatus(context, "Accepted"),
            isPrimary: true,
          ),
        ),
      ];
    } else {
      // For other statuses, just show a print invoice button
      actions = [
        Expanded(
          child: _buildActionButton(
            "Print Invoice",
            const Color.fromARGB(255, 105, 65, 198),
            () {},
            isPrimary: true,
          ),
        ),
      ];
    }

    return Row(children: actions);
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.transparent,
        foregroundColor: isPrimary ? Colors.white : color,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        elevation: isPrimary ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: color,
            width: 1.5,
          ),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Method to update order status
  Future<void> _updateOrderStatus(BuildContext context, String status,
      {String? note}) async {
    BuildContext? dialogContext;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Call API
      final success = await apiService
          .updateOrderStatus(orderDetails.id, status, note: note);

      // Close loading dialog
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      if (success) {
        // Send notification to admin
        await _sendStatusUpdateNotification(status, note);

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${orderDetails.orderId} has been $status'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // First call refresh to load new data
        onStatusUpdate();

        // Important: Add a small delay to ensure the API has time to respond
        // before we close the details view and refresh the UI
        await Future.delayed(Duration(milliseconds: 300));

        // Then close the details panel
        onClose();
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update order status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to send notification to admin about order status update
  Future<void> _sendStatusUpdateNotification(
      String status, String? note) async {
    String title = '';
    String message = '';

    if (status == "Accepted") {
      title = "Order Accepted";
      message = "Order ${orderDetails.orderId} has been accepted by supplier.";
    } else if (status == "Declined") {
      title = "Order Declined";
      message = "Order ${orderDetails.orderId} has been declined by supplier.";
      if (note != null && note.isNotEmpty) {
        message += " Reason: $note";
      }
    } else if (status == "Delivered") {
      title = "Order Delivered";
      message = "Order ${orderDetails.orderId} has been marked as delivered.";
    }

    // Create additional data to include with notification
    Map<String, dynamic> additionalData = {
      'orderId': orderDetails.orderId,
      'status': status,
      'type': 'order_status',
      'timestamp': DateTime.now().toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
    };

    // Send notification to admin
    await NotificationService()
        .sendNotificationToAdmin(title, message, additionalData);
  }

// Method to show decline dialog with note field
  void _showDeclineDialog(BuildContext context) {
    String note = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          "Decline Order",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please provide a reason for declining this order:",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 29, 41, 57),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color.fromARGB(255, 34, 53, 62),
                  width: 1,
                ),
              ),
              child: TextField(
                maxLines: 4,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: "Enter reason...",
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white30,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12.r),
                ),
                onChanged: (value) {
                  note = value;
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 229, 62, 62),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            onPressed: () {
              if (note.trim().isEmpty) {
                // Show validation error if note is empty
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please provide a reason for declining'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _updateOrderStatus(context, "Declined", note: note);
            },
            child: Text(
              "Decline",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
