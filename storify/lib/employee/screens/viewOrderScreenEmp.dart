// lib/employee/screens/view_order_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/employee/screens/orders_screen.dart';
import 'package:storify/employee/widgets/orderServiceEmp.dart';

// Line item model for order details
class OrderLineItem {
  final int id;
  final String name;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double total;
  final int productId;

  // Only for supplier orders
  final double? costPrice;
  final String? prodDate;
  final String? expDate;
  final double? originalCostPrice;
  final String? status;

  OrderLineItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.total,
    required this.productId,
    this.costPrice,
    this.prodDate,
    this.expDate,
    this.originalCostPrice,
    this.status,
  });

  // Factory method to create from customer order item
  factory OrderLineItem.fromCustomerJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};

    return OrderLineItem(
      id: json['id'] ?? 0,
      name: product['name'] ?? 'Unknown Product',
      imageUrl: product['image'],
      unitPrice:
          json['Price'] != null ? (json['Price'] as num).toDouble() : 0.0,
      quantity: json['quantity'] ?? 0,
      total:
          json['subtotal'] != null ? (json['subtotal'] as num).toDouble() : 0.0,
      productId: product['productId'] ?? 0,
    );
  }

  // Factory method to create from supplier order item
  factory OrderLineItem.fromSupplierJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};

    return OrderLineItem(
      id: json['id'] ?? 0,
      name: product['name'] ?? 'Unknown Product',
      imageUrl: product['image'],
      unitPrice: json['originalCostPrice'] != null
          ? (json['originalCostPrice'] as num).toDouble()
          : 0.0,
      quantity: json['quantity'] ?? 0,
      total:
          json['subtotal'] != null ? (json['subtotal'] as num).toDouble() : 0.0,
      productId: product['productId'] ?? 0,
      costPrice: json['costPrice'] != null
          ? (json['costPrice'] as num).toDouble()
          : null,
      originalCostPrice: json['originalCostPrice'] != null
          ? (json['originalCostPrice'] as num).toDouble()
          : null,
      status: json['status'],
      prodDate: json['prodDate'],
      expDate: json['expDate'],
    );
  }

  // Create a copy with updated quantity for supplier orders
  OrderLineItem copyWithUpdatedQuantity(int newQuantity) {
    return OrderLineItem(
      id: id,
      name: name,
      imageUrl: imageUrl,
      unitPrice: unitPrice,
      quantity: newQuantity,
      total: unitPrice * newQuantity,
      productId: productId,
      costPrice: costPrice,
      prodDate: prodDate,
      expDate: expDate,
      originalCostPrice: originalCostPrice,
      status: status,
    );
  }

  // Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
    };
  }
}

class ViewOrderScreen extends StatefulWidget {
  final OrderItem order;

  const ViewOrderScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<ViewOrderScreen> createState() => _ViewOrderScreenState();
}

class _ViewOrderScreenState extends State<ViewOrderScreen> {
  late OrderItem _localOrder;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _noteController = TextEditingController();
  Map<String, dynamic>? _orderDetails;
  List<OrderLineItem> _lineItems = [];

  // For supplier orders, track edited quantities
  Map<int, int> _editedQuantities = {};
  bool _hasQuantityChanges = false;

  // Pagination variables
  int _lineItemsCurrentPage = 1;
  final int _lineItemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _localOrder = widget.order;
    _fetchOrderDetails();
  }

  // Fetch order details from API
// Add this to the start of _fetchOrderDetails method
  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch order details based on type
      if (_localOrder.type == "Customer") {
        final response =
            await OrderService.getCustomerOrderDetails(_localOrder.orderId);
        if (response == null) {
          throw Exception("Received null response from API");
        }

        // Debug the response structure
        print('Customer Order Response Structure: ${json.encode(response)}');

        _processCustomerOrderDetails(response);
      } else {
        final response =
            await OrderService.getSupplierOrderDetails(_localOrder.orderId);
        if (response == null) {
          throw Exception("Received null response from API");
        }

        // Debug the response structure
        print('Supplier Order Response Structure: ${json.encode(response)}');

        _processSupplierOrderDetails(response);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchOrderDetails: $e');
      setState(() {
        _errorMessage = 'Error loading order details: $e';
        _isLoading = false;
      });
    }
  }

  void _processCustomerOrderDetails(Map<String, dynamic> response) {
    setState(() {
      _orderDetails = response;

      // Extract the order object which contains all the data
      final orderData = response['order'];
      if (orderData == null) {
        print('Error: No order data found in customer response');
        _lineItems = [];
        _localOrder = widget.order; // Keep existing data
        return;
      }

      // Extract items from the order object
      final items = orderData['items'];
      if (items == null || items.isEmpty) {
        print('Warning: items is null or empty in customer order details');
        _lineItems = [];
      } else {
        _lineItems = (items as List)
            .map((item) => OrderLineItem.fromCustomerJson(item))
            .toList();
      }

      // Extract customer and user data
      final customer = orderData['customer'];
      final user = customer != null ? customer['user'] : null;

      // Format date
      String formattedDate = "N/A";
      if (orderData['createdAt'] != null) {
        try {
          final DateTime orderDate = DateTime.parse(orderData['createdAt']);
          formattedDate =
              '${orderDate.month}-${orderDate.day}-${orderDate.year}';
        } catch (e) {
          print('Error parsing date: ${orderData['createdAt']}');
          final now = DateTime.now();
          formattedDate = '${now.month}-${now.day}-${now.year}';
        }
      } else {
        print('Warning: createdAt is null in order details');
        final now = DateTime.now();
        formattedDate = '${now.month}-${now.day}-${now.year}';
      }

      // Get totalCost
      double totalAmount = 0.0;
      if (orderData['totalCost'] != null) {
        totalAmount = (orderData['totalCost'] as num).toDouble();
      }

      // Update the order object
      _localOrder = OrderItem(
        orderId: orderData['id'] ?? 0,
        name: user != null && user['name'] != null ? user['name'] : 'Unknown',
        phoneNo: user != null && user['phoneNumber'] != null
            ? user['phoneNumber']
            : 'N/A',
        orderDate: formattedDate,
        totalProducts: _lineItems.length,
        totalAmount: totalAmount,
        status: orderData['status'] ?? 'Unknown',
        type: "Customer",
      );
    });
  }

  // Process supplier order details
// In ViewOrderScreen class
  void _processSupplierOrderDetails(Map<String, dynamic> response) {
    setState(() {
      _orderDetails = response;

      // Extract the order object which contains all the data
      final orderData = response['order'];
      if (orderData == null) {
        print('Error: No order data found in supplier response');
        _lineItems = [];
        _localOrder = widget.order; // Keep existing data
        return;
      }

      // Extract items from the order object
      final items = orderData['items'];
      if (items == null || items.isEmpty) {
        print('Warning: items is null or empty in supplier order details');
        _lineItems = [];
      } else {
        _lineItems = (items as List)
            .map((item) => OrderLineItem.fromSupplierJson(item))
            .toList();
      }

      // Extract supplier and user data
      final supplier = orderData['supplier'];
      final user = supplier != null ? supplier['user'] : null;

      // Format date
      String formattedDate = "N/A";
      if (orderData['createdAt'] != null) {
        try {
          final DateTime orderDate = DateTime.parse(orderData['createdAt']);
          formattedDate =
              '${orderDate.month}-${orderDate.day}-${orderDate.year}';
        } catch (e) {
          print('Error parsing date: ${orderData['createdAt']}');
          final now = DateTime.now();
          formattedDate = '${now.month}-${now.day}-${now.year}';
        }
      } else {
        print('Warning: createdAt is null in order details');
        final now = DateTime.now();
        formattedDate = '${now.month}-${now.day}-${now.year}';
      }

      // Get totalCost
      double totalAmount = 0.0;
      if (orderData['totalCost'] != null) {
        totalAmount = (orderData['totalCost'] as num).toDouble();
      }

      // Update the order object
      _localOrder = OrderItem(
        orderId: orderData['id'] ?? 0,
        name: user != null && user['name'] != null ? user['name'] : 'Unknown',
        phoneNo: user != null && user['phoneNumber'] != null
            ? user['phoneNumber']
            : 'N/A',
        orderDate: formattedDate,
        totalProducts: _lineItems.length,
        totalAmount: totalAmount,
        status: orderData['status'] ?? 'Unknown',
        type: "Supplier",
      );
    });
  }

  // Refresh order data
  Future<void> _refreshOrderData() async {
    await _fetchOrderDetails();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order data refreshed'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color.fromARGB(255, 0, 196, 255),
      ),
    );
  }

  // Update customer order status
  Future<void> _updateCustomerOrderStatus(String newStatus) async {
    // Check if order is already in this status
    if (_localOrder.status == newStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order is already in $newStatus status'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final note = _noteController.text.trim();

      // Update order status
      await OrderService.updateCustomerOrderStatus(
          _localOrder.orderId, newStatus, note.isNotEmpty ? note : null);

      // Refresh order data
      await _fetchOrderDetails();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated to $newStatus successfully'),
          backgroundColor: const Color.fromARGB(178, 0, 224, 116),
        ),
      );

      // If transitioning to Prepared, return to previous screen after delay
      if (newStatus == "Prepared") {
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, _localOrder);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating order: $e';
        _isLoading = false;
      });
    }
  }

  // Update supplier order status
  Future<void> _updateSupplierOrderStatus(String newStatus) async {
    // Check if order is already in this status
    if (_localOrder.status == newStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order is already in $newStatus status'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final note = _noteController.text.trim();

      // Prepare updated items if there are quantity changes
      List<Map<String, dynamic>>? updatedItems;
      if (_hasQuantityChanges) {
        updatedItems = _editedQuantities.entries.map((entry) {
          return {
            'id': entry.key,
            'quantity': entry.value,
          };
        }).toList();
      }

      // Update order status
      await OrderService.updateSupplierOrderStatus(_localOrder.orderId,
          newStatus, note.isNotEmpty ? note : null, updatedItems);

      // Refresh order data
      await _fetchOrderDetails();

      // Reset edited quantities
      setState(() {
        _editedQuantities.clear();
        _hasQuantityChanges = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated to $newStatus successfully'),
          backgroundColor: const Color.fromARGB(178, 0, 224, 116),
        ),
      );

      // If transitioning to Delivered, return to previous screen after delay
      if (newStatus == "Delivered") {
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, _localOrder);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating order: $e';
        _isLoading = false;
      });
    }
  }

  // Update item quantity for supplier orders
  void _updateItemQuantity(int itemId, int newQuantity) {
    if (newQuantity <= 0) return;

    setState(() {
      _editedQuantities[itemId] = newQuantity;
      _hasQuantityChanges = true;

      // Update the displayed item for the UI
      final index = _lineItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final updatedItem =
            _lineItems[index].copyWithUpdatedQuantity(newQuantity);
        _lineItems[index] = updatedItem;
      }
    });
  }

  // Calculate visible line items for pagination
  List<OrderLineItem> get _visibleLineItems {
    final totalItems = _lineItems.length;
    if (totalItems == 0) return [];

    final totalPages = (totalItems / _lineItemsPerPage).ceil();
    if (_lineItemsCurrentPage > totalPages && totalPages > 0) {
      _lineItemsCurrentPage = 1;
    }
    final startIndex = (_lineItemsCurrentPage - 1) * _lineItemsPerPage;
    int endIndex = startIndex + _lineItemsPerPage;
    if (endIndex > totalItems) endIndex = totalItems;
    return _lineItems.sublist(startIndex, endIndex);
  }

  // Calculate total amount based on current line items (including edited quantities)
  double get _calculatedTotal {
    return _lineItems.fold(0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire build method in a try-catch to prevent app crashes
    try {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 29, 41, 57),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: const Color.fromARGB(255, 105, 65, 198),
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 48.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16.sp,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: _refreshOrderData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 105, 65, 198),
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            child: Text(
                              'Go Back',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding:
                            EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Content same as before...
                            // Top row: "Back" button and "Order Details" with buttons
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 29, 41, 57),
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
                                    Navigator.pop(context, _localOrder);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_back,
                                        color: const Color.fromARGB(
                                            255, 105, 123, 123),
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'Back',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color.fromARGB(
                                              255, 105, 123, 123),
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
                                    color: const Color.fromARGB(
                                        255, 246, 246, 246),
                                  ),
                                ),
                                const Spacer(),
                                // Print Invoice button
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
                                    // Print Invoice action placeholder
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Printing invoice...'),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Print Invoice',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color.fromARGB(
                                          255, 105, 123, 123),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30.h),

                            // Rest of the content...
                            // (Keep the entire existing UI structure here)
                            // Main content row: left (items table) + right (order details)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left side: Items table (flex = 2)
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color.fromARGB(255, 36, 50, 69),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(30.r),
                                        topRight: Radius.circular(30.r),
                                        bottomRight: Radius.circular(30.r),
                                        bottomLeft: Radius.circular(30.r),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        // Items table
                                        _lineItems.isEmpty
                                            ? Center(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 30.h),
                                                  child: Text(
                                                    "No items found for this order",
                                                    style: GoogleFonts
                                                        .spaceGrotesk(
                                                      fontSize: 16.sp,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: DataTable(
                                                  dataRowColor:
                                                      MaterialStateProperty
                                                          .resolveWith<Color?>(
                                                    (Set<MaterialState>
                                                            states) =>
                                                        Colors.transparent,
                                                  ),
                                                  headingRowColor:
                                                      MaterialStateProperty.all<
                                                          Color>(
                                                    const Color.fromARGB(
                                                        255, 47, 71, 82),
                                                  ),
                                                  border: TableBorder(
                                                    horizontalInside:
                                                        BorderSide(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                    ),
                                                  ),
                                                  columnSpacing: 20.w,
                                                  columns: [
                                                    DataColumn(
                                                      label: Text(
                                                        "Image",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        "Item",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        "Unit Price",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      numeric: true,
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        "Qty",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      numeric: true,
                                                    ),
                                                    // Add Qty controls for supplier orders in Accepted status
                                                    if (_localOrder.type ==
                                                            "Supplier" &&
                                                        _localOrder.status ==
                                                            "Accepted")
                                                      DataColumn(
                                                        label: Text(
                                                          "Edit Qty",
                                                          style: GoogleFonts
                                                              .spaceGrotesk(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    DataColumn(
                                                      label: Text(
                                                        "Total",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      numeric: true,
                                                    ),
                                                  ],
                                                  rows: _visibleLineItems
                                                      .map((item) {
                                                    // Pre-format all strings for display
                                                    final String nameStr =
                                                        item.name;
                                                    final String unitPriceStr =
                                                        "\$${item.unitPrice.toStringAsFixed(2)}";
                                                    final String qtyStr = item
                                                        .quantity
                                                        .toString();
                                                    final String totalStr =
                                                        "\$${item.total.toStringAsFixed(2)}";

                                                    return DataRow(
                                                      cells: [
                                                        // Image cell
                                                        DataCell(
                                                          Container(
                                                            width: 40.w,
                                                            height: 40.h,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6.r),
                                                            ),
                                                            child:
                                                                item.imageUrl !=
                                                                        null
                                                                    ? ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(6.r),
                                                                        child: Image
                                                                            .network(
                                                                          item.imageUrl!,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          errorBuilder: (context,
                                                                              error,
                                                                              stackTrace) {
                                                                            return Icon(
                                                                              Icons.image_not_supported_outlined,
                                                                              color: Colors.white54,
                                                                              size: 20.sp,
                                                                            );
                                                                          },
                                                                        ),
                                                                      )
                                                                    : Icon(
                                                                        Icons
                                                                            .image_outlined,
                                                                        color: Colors
                                                                            .white54,
                                                                        size: 20
                                                                            .sp,
                                                                      ),
                                                          ),
                                                        ),
                                                        // Name cell
                                                        DataCell(Text(
                                                          nameStr,
                                                          style: GoogleFonts
                                                              .spaceGrotesk(
                                                            color: Colors.white,
                                                          ),
                                                        )),
                                                        // Unit price cell
                                                        DataCell(Text(
                                                          unitPriceStr,
                                                          style: GoogleFonts
                                                              .spaceGrotesk(
                                                            color: Colors.white,
                                                          ),
                                                        )),
                                                        // Quantity cell
                                                        DataCell(Text(
                                                          qtyStr,
                                                          style: GoogleFonts
                                                              .spaceGrotesk(
                                                            color: Colors.white,
                                                          ),
                                                        )),
                                                        // Edit Quantity controls for supplier orders in Accepted status
                                                        if (_localOrder.type ==
                                                                "Supplier" &&
                                                            _localOrder
                                                                    .status ==
                                                                "Accepted")
                                                          DataCell(
                                                            Row(
                                                              children: [
                                                                // Decrease button
                                                                InkWell(
                                                                  onTap: () {
                                                                    if (item.quantity >
                                                                        1) {
                                                                      _updateItemQuantity(
                                                                          item
                                                                              .id,
                                                                          item.quantity -
                                                                              1);
                                                                    }
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    width: 24.w,
                                                                    height:
                                                                        24.h,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .red
                                                                          .withOpacity(
                                                                              0.2),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              4.r),
                                                                    ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .remove,
                                                                      color: Colors
                                                                          .white,
                                                                      size:
                                                                          16.sp,
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 6.w),
                                                                // Increase button
                                                                InkWell(
                                                                  onTap: () {
                                                                    _updateItemQuantity(
                                                                        item.id,
                                                                        item.quantity +
                                                                            1);
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    width: 24.w,
                                                                    height:
                                                                        24.h,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .green
                                                                          .withOpacity(
                                                                              0.2),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              4.r),
                                                                    ),
                                                                    child: Icon(
                                                                      Icons.add,
                                                                      color: Colors
                                                                          .white,
                                                                      size:
                                                                          16.sp,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        // Total cell
                                                        DataCell(Text(
                                                          totalStr,
                                                          style: GoogleFonts
                                                              .spaceGrotesk(
                                                            color: Colors.white,
                                                          ),
                                                        )),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ),

                                        // Pagination controls if more than one page
                                        if (_lineItems.length >
                                            _lineItemsPerPage) ...[
                                          SizedBox(height: 16.h),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.arrow_back_ios,
                                                  color: Colors.white,
                                                  size: 16.sp,
                                                ),
                                                onPressed:
                                                    _lineItemsCurrentPage > 1
                                                        ? () {
                                                            setState(() {
                                                              _lineItemsCurrentPage--;
                                                            });
                                                          }
                                                        : null,
                                              ),
                                              Text(
                                                "Page $_lineItemsCurrentPage of ${(_lineItems.length / _lineItemsPerPage).ceil()}",
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Colors.white,
                                                  size: 16.sp,
                                                ),
                                                onPressed: _lineItemsCurrentPage <
                                                        (_lineItems.length /
                                                                _lineItemsPerPage)
                                                            .ceil()
                                                    ? () {
                                                        setState(() {
                                                          _lineItemsCurrentPage++;
                                                        });
                                                      }
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ],

                                        SizedBox(height: 20.h),
                                        // Grand Total
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 6.h),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "Grand Total: ",
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                Text(
                                                  "\$${_calculatedTotal.toStringAsFixed(2)}",
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Show changes warning if quantities were edited
                                        if (_hasQuantityChanges) ...[
                                          SizedBox(height: 10.h),
                                          Container(
                                            padding: EdgeInsets.all(10.w),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.amber.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              border: Border.all(
                                                  color: Colors.amber),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.amber,
                                                  size: 20.sp,
                                                ),
                                                SizedBox(width: 10.w),
                                                Expanded(
                                                  child: Text(
                                                    "You have made changes to item quantities. These changes will be applied when updating the order status.",
                                                    style: GoogleFonts
                                                        .spaceGrotesk(
                                                      fontSize: 12.sp,
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20.w),

                                // Right side: Order Info and Customer/Supplier Info
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color.fromARGB(255, 36, 50, 69),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        _buildInfoRow("Order ID",
                                            _localOrder.orderId.toString()),
                                        _buildInfoRow("Order Date",
                                            _localOrder.orderDate),
                                        _buildInfoRow(
                                            "Order Type", _localOrder.type),
                                        SizedBox(height: 6.h),
                                        if (_localOrder.type == "Customer" &&
                                            _orderDetails != null)
                                          _buildInfoRow(
                                              "Payment Status",
                                              (_orderDetails!['amountPaid'] !=
                                                          null &&
                                                      (_orderDetails![
                                                                  'amountPaid']
                                                              as num) >
                                                          0)
                                                  ? "Paid"
                                                  : "Pending"),
                                        Divider(
                                            color: Colors.white24,
                                            height: 20.h),
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
                                            _buildStatusPill(
                                                _localOrder.status),
                                          ],
                                        ),

                                        // Show order action buttons based on type and status
                                        if (_localOrder.type == "Customer" &&
                                            _localOrder.status ==
                                                "Accepted") ...[
                                          SizedBox(height: 20.h),
                                          Text(
                                            "Order Actions:",
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white54,
                                            ),
                                          ),
                                          SizedBox(height: 10.h),
                                          // Add note field for actions
                                          TextField(
                                            controller: _noteController,
                                            maxLines: 3,
                                            style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Add a note about this action (optional)...',
                                              hintStyle:
                                                  GoogleFonts.spaceGrotesk(
                                                      color: Colors.white38),
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.05),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.all(12.w),
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          // Start Preparing button
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 255, 150, 30),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12.h),
                                              minimumSize:
                                                  Size(double.infinity, 45.h),
                                            ),
                                            onPressed: () =>
                                                _updateCustomerOrderStatus(
                                                    "Preparing"),
                                            child: Text(
                                              "Start Preparing",
                                              style: GoogleFonts.spaceGrotesk(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],

                                        // For Customer Preparing status, show Mark as Prepared button
                                        if (_localOrder.type == "Customer" &&
                                            _localOrder.status ==
                                                "Preparing") ...[
                                          SizedBox(height: 20.h),
                                          Text(
                                            "Order Actions:",
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white54,
                                            ),
                                          ),
                                          SizedBox(height: 10.h),
                                          // Add note field for actions
                                          TextField(
                                            controller: _noteController,
                                            maxLines: 3,
                                            style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Add a note about this action (optional)...',
                                              hintStyle:
                                                  GoogleFonts.spaceGrotesk(
                                                      color: Colors.white38),
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.05),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.all(12.w),
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          // Mark as Prepared button
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      178, 0, 224, 116),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12.h),
                                              minimumSize:
                                                  Size(double.infinity, 45.h),
                                            ),
                                            onPressed: () =>
                                                _updateCustomerOrderStatus(
                                                    "Prepared"),
                                            child: Text(
                                              "Mark as Prepared",
                                              style: GoogleFonts.spaceGrotesk(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],

                                        // For Supplier Accepted status, show Mark as Delivered button
                                        if (_localOrder.type == "Supplier" &&
                                            _localOrder.status ==
                                                "Accepted") ...[
                                          SizedBox(height: 20.h),
                                          Text(
                                            "Order Actions:",
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white54,
                                            ),
                                          ),
                                          SizedBox(height: 10.h),
                                          // Add note field for actions
                                          TextField(
                                            controller: _noteController,
                                            maxLines: 3,
                                            style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Add a note about this action (optional)...',
                                              hintStyle:
                                                  GoogleFonts.spaceGrotesk(
                                                      color: Colors.white38),
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.05),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.all(12.w),
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          // Mark as Delivered button
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      178, 0, 224, 116),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12.h),
                                              minimumSize:
                                                  Size(double.infinity, 45.h),
                                            ),
                                            onPressed: () =>
                                                _updateSupplierOrderStatus(
                                                    "Delivered"),
                                            child: Text(
                                              "Mark as Delivered",
                                              style: GoogleFonts.spaceGrotesk(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],

                                        SizedBox(height: 20.h),
                                        Text(
                                          _localOrder.type == "Supplier"
                                              ? "Supplier Info"
                                              : "Customer Info",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 10.h),
                                        _buildInfoRow("Name", _localOrder.name),
                                        _buildInfoRow(
                                            "Phone", _localOrder.phoneNo),

                                        // Show email if available in the API response
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
    } catch (e) {
      // If any error occurs during build, show a fallback error screen
      print('Error in view order screen build: $e');
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 29, 41, 57),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Error displaying order details: $e',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Helper method to build info rows
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

  // Helper method to build status pills
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
        textColor = const Color.fromARGB(178, 0, 224, 116); // green
        borderColor = textColor;
        break;
      case "Preparing":
        textColor = const Color.fromARGB(255, 255, 150, 30); // orange
        borderColor = textColor;
        break;
      default:
        textColor = Colors.white70;
        borderColor = Colors.white54;
        break;
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
