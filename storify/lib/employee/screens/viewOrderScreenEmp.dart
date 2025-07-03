// lib/employee/screens/view_order_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/employee/screens/orders_screen.dart';
import 'package:storify/employee/widgets/orderServiceEmp.dart';

// Batch Alert model
class BatchAlert {
  final int productId;
  final String productName;
  final String alertType;
  final String alertMessage;
  final List<ExistingBatch> existingBatches;
  final SupplierDates supplierDates;

  BatchAlert({
    required this.productId,
    required this.productName,
    required this.alertType,
    required this.alertMessage,
    required this.existingBatches,
    required this.supplierDates,
  });

  factory BatchAlert.fromJson(Map<String, dynamic> json) {
    return BatchAlert(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      alertType: json['alertType'] ?? '',
      alertMessage: json['alertMessage'] ?? '',
      existingBatches: (json['existingBatches'] as List? ?? [])
          .map((batch) => ExistingBatch.fromJson(batch))
          .toList(),
      supplierDates: SupplierDates.fromJson(json['supplierDates'] ?? {}),
    );
  }
}

class ExistingBatch {
  final int quantity;
  final String? prodDate;
  final String? expDate;
  final String receivedDate;

  ExistingBatch({
    required this.quantity,
    this.prodDate,
    this.expDate,
    required this.receivedDate,
  });

  factory ExistingBatch.fromJson(Map<String, dynamic> json) {
    return ExistingBatch(
      quantity: json['quantity'] ?? 0,
      prodDate: json['prodDate'],
      expDate: json['expDate'],
      receivedDate: json['receivedDate'] ?? '',
    );
  }
}

class SupplierDates {
  final String? prodDate;
  final String? expDate;
  final String? batchNumber;
  final String? notes;

  SupplierDates({
    this.prodDate,
    this.expDate,
    this.batchNumber,
    this.notes,
  });

  factory SupplierDates.fromJson(Map<String, dynamic> json) {
    return SupplierDates(
      prodDate: json['prodDate'],
      expDate: json['expDate'],
      batchNumber: json['batchNumber'],
      notes: json['notes'],
    );
  }
}

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
  final BatchAlert? itemBatchAlert; // Add batch alert for individual items

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
    this.itemBatchAlert,
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

    // Parse batch alert if present
    BatchAlert? batchAlert;
    if (json['batchAlert'] != null && json['batchAlert'] is Map) {
      final batchAlertData = json['batchAlert'] as Map<String, dynamic>;
      if (batchAlertData['hasAlert'] == true ||
          batchAlertData.containsKey('productId')) {
        try {
          batchAlert = BatchAlert.fromJson(batchAlertData);
        } catch (e) {
          debugPrint('Error parsing batch alert: $e');
        }
      }
    }

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
      itemBatchAlert: batchAlert,
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
      itemBatchAlert: itemBatchAlert,
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

  // Batch alerts for supplier orders
  List<BatchAlert> _batchAlerts = [];
  Map<String, dynamic>? _alertSummary;

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
        debugPrint(
            'Customer Order Response Structure: ${json.encode(response)}');

        _processCustomerOrderDetails(response);
      } else {
        final response =
            await OrderService.getSupplierOrderDetails(_localOrder.orderId);
        if (response == null) {
          throw Exception("Received null response from API");
        }

        // Debug the response structure
        debugPrint(
            'Supplier Order Response Structure: ${json.encode(response)}');

        _processSupplierOrderDetails(response);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in _fetchOrderDetails: $e');
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
        debugPrint('Error: No order data found in customer response');
        _lineItems = [];
        _localOrder = widget.order; // Keep existing data
        return;
      }

      // Extract items from the order object
      final items = orderData['items'];
      if (items == null || items.isEmpty) {
        debugPrint('Warning: items is null or empty in customer order details');
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
          debugPrint('Error parsing date: ${orderData['createdAt']}');
          final now = DateTime.now();
          formattedDate = '${now.month}-${now.day}-${now.year}';
        }
      } else {
        debugPrint('Warning: createdAt is null in order details');
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

  // Process supplier order details with new structure
  void _processSupplierOrderDetails(Map<String, dynamic> response) {
    setState(() {
      _orderDetails = response;

      // The new structure has order data directly in the response
      final orderData =
          response['order'] ?? response; // Fallback to response root

      if (orderData == null) {
        debugPrint('Error: No order data found in supplier response');
        _lineItems = [];
        _localOrder = widget.order; // Keep existing data
        return;
      }

      // Extract items from the order object
      final items = orderData['items'];
      if (items == null || items.isEmpty) {
        debugPrint('Warning: items is null or empty in supplier order details');
        _lineItems = [];
      } else {
        _lineItems = (items as List)
            .map((item) => OrderLineItem.fromSupplierJson(item))
            .toList();
      }

      // Extract batch alerts
      _batchAlerts = [];
      if (response['batchAlerts'] != null) {
        _batchAlerts = (response['batchAlerts'] as List)
            .map((alert) => BatchAlert.fromJson(alert))
            .toList();
      }

      // Extract alert summary
      _alertSummary = response['alertSummary'];

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
          debugPrint('Error parsing date: ${orderData['createdAt']}');
          final now = DateTime.now();
          formattedDate = '${now.month}-${now.day}-${now.year}';
        }
      } else {
        debugPrint('Warning: createdAt is null in order details');
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
            'receivedQuantity': entry.value,
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

  // Build batch alert widget
  Widget _buildBatchAlertSection() {
    if (_localOrder.type != "Supplier" ||
        (_batchAlerts.isEmpty && _alertSummary == null)) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _alertSummary?['hasAlerts'] == true
              ? Colors.amber
              : const Color.fromARGB(255, 47, 71, 82),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _alertSummary?['hasAlerts'] == true
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                color: _alertSummary?['hasAlerts'] == true
                    ? Colors.amber
                    : Colors.blue,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "Batch Information",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Alert summary
          if (_alertSummary != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _alertSummary!['hasAlerts'] == true
                    ? Colors.amber.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _alertSummary!['message'] ?? 'No alerts',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      color: _alertSummary!['hasAlerts'] == true
                          ? Colors.amber
                          : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_alertSummary!['recommendation'] != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      _alertSummary!['recommendation'],
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Individual batch alerts
          if (_batchAlerts.isNotEmpty) ...[
            Text(
              "Product Alerts:",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8.h),
            ...(_batchAlerts.map((alert) => _buildIndividualBatchAlert(alert))),
          ],
        ],
      ),
    );
  }

  Widget _buildIndividualBatchAlert(BatchAlert alert) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert.productName,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            alert.alertMessage,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.sp,
              color: Colors.orange.withOpacity(0.9),
            ),
          ),
          if (alert.existingBatches.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              "Existing batches:",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
              ),
            ),
            ...alert.existingBatches.take(2).map((batch) => Text(
                  "• Qty: ${batch.quantity}, Prod: ${batch.prodDate ?? 'N/A'}, Exp: ${batch.expDate ?? 'N/A'}",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9.sp,
                    color: Colors.white70,
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // Modern helper methods for the new design
  Widget _buildEmptyState() {
    return Container(
      height: 200.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 41, 57).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color.fromARGB(255, 47, 71, 82).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48.sp,
              color: Colors.white.withOpacity(0.3),
            ),
            SizedBox(height: 12.h),
            Text(
              "No items found",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "This order doesn't contain any items",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernItemCard(OrderLineItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 41, 57),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color.fromARGB(255, 47, 71, 82),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main item row
          Row(
            children: [
              // Product image
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color.fromARGB(255, 47, 71, 82),
                    width: 1,
                  ),
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white54,
                              size: 24.sp,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white54,
                        size: 24.sp,
                      ),
              ),
              SizedBox(width: 16.w),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        _buildInfoChip(
                          "Unit Price",
                          "\$${item.unitPrice.toStringAsFixed(2)}",
                          const Color.fromARGB(255, 0, 196, 255),
                        ),
                        SizedBox(width: 8.w),
                        _buildInfoChip(
                          "Qty",
                          item.quantity.toString(),
                          const Color.fromARGB(255, 255, 150, 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit quantity controls for supplier orders
              if (_localOrder.type == "Supplier" &&
                  _localOrder.status == "Accepted") ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 50, 69),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        color: Colors.red,
                        onTap: () {
                          if (item.quantity > 1) {
                            _updateItemQuantity(item.id, item.quantity - 1);
                          }
                        },
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        item.quantity.toString(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      _buildQuantityButton(
                        icon: Icons.add,
                        color: Colors.green,
                        onTap: () {
                          _updateItemQuantity(item.id, item.quantity + 1);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
              ],

              // Total price
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(178, 0, 224, 116).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color.fromARGB(178, 0, 224, 116),
                    width: 1,
                  ),
                ),
                child: Text(
                  "\$${item.total.toStringAsFixed(2)}",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromARGB(178, 0, 224, 116),
                  ),
                ),
              ),
            ],
          ),

          // Batch info for supplier orders
          if (_localOrder.type == "Supplier" &&
              (item.prodDate != null ||
                  item.expDate != null ||
                  item.itemBatchAlert != null)) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: item.itemBatchAlert != null
                      ? Colors.amber.withOpacity(0.5)
                      : const Color.fromARGB(255, 47, 71, 82).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        item.itemBatchAlert != null
                            ? Icons.warning_amber_outlined
                            : Icons.info_outline,
                        color: item.itemBatchAlert != null
                            ? Colors.amber
                            : Colors.blue,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "Batch Information",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      if (item.prodDate != null) ...[
                        _buildBatchInfoChip("Prod Date", item.prodDate!),
                        SizedBox(width: 8.w),
                      ],
                      if (item.expDate != null) ...[
                        _buildBatchInfoChip("Exp Date", item.expDate!),
                      ],
                    ],
                  ),
                  if (item.itemBatchAlert != null) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              "Batch Alert: ${item.itemBatchAlert!.alertType}",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11.sp,
                                color: Colors.amber,
                                fontWeight: FontWeight.w500,
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
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11.sp,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        "$label: $value",
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10.sp,
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 28.h,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Icon(
          icon,
          color: color,
          size: 16.sp,
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_lineItems.length / _lineItemsPerPage).ceil();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color.fromARGB(255, 47, 71, 82),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: _lineItemsCurrentPage > 1 ? Colors.white : Colors.white38,
              size: 20.sp,
            ),
            onPressed: _lineItemsCurrentPage > 1
                ? () {
                    setState(() {
                      _lineItemsCurrentPage--;
                    });
                  }
                : null,
          ),
          SizedBox(width: 12.w),
          Text(
            "Page $_lineItemsCurrentPage of $totalPages",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: _lineItemsCurrentPage < totalPages
                  ? Colors.white
                  : Colors.white38,
              size: 20.sp,
            ),
            onPressed: _lineItemsCurrentPage < totalPages
                ? () {
                    setState(() {
                      _lineItemsCurrentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color.fromARGB(255, 105, 65, 198),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Subtotal:",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
              Text(
                "\$${_calculatedTotal.toStringAsFixed(2)}",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(color: Colors.white24, height: 1),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Grand Total:",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                "\$${_calculatedTotal.toStringAsFixed(2)}",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color.fromARGB(255, 105, 65, 198),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangesWarning() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Quantity Changes Detected",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Your changes will be applied when updating the order status.",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.sp,
                    color: Colors.amber.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

                            // Batch Alert Section (only for supplier orders)
                            _buildBatchAlertSection(),

                            // Modern Full-width Items Section
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 50, 69),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 47, 71, 82),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with title and item count
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Order Items",
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 6.h),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                                  255, 105, 65, 198)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20.r),
                                          border: Border.all(
                                            color: const Color.fromARGB(
                                                255, 105, 65, 198),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          "${_lineItems.length} items",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: const Color.fromARGB(
                                                255, 105, 65, 198),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.h),

                                  // Items list
                                  _lineItems.isEmpty
                                      ? _buildEmptyState()
                                      : Column(
                                          children: [
                                            // Items cards
                                            ...(_visibleLineItems
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final index = entry.key;
                                              final item = entry.value;
                                              return _buildModernItemCard(
                                                  item, index);
                                            }).toList()),

                                            // Pagination if needed
                                            if (_lineItems.length >
                                                _lineItemsPerPage) ...[
                                              SizedBox(height: 20.h),
                                              _buildPaginationControls(),
                                            ],

                                            SizedBox(height: 24.h),

                                            // Total section
                                            _buildTotalSection(),

                                            // Changes warning if quantities were edited
                                            if (_hasQuantityChanges) ...[
                                              SizedBox(height: 16.h),
                                              _buildChangesWarning(),
                                            ],
                                          ],
                                        ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // Order Info Section (now below the table)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 50, 69),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 47, 71, 82),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Order Info (Left)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Order Information",
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
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 32.w),

                                  // Customer/Supplier Info (Right)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
      debugPrint('Error in view order screen build: $e');
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
