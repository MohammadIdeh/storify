// lib/supplier/widgets/orderwidgets/OrderDetailsWidget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/supplier/widgets/orderwidgets/OrderDetails_Model.dart';
import 'package:storify/supplier/widgets/orderwidgets/apiService.dart';
import 'package:storify/utilis/notification_service.dart';

class OrderDetailsWidget extends StatefulWidget {
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
  State<OrderDetailsWidget> createState() => _OrderDetailsWidgetState();
}

class _OrderDetailsWidgetState extends State<OrderDetailsWidget> {
  // Keep track of selected products for decline
  final Map<int, bool> _selectedProducts = {};
  // Keep track of edited prices
  final Map<int, double> _editedPrices = {};
  // Track if any price was edited
  bool get _hasPriceEdits => _editedPrices.isNotEmpty;
  bool get _hasSelectedProducts => _selectedProducts.values.contains(true);

  @override
  void initState() {
    super.initState();
    // Initialize all products as unselected (will be accepted)
    for (var product in widget.orderDetails.products) {
      _selectedProducts[product.id] = false;
    }
  }

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
                if (widget.orderDetails.note != null) _buildNotes(),
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
            onPressed: widget.onClose,
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
                  _buildInfoItem("Order ID", widget.orderDetails.orderId),
                  SizedBox(height: 12.h),
                  _buildInfoItem("Date", widget.orderDetails.orderDate),
                  SizedBox(height: 12.h),
                  _buildInfoItem("Status", widget.orderDetails.status,
                      isStatus: true),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),
                  if (widget.orderDetails.paymentMethod != null)
                    _buildInfoItem(
                        "Payment", widget.orderDetails.paymentMethod!),
                ],
              ),
            ),
          ],
        ),
        if (widget.orderDetails.deliveryAddress != null) ...[
          SizedBox(height: 12.h),
          _buildInfoItem(
              "Delivery Address", widget.orderDetails.deliveryAddress!),
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
    bool showSelectionControls = widget.orderDetails.status == "Pending";
    bool canEditPrices = widget.orderDetails.status == "Pending";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Products",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (showSelectionControls)
              Row(
                children: [
                  if (canEditPrices)
                    Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: Text(
                        "Tap price to edit",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  Text(
                    "Select products to decline",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
          ],
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
            itemCount: widget.orderDetails.products.length,
            separatorBuilder: (context, index) => Divider(
              color: const Color.fromARGB(255, 34, 53, 62),
              height: 1.h,
            ),
            itemBuilder: (context, index) {
              final product = widget.orderDetails.products[index];
              final bool isSelected = _selectedProducts[product.id] ?? false;

              // Get current price (either edited or original)
              final double currentPrice =
                  _editedPrices[product.id] ?? product.price;
              final double currentTotalPrice = currentPrice * product.quantity;

              // Show product status if order is PartiallyAccepted
              final bool showProductStatus =
                  widget.orderDetails.status == "PartiallyAccepted" &&
                      product.status != null;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    // Checkbox for selection (only shown for pending orders)
                    if (showSelectionControls)
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedProducts[product.id] = value ?? false;
                            });
                          },
                          activeColor: const Color.fromARGB(255, 229, 62, 62),
                          checkColor: Colors.white,
                          side: BorderSide(color: Colors.white54),
                        ),
                      ),

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
                          Row(
                            children: [
                              Text(
                                "ID: ${product.productId}",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14.sp,
                                  color: Colors.white70,
                                ),
                              ),
                              if (showProductStatus) ...[
                                SizedBox(width: 8.w),
                                _buildProductStatusPill(product.status!),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Total price display
                        Text(
                          "\$${currentTotalPrice.toStringAsFixed(2)}",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        // Price per unit with edit functionality
                        if (canEditPrices)
                          GestureDetector(
                            onTap: () => _showPriceEditDialog(context, product),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _editedPrices.containsKey(product.id)
                                    ? const Color.fromARGB(255, 105, 65, 198)
                                        .withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: _editedPrices.containsKey(product.id)
                                      ? const Color.fromARGB(255, 105, 65, 198)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${product.quantity} × \$${currentPrice.toStringAsFixed(2)}",
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14.sp,
                                      color:
                                          _editedPrices.containsKey(product.id)
                                              ? const Color.fromARGB(
                                                  255, 105, 65, 198)
                                              : Colors.white70,
                                      fontWeight:
                                          _editedPrices.containsKey(product.id)
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                  if (_editedPrices
                                      .containsKey(product.id)) ...[
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.edit,
                                      size: 12.sp,
                                      color: const Color.fromARGB(
                                          255, 105, 65, 198),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            "${product.quantity} × \$${currentPrice.toStringAsFixed(2)}",
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

  // Method to show price edit dialog
  void _showPriceEditDialog(BuildContext context, OrderProduct product) {
    // Current price (either edited or original)
    final currentPrice = _editedPrices[product.id] ?? product.price;

    // Controller for the text field, initialized with current price
    final TextEditingController priceController = TextEditingController(
      text: currentPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          "Edit Price",
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
              "Product: ${product.name}",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Original Price: \$${product.price.toStringAsFixed(2)}",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Enter new price per unit:",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8.h),
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
                controller: priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                  ),
                  hintText: "0.00",
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white30,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "Quantity: ${product.quantity}",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8.h),
            StatefulBuilder(
              builder: (context, setState) {
                // Try to parse the current price input
                double newPrice = 0.0;
                try {
                  newPrice = double.parse(priceController.text);
                } catch (e) {
                  newPrice = 0.0;
                }

                // Calculate new total
                final double newTotal = newPrice * product.quantity;

                return Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 29, 41, 57),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color.fromARGB(255, 34, 53, 62),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "New Total:",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        "\$${newTotal.toStringAsFixed(2)}",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          // Reset button (only show if the price has been edited)
          if (_editedPrices.containsKey(product.id))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  // Remove this product from edited prices to revert to original
                  _editedPrices.remove(product.id);
                });
              },
              child: Text(
                "Reset to Original",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
              backgroundColor: const Color.fromARGB(255, 105, 65, 198),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            onPressed: () {
              try {
                final double newPrice = double.parse(priceController.text);
                if (newPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Price must be greater than zero'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() {
                  // Only store the edited price if it's different from the original
                  if (newPrice != product.price) {
                    _editedPrices[product.id] = newPrice;
                  } else {
                    // If the price is the same as original, remove it from edited
                    _editedPrices.remove(product.id);
                  }
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              "Update Price",
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

  Widget _buildProductStatusPill(String status) {
    Color color;

    if (status == "Accepted") {
      color = const Color.fromARGB(178, 0, 224, 116); // green
    } else if (status == "Declined") {
      color = const Color.fromARGB(255, 229, 62, 62); // red
    } else {
      color = Colors.white70;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPricingSummary() {
    // Calculate the new total if there are price edits
    double calculatedTotal = 0.0;

    if (_hasPriceEdits) {
      for (var product in widget.orderDetails.products) {
        // Get current price (either edited or original)
        final double currentPrice = _editedPrices[product.id] ?? product.price;
        calculatedTotal += currentPrice * product.quantity;
      }
    } else {
      calculatedTotal = widget.orderDetails.totalAmount;
    }

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
          _buildPriceRow(
            "Total",
            "\$${calculatedTotal.toStringAsFixed(2)}",
            isTotal: true,
            isEdited: _hasPriceEdits,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount,
      {bool isTotal = false, bool isEdited = false}) {
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
        Row(
          children: [
            if (isEdited)
              Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: Icon(
                  Icons.edit,
                  size: 14.sp,
                  color: const Color.fromARGB(255, 105, 65, 198),
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
            widget.orderDetails.note!,
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

    if (widget.orderDetails.status == "Pending") {
      if (_hasSelectedProducts) {
        // When products are selected for decline, show Accept Partially button
        actions = [
          Expanded(
            child: _buildActionButton(
              "Accept Partially" +
                  (_hasPriceEdits ? " with Price Changes" : ""),
              const Color.fromARGB(255, 255, 136, 0), // orange
              () => _showPartialAcceptanceDialog(context),
              isPrimary: true,
            ),
          ),
        ];
      } else {
        // For pending orders without selection, allow accept or decline
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
              "Accept" + (_hasPriceEdits ? " with Price Changes" : ""),
              const Color.fromARGB(255, 105, 65, 198),
              () => _updateOrderStatus(context, "Accepted"),
              isPrimary: true,
            ),
          ),
        ];
      }
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

  // Show dialog for partial acceptance
  void _showPartialAcceptanceDialog(BuildContext context) {
    String note = '';
    final int declinedCount =
        _selectedProducts.values.where((selected) => selected).length;
    final int totalProducts = widget.orderDetails.products.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          "Partially Accept Order",
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
              "You are about to accept this order partially.",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "$declinedCount out of $totalProducts products will be declined.",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_hasPriceEdits) ...[
              SizedBox(height: 8.h),
              Text(
                "${_editedPrices.length} product prices have been modified.",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 105, 65, 198),
                ),
              ),
            ],
            SizedBox(height: 16.h),
            Text(
              "Please provide a reason for partial acceptance:",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8.h),
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
                maxLines: 3,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: _hasPriceEdits
                      ? "e.g., Some products are out of stock and prices updated"
                      : "e.g., Some products are out of stock",
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
              backgroundColor: const Color.fromARGB(255, 255, 136, 0), // orange
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
                    content:
                        Text('Please provide a reason for partial acceptance'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              _acceptPartially(context, note);
            },
            child: Text(
              "Confirm",
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

  // Method to accept order partially
  void _acceptPartially(BuildContext context, String note) {
    // Create list of declined items and price updates
    List<Map<String, dynamic>> declinedItems = [];
    List<Map<String, dynamic>> priceUpdates = [];
    int declinedCount = 0;

    // Process declined products
    _selectedProducts.forEach((itemId, isSelected) {
      if (isSelected) {
        declinedCount++;

        // Find the product to get its productId (not item ID)
        final product = widget.orderDetails.products.firstWhere(
          (p) => p.id == itemId,
        );

        // Send productId (not item ID) to the API
        declinedItems.add({
          "id": product.productId, // Use productId instead of item ID
          "status": "Declined"
        });
      }
    });

    // Process price updates for all non-declined products
    _editedPrices.forEach((itemId, newPrice) {
      // Only update prices for products that are not declined
      final bool isDeclined = _selectedProducts[itemId] ?? false;
      if (!isDeclined) {
        // Find the product to get its productId
        final product = widget.orderDetails.products.firstWhere(
          (p) => p.id == itemId,
        );

        priceUpdates.add({"id": product.productId, "costPrice": newPrice});
      }
    });

    // Combine declined items and price updates
    List<Map<String, dynamic>> updatedItems = [];

    // Add all declined items
    updatedItems.addAll(declinedItems);

    // Add price updates for non-declined items
    updatedItems.addAll(priceUpdates);

    // If all products are declined, change overall status to "Declined"
    final String orderStatus = (declinedCount >=
            widget.orderDetails.products.length)
        ? "Declined"
        : "Accepted"; // If not all products declined, backend will set to PartiallyAccepted

    // Call update method with partial acceptance details
    _updateOrderStatus(
      context,
      orderStatus,
      note: note,
      declinedItems: updatedItems,
    );
  }

  // Method to update order status
  Future<void> _updateOrderStatus(
    BuildContext context,
    String status, {
    String? note,
    List<Map<String, dynamic>>? declinedItems,
  }) async {
    BuildContext? dialogContext;

    try {
      print('Starting order status update: $status');
      print('Note: $note');

      // If accepting the entire order with price changes, create items array with price updates
      if (status == "Accepted" &&
          _hasPriceEdits &&
          (declinedItems == null || declinedItems.isEmpty)) {
        declinedItems = [];

        // Add price updates for all products
        _editedPrices.forEach((itemId, newPrice) {
          // Find the product to get its productId
          final product = widget.orderDetails.products.firstWhere(
            (p) => p.id == itemId,
          );

          declinedItems!.add({"id": product.productId, "costPrice": newPrice});
        });
      }

      print('Updated items: $declinedItems');

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
      final success = await widget.apiService.updateOrderStatus(
        widget.orderDetails.id,
        status,
        note: note,
        declinedItems: declinedItems,
      );

      print('API call completed, success: $success');

      // Close loading dialog
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      if (success) {
        // Send notification to admin
        await _sendStatusUpdateNotification(status, note,
            isPartial: declinedItems != null &&
                declinedItems.isNotEmpty &&
                status == "Accepted" &&
                declinedItems.any((item) => item.containsKey("status")));

        // Show success message
        String statusMessage = status;
        if (status == "Accepted") {
          if (declinedItems != null &&
              declinedItems.isNotEmpty &&
              declinedItems.any((item) => item.containsKey("status"))) {
            statusMessage = "partially accepted";
          } else if (_hasPriceEdits) {
            statusMessage = "accepted with price changes";
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Order ${widget.orderDetails.orderId} has been $statusMessage'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // First call refresh to load new data
        widget.onStatusUpdate();

        // Important: Add a small delay to ensure the API has time to respond
        // before we close the details view and refresh the UI
        await Future.delayed(Duration(milliseconds: 500));

        // Then close the details panel
        widget.onClose();
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
      print('Error in _updateOrderStatus: $e');

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
  Future<void> _sendStatusUpdateNotification(String status, String? note,
      {bool isPartial = false}) async {
    String title = '';
    String message = '';

    if (status == "Accepted") {
      if (isPartial) {
        title = "Order Partially Accepted";
        message =
            "Order ${widget.orderDetails.orderId} has been partially accepted by supplier.";
      } else if (_hasPriceEdits) {
        title = "Order Accepted with Price Changes";
        message =
            "Order ${widget.orderDetails.orderId} has been accepted by supplier with price changes.";
      } else {
        title = "Order Accepted";
        message =
            "Order ${widget.orderDetails.orderId} has been accepted by supplier.";
      }
    } else if (status == "Declined") {
      title = "Order Declined";
      message =
          "Order ${widget.orderDetails.orderId} has been declined by supplier.";
    } else if (status == "Delivered") {
      title = "Order Delivered";
      message =
          "Order ${widget.orderDetails.orderId} has been marked as delivered.";
    }

    if (note != null && note.isNotEmpty) {
      message += " Reason: $note";
    }

    // Create additional data to include with notification
    Map<String, dynamic> additionalData = {
      'orderId': widget.orderDetails.orderId,
      'status': isPartial ? "PartiallyAccepted" : status,
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
