// lib/employee/screens/viewOrderScreenEmp.dart - CORRECTED VERSION with proper batch handling
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/employee/screens/orders_screen.dart';
import 'package:storify/employee/widgets/orderServiceEmp.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

// UPDATED: Enhanced Batch Selection model to handle the three scenarios
class BatchSelection {
  final int batchId;
  final int availableQuantity;
  int selectedQuantity;
  final String? prodDate;
  final String? expDate;
  final String? batchNumber;
  final bool isRecommended;
  final String? receivedDate;
  final double? costPrice;

  BatchSelection({
    required this.batchId,
    required this.availableQuantity,
    this.selectedQuantity = 0,
    this.prodDate,
    this.expDate,
    this.batchNumber,
    this.isRecommended = false,
    this.receivedDate,
    this.costPrice,
  });
}

// UPDATED: Enhanced Product Info model to handle all three scenarios
class ProductFifoInfo {
  final int productId;
  final String productName;
  final int requiredQuantity;
  final int totalAvailable;
  final bool canFulfill;
  final String
      preparationType; // "batch_management", "direct_quantity", "insufficient_stock"
  final List<BatchSelection> batchSelections;
  final List<BatchAlert> alerts;
  final String? directQuantityMethod;

  ProductFifoInfo({
    required this.productId,
    required this.productName,
    required this.requiredQuantity,
    required this.totalAvailable,
    required this.canFulfill,
    required this.preparationType,
    required this.batchSelections,
    required this.alerts,
    this.directQuantityMethod,
  });

  // CORRECTED: Factory method to create from order item fifoInfo
  factory ProductFifoInfo.fromOrderItem(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    final fifoInfo = item['fifoInfo'] ?? {};

    final productId = product['productId'] ?? 0;
    final productName = product['name'] ?? 'Unknown Product';
    final requiredQuantity = item['quantity'] ?? 0;
    final canFulfill = fifoInfo['canFulfill'] ?? false;
    final totalAvailable = fifoInfo['totalAvailable'] ?? 0;

    // Parse alerts
    final alertsList = (fifoInfo['alerts'] as List? ?? []);
    final alerts =
        alertsList.map((alertData) => BatchAlert.fromJson(alertData)).toList();

    // Determine preparation type based on allocation structure
    final allocation = fifoInfo['allocation'] as List? ?? [];
    String preparationType = "insufficient_stock";
    String? directQuantityMethod;
    List<BatchSelection> batchSelections = [];

    if (!canFulfill) {
      preparationType = "insufficient_stock";
    } else {
      // Check if it's direct quantity (no batch management)
      final hasNoBatchAlert =
          alerts.any((alert) => alert.type == "NO_BATCH_MANAGEMENT");

      if (hasNoBatchAlert ||
          (allocation.isNotEmpty &&
              allocation.first['type'] == "direct_quantity")) {
        preparationType = "direct_quantity";
        if (allocation.isNotEmpty) {
          directQuantityMethod = allocation.first['method'];
        }
      } else if (allocation.isNotEmpty && allocation.first['batchId'] != null) {
        preparationType = "batch_management";

        // Process batch allocations
        for (final alloc in allocation) {
          if (alloc['batchId'] != null) {
            batchSelections.add(BatchSelection(
              batchId: alloc['batchId'],
              availableQuantity:
                  alloc['remainingInBatch'] ?? alloc['quantity'] ?? 0,
              selectedQuantity: alloc['quantity'] ?? 0,
              prodDate: alloc['prodDate'],
              expDate: alloc['expDate'],
              batchNumber: alloc['batchNumber'] ?? 'Batch #${alloc['batchId']}',
              isRecommended: true, // These are FIFO recommendations
              receivedDate: alloc['receivedDate'],
              costPrice: (alloc['costPrice'] as num?)?.toDouble(),
            ));
          }
        }
      }
    }

    return ProductFifoInfo(
      productId: productId,
      productName: productName,
      requiredQuantity: requiredQuantity,
      totalAvailable: totalAvailable,
      canFulfill: canFulfill,
      preparationType: preparationType,
      batchSelections: batchSelections,
      alerts: alerts,
      directQuantityMethod: directQuantityMethod,
    );
  }
}

// Line item model for order details (unchanged)
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

  // UPDATED: Enhanced batch management for customer orders
  List<ProductFifoInfo> _productFifoInfos = [];
  bool _showBatchDetails = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrderDetails();
    });
  }

  // Get localized status text
  String _getLocalizedStatus(BuildContext context, String status) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    switch (status.toLowerCase()) {
      case "accepted":
        return l10n.viewOrderStatusAccepted;
      case "pending":
        return l10n.viewOrderStatusPending;
      case "delivered":
        return l10n.viewOrderStatusDelivered;
      case "shipped":
        return l10n.viewOrderStatusShipped;
      case "prepared":
        return l10n.viewOrderStatusPrepared;
      case "rejected":
        return l10n.viewOrderStatusRejected;
      case "declined":
        return l10n.viewOrderStatusDeclined;
      case "preparing":
        return l10n.viewOrderStatusPreparing;
      default:
        return status;
    }
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

        debugPrint(
            'Customer Order Response Structure: ${json.encode(response)}');
        _processCustomerOrderDetails(response);
      } else {
        final response =
            await OrderService.getSupplierOrderDetails(_localOrder.orderId);
        if (response == null) {
          throw Exception("Received null response from API");
        }

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

  // UPDATED: Process customer order details with enhanced FIFO info handling
  void _processCustomerOrderDetails(Map<String, dynamic> response) {
    setState(() {
      _orderDetails = response;

      // Extract the order object which contains all the data
      final orderData = response['order'];
      if (orderData == null) {
        debugPrint('Error: No order data found in customer response');
        _lineItems = [];
        _productFifoInfos = [];
        _localOrder = widget.order; // Keep existing data
        return;
      }

      // Extract items from the order object
      final items = orderData['items'];
      if (items == null || items.isEmpty) {
        debugPrint('Warning: items is null or empty in customer order details');
        _lineItems = [];
        _productFifoInfos = [];
      } else {
        _lineItems = (items as List)
            .map((item) => OrderLineItem.fromCustomerJson(item))
            .toList();

        // CORRECTED: Process FIFO info for each item
        _productFifoInfos = (items as List)
            .map((item) => ProductFifoInfo.fromOrderItem(item))
            .toList();

        debugPrint('=== PROCESSED FIFO INFO ===');
        for (final info in _productFifoInfos) {
          debugPrint('Product: ${info.productName}');
          debugPrint('  Type: ${info.preparationType}');
          debugPrint(
              '  Required: ${info.requiredQuantity}, Available: ${info.totalAvailable}');
          debugPrint('  Can Fulfill: ${info.canFulfill}');
          debugPrint('  Batches: ${info.batchSelections.length}');
          debugPrint('  Alerts: ${info.alerts.length}');
        }
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

  // Process supplier order details (unchanged)
  void _processSupplierOrderDetails(Map<String, dynamic> response) {
    setState(() {
      _orderDetails = response;

      // The structure has order data directly in the response
      final orderData = response['order'] ?? response;

      if (orderData == null) {
        debugPrint('Error: No order data found in supplier response');
        _lineItems = [];
        _localOrder = widget.order;
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

    if (mounted) {
      final l10n =
          Localizations.of<AppLocalizations>(context, AppLocalizations)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.viewOrderDataRefreshed),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color.fromARGB(255, 0, 196, 255),
        ),
      );
    }
  }

  // Start customer order preparation
  Future<void> _startCustomerOrderPreparation() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    if (_localOrder.status != "Accepted") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.viewOrderMustBeAcceptedToStart),
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

      // Use legacy method that returns Map<String, dynamic>
      await OrderService.startCustomerOrderPreparationLegacy(
          _localOrder.orderId, note.isNotEmpty ? note : null);

      // Refresh the order to get updated status and FIFO info
      await _fetchOrderDetails();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.viewOrderPreparationStartedSuccess),
          backgroundColor: const Color.fromARGB(255, 255, 150, 30),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error starting preparation: $e';
        _isLoading = false;
      });
    }
  }

  // Complete customer order preparation
  Future<void> _completeCustomerOrderPreparation() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    if (_localOrder.status != "Preparing") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.viewOrderMustBePreparingToComplete),
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
      List<ManualBatchAllocation>? manualAllocations;

      // Check if any batch quantities were manually changed
      bool hasManualChanges = _hasManualBatchChanges;

      // If manual changes detected, prepare manual allocations
      if (hasManualChanges) {
        manualAllocations = [];

        for (final productInfo in _productFifoInfos) {
          if (productInfo.preparationType == "batch_management") {
            final allocations = <BatchAllocation>[];
            for (final selection in productInfo.batchSelections) {
              if (selection.selectedQuantity > 0) {
                allocations.add(BatchAllocation(
                  batchId: selection.batchId,
                  quantity: selection.selectedQuantity,
                ));
              }
            }

            if (allocations.isNotEmpty) {
              manualAllocations.add(ManualBatchAllocation(
                productId: productInfo.productId,
                batchAllocations: allocations,
              ));
            }
          }
        }

        if (manualAllocations.isEmpty) {
          manualAllocations = null; // Let system use FIFO
        }
      }

      // Complete preparation
      await OrderService.completeCustomerOrderPreparation(
        _localOrder.orderId,
        notes: note.isNotEmpty ? note : null,
        manualBatchAllocations: manualAllocations,
      );

      // Show success message with mode indication
      final modeText = hasManualChanges
          ? l10n.viewOrderCompletedManualBatch
          : l10n.viewOrderCompletedAutoFifo;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.viewOrderCompletedSuccess(modeText)),
          backgroundColor: const Color.fromARGB(178, 0, 224, 116),
        ),
      );

      // Refresh order data
      await _fetchOrderDetails();

      // Return to previous screen after delay
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context, _localOrder);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error completing preparation: $e';
        _isLoading = false;
      });
    }
  }

  // Update supplier order status (same as before)
  Future<void> _updateSupplierOrderStatus(String newStatus) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    if (_localOrder.status == newStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.viewOrderAlreadyInStatus(newStatus)),
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
          final itemId = entry.key;
          final newQuantity = entry.value;

          // Find the original item to get the PRODUCT ID
          final originalItem = _lineItems.firstWhere(
            (item) => item.id == itemId,
            orElse: () => _lineItems.first,
          );

          // Send PRODUCT ID instead of ITEM ID
          return {
            'id': originalItem.productId,
            'receivedQuantity': newQuantity,
          };
        }).toList();
      }

      // Make the API call with corrected data
      await OrderService.updateSupplierOrderStatus(
        _localOrder.orderId,
        newStatus,
        note.isNotEmpty ? note : null,
        updatedItems,
      );

      // Refresh order data to see the changes
      await _fetchOrderDetails();

      // Reset edited quantities
      setState(() {
        _editedQuantities.clear();
        _hasQuantityChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.viewOrderUpdatedToStatus(newStatus)),
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

  // UPDATED: Update batch selection quantity
  void _updateBatchSelection(int productId, int batchId, int newQuantity) {
    final productIndex =
        _productFifoInfos.indexWhere((info) => info.productId == productId);
    if (productIndex == -1) return;

    setState(() {
      final productInfo = _productFifoInfos[productIndex];
      final batchIndex =
          productInfo.batchSelections.indexWhere((s) => s.batchId == batchId);
      if (batchIndex != -1) {
        productInfo.batchSelections[batchIndex].selectedQuantity =
            newQuantity.clamp(
                0, productInfo.batchSelections[batchIndex].availableQuantity);
      }
    });
  }

  // UPDATED: Check if any batch quantities were manually changed from FIFO recommendations
  bool get _hasManualBatchChanges {
    for (final productInfo in _productFifoInfos) {
      if (productInfo.preparationType == "batch_management") {
        for (final selection in productInfo.batchSelections) {
          // Compare with recommended quantity (which was set initially as selectedQuantity)
          // If user has modified it from the original FIFO recommendation, it's a manual change
          // This is a simplified check - in a real implementation, you'd store the original recommendations
          if (selection.selectedQuantity != selection.selectedQuantity) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Helper getter for alerts to show
  List<BatchAlert> get _alertsToShow {
    final allAlerts = <BatchAlert>[];
    for (final productInfo in _productFifoInfos) {
      allAlerts.addAll(productInfo.alerts);
    }
    return allAlerts;
  }

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

  // Calculate total amount based on current line items
  double get _calculatedTotal {
    return _lineItems.fold(0, (sum, item) => sum + item.total);
  }

  // CORRECTED: Build batch management section with proper handling of all three scenarios
  Widget _buildBatchManagementSection() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    if (_localOrder.type != "Customer" || _productFifoInfos.isEmpty) {
      return SizedBox.shrink();
    }

    // Analyze the products to determine what to show
    final hasAnyBatchManagement = _productFifoInfos
        .any((info) => info.preparationType == "batch_management");
    final hasInsufficientStock =
        _productFifoInfos.any((info) => !info.canFulfill);
    final hasDirectQuantity = _productFifoInfos
        .any((info) => info.preparationType == "direct_quantity");
    final hasCriticalAlerts =
        _alertsToShow.any((alert) => alert.severity == 'critical');

    // Show section only if order is Accepted or Preparing, and there's relevant info to display
    if (_localOrder.status != "Accepted" && _localOrder.status != "Preparing") {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasCriticalAlerts
              ? Colors.red
              : hasInsufficientStock
                  ? Colors.red
                  : hasAnyBatchManagement
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
                hasCriticalAlerts || hasInsufficientStock
                    ? Icons.error_outline
                    : hasAnyBatchManagement
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline,
                color: hasCriticalAlerts || hasInsufficientStock
                    ? Colors.red
                    : hasAnyBatchManagement
                        ? Colors.amber
                        : Colors.blue,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.viewOrderBatchManagement,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
              ),
              Spacer(),
              // Show summary
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  l10n.viewOrderBatchSummary(
                      _productFifoInfos.length, _alertsToShow.length),
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 10.sp,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ),
              SizedBox(width: 8.w),
              // Toggle batch details
              TextButton(
                onPressed: () {
                  setState(() {
                    _showBatchDetails = !_showBatchDetails;
                  });
                },
                child: Text(
                  _showBatchDetails
                      ? l10n.viewOrderHideDetails
                      : l10n.viewOrderShowDetails,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Summary alerts
          if (_alertsToShow.isNotEmpty) ...[
            for (final alert in _alertsToShow.take(3)) ...[
              Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: alert.severity == 'critical'
                      ? Colors.red.withOpacity(0.1)
                      : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  alert.message,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: alert.severity == 'critical'
                              ? Colors.red
                              : Colors.amber,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          color: alert.severity == 'critical'
                              ? Colors.red
                              : Colors.amber,
                        ),
                ),
              ),
            ],
            if (_alertsToShow.length > 3) ...[
              Text(
                l10n.viewOrderMoreAlerts(_alertsToShow.length - 3),
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 11.sp,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
              ),
            ],
          ],

          // Detailed information for each product
          if (_showBatchDetails) ...[
            SizedBox(height: 16.h),
            Text(
              "Product Details:",
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
            ),
            SizedBox(height: 8.h),
            for (final productInfo in _productFifoInfos) ...[
              _buildProductDetailCard(productInfo),
              SizedBox(height: 12.h),
            ],
          ],
        ],
      ),
    );
  }

  // CORRECTED: Build product detail card with proper handling of all three scenarios
  Widget _buildProductDetailCard(ProductFifoInfo productInfo) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    Color borderColor;
    Color headerColor;
    IconData icon;

    switch (productInfo.preparationType) {
      case "batch_management":
        borderColor = Colors.amber;
        headerColor = Colors.amber;
        icon = Icons.inventory_2;
        break;
      case "direct_quantity":
        borderColor = Colors.blue;
        headerColor = Colors.blue;
        icon = Icons.straighten;
        break;
      case "insufficient_stock":
      default:
        borderColor = Colors.red;
        headerColor = Colors.red;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 41, 57).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with product name and type
          Row(
            children: [
              Icon(icon, color: headerColor, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  productInfo.productName,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: headerColor.withOpacity(0.3)),
                ),
                child: Text(
                  _getPreparationTypeLabel(productInfo.preparationType),
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: headerColor,
                          fontWeight: FontWeight.w600,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 10.sp,
                          color: headerColor,
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // CORRECTED: Fixed the swapped labels - Required vs Available
          Row(
            children: [
              _buildQuantityInfo(
                "Required", // FIXED: This was previously showing available
                productInfo.requiredQuantity.toString(),
                Colors.orange,
              ),
              SizedBox(width: 16.w),
              _buildQuantityInfo(
                "Available", // FIXED: This was previously showing required
                productInfo.totalAvailable.toString(),
                productInfo.canFulfill ? Colors.green : Colors.red,
              ),
              SizedBox(width: 16.w),
              _buildQuantityInfo(
                "Status",
                productInfo.canFulfill ? "✓ Can Fulfill" : "✗ Insufficient",
                productInfo.canFulfill ? Colors.green : Colors.red,
              ),
            ],
          ),

          // Show specific content based on preparation type
          if (productInfo.preparationType == "batch_management") ...[
            SizedBox(height: 12.h),
            Text(
              "Batch Selection (FIFO Recommended):",
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
            ),
            SizedBox(height: 8.h),
            for (final batch in productInfo.batchSelections) ...[
              _buildBatchSelectionRow(productInfo.productId, batch),
            ],
          ] else if (productInfo.preparationType == "direct_quantity") ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "This product uses simple quantity tracking without batch/expiry date management.",
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 11.sp,
                              color: Colors.blue,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 11.sp,
                              color: Colors.blue,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (productInfo.preparationType == "insufficient_stock") ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Insufficient stock available. Required: ${productInfo.requiredQuantity}, Available: ${productInfo.totalAvailable}",
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 11.sp,
                              color: Colors.red,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 11.sp,
                              color: Colors.red,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Show alerts specific to this product
          if (productInfo.alerts.isNotEmpty) ...[
            SizedBox(height: 8.h),
            for (final alert in productInfo.alerts) ...[
              Container(
                margin: EdgeInsets.only(bottom: 4.h),
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: alert.severity == 'critical'
                      ? Colors.red.withOpacity(0.1)
                      : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  alert.message,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: alert.severity == 'critical'
                              ? Colors.red
                              : Colors.amber,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 10.sp,
                          color: alert.severity == 'critical'
                              ? Colors.red
                              : Colors.amber,
                        ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Helper method to get preparation type label
  String _getPreparationTypeLabel(String type) {
    switch (type) {
      case "batch_management":
        return "Batch Managed";
      case "direct_quantity":
        return "Direct Quantity";
      case "insufficient_stock":
        return "No Stock";
      default:
        return type;
    }
  }

  // Helper method to build quantity info chips
  Widget _buildQuantityInfo(String label, String value, Color color) {
    final isArabic = LocalizationHelper.isArabic(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 9.sp,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 9.sp,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
          ),
          Text(
            value,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: color,
                    fontWeight: FontWeight.w600,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 11.sp,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }

  // CORRECTED: Build batch selection row with proper date labels
  Widget _buildBatchSelectionRow(int productId, BatchSelection batch) {
    final isArabic = LocalizationHelper.isArabic(context);

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: batch.isRecommended
            ? Colors.green.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: batch.isRecommended
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      batch.batchNumber ?? 'Batch #${batch.batchId}',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: batch.isRecommended
                                  ? Colors.green
                                  : Colors.white,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: batch.isRecommended
                                  ? Colors.green
                                  : Colors.white,
                            ),
                    ),
                    if (batch.isRecommended) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          "FIFO",
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  fontSize: 10.sp,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  fontSize: 10.sp,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                // CORRECTED: Fixed the swapped labels - Prod Date vs Available Quantity
                Text(
                  "Prod: ${batch.prodDate ?? 'N/A'} | Exp: ${batch.expDate ?? 'N/A'} | Available: ${batch.availableQuantity}",
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: Colors.white60,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 10.sp,
                          color: Colors.white60,
                        ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Quantity selection (only for preparing orders)
          if (_localOrder.status == "Preparing") ...[
            Container(
              width: 100.w,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 16.sp, color: Colors.red),
                    onPressed: batch.selectedQuantity > 0
                        ? () => _updateBatchSelection(
                              productId,
                              batch.batchId,
                              batch.selectedQuantity - 1,
                            )
                        : null,
                    padding: EdgeInsets.all(4.w),
                    constraints:
                        BoxConstraints(minWidth: 24.w, minHeight: 24.h),
                  ),
                  Expanded(
                    child: Text(
                      "${batch.selectedQuantity}",
                      textAlign: TextAlign.center,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 16.sp, color: Colors.green),
                    onPressed: batch.selectedQuantity < batch.availableQuantity
                        ? () => _updateBatchSelection(
                              productId,
                              batch.batchId,
                              batch.selectedQuantity + 1,
                            )
                        : null,
                    padding: EdgeInsets.all(4.w),
                    constraints:
                        BoxConstraints(minWidth: 24.w, minHeight: 24.h),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Just show the selected/recommended quantity for non-preparing orders
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                "Qty: ${batch.selectedQuantity}",
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Rest of the methods remain the same...
  // (buildEmptyState, buildModernItemCard, buildInfoChip, etc.)

  // Build empty state
  Widget _buildEmptyState() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

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
              l10n.viewOrderNoItemsFound,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
            ),
            SizedBox(height: 6.h),
            Text(
              l10n.viewOrderNoItemsDescription,
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
    );
  }

  // Build modern item card
  Widget _buildModernItemCard(OrderLineItem item, int index) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

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
      child: Row(
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
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
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
                      l10n.viewOrderUnitPriceLabel,
                      "\$${item.unitPrice.toStringAsFixed(2)}",
                      const Color.fromARGB(255, 0, 196, 255),
                    ),
                    SizedBox(width: 8.w),
                    _buildInfoChip(
                      l10n.viewOrderQuantityLabel,
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
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
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
              color: const Color.fromARGB(178, 0, 224, 116).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color.fromARGB(178, 0, 224, 116),
                width: 1,
              ),
            ),
            child: Text(
              "\$${item.total.toStringAsFixed(2)}",
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(178, 0, 224, 116),
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(178, 0, 224, 116),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    final isArabic = LocalizationHelper.isArabic(context);

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
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 11.sp,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
            ),
            TextSpan(
              text: value,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: color,
                      fontWeight: FontWeight.w600,
                    )
                  : GoogleFonts.spaceGrotesk(
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
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
            l10n.viewOrderPageInfo(_lineItemsCurrentPage, totalPages),
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

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
                l10n.viewOrderSubtotal,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
              ),
              Text(
                "\$${_calculatedTotal.toStringAsFixed(2)}",
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      )
                    : GoogleFonts.spaceGrotesk(
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
                l10n.viewOrderGrandTotal,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
              ),
              Text(
                "\$${_calculatedTotal.toStringAsFixed(2)}",
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 105, 65, 198),
                      )
                    : GoogleFonts.spaceGrotesk(
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

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
                  l10n.viewOrderQuantityChangesDetected,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.viewOrderChangesWillBeApplied,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 11.sp,
                          color: Colors.amber.withOpacity(0.9),
                        )
                      : GoogleFonts.spaceGrotesk(
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    try {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
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
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                    )
                                  : GoogleFonts.spaceGrotesk(
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
                                l10n.viewOrderRetryButton,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
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
                                l10n.viewOrderGoBackButton,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: isRtl ? 45.w : 45.w,
                            top: 20.h,
                            right: isRtl ? 45.w : 45.w,
                          ),
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
                                          color:
                                              Color.fromARGB(255, 47, 71, 82),
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
                                          isRtl
                                              ? Icons.arrow_forward
                                              : Icons.arrow_back,
                                          color: const Color.fromARGB(
                                              255, 105, 123, 123),
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          l10n.viewOrderBackButton,
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  fontSize: 17.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color.fromARGB(
                                                      255, 105, 123, 123),
                                                )
                                              : GoogleFonts.spaceGrotesk(
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
                                    l10n.viewOrderTitle,
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            fontSize: 28.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color.fromARGB(
                                                255, 246, 246, 246),
                                          )
                                        : GoogleFonts.spaceGrotesk(
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
                                          color:
                                              Color.fromARGB(255, 47, 71, 82),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      fixedSize: Size(220.w, 50.h),
                                      elevation: 1,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                l10n.viewOrderPrintingInvoice)),
                                      );
                                    },
                                    child: Text(
                                      l10n.viewOrderPrintInvoice,
                                      style: isArabic
                                          ? GoogleFonts.cairo(
                                              fontSize: 17.sp,
                                              fontWeight: FontWeight.w700,
                                              color: const Color.fromARGB(
                                                  255, 105, 123, 123),
                                            )
                                          : GoogleFonts.spaceGrotesk(
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

                              // CORRECTED: Enhanced Batch Management Section
                              _buildBatchManagementSection(),

                              // Modern Full-width Items Section
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 36, 50, 69),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color:
                                        const Color.fromARGB(255, 47, 71, 82),
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
                                          l10n.viewOrderItemsTitle,
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  fontSize: 22.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                )
                                              : GoogleFonts.spaceGrotesk(
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
                                            l10n.viewOrderItemsCount(
                                                _lineItems.length),
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color.fromARGB(
                                                        255, 105, 65, 198),
                                                  )
                                                : GoogleFonts.spaceGrotesk(
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

                              // Order Info Section
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 36, 50, 69),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color:
                                        const Color.fromARGB(255, 47, 71, 82),
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
                                            l10n.viewOrderInformationTitle,
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  )
                                                : GoogleFonts.spaceGrotesk(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                          ),
                                          SizedBox(height: 10.h),
                                          _buildInfoRow(l10n.viewOrderIdLabel,
                                              _localOrder.orderId.toString()),
                                          _buildInfoRow(l10n.viewOrderDateLabel,
                                              _localOrder.orderDate),
                                          _buildInfoRow(l10n.viewOrderTypeLabel,
                                              _localOrder.type),
                                          SizedBox(height: 6.h),
                                          if (_localOrder.type == "Customer" &&
                                              _orderDetails != null)
                                            _buildInfoRow(
                                                l10n
                                                    .viewOrderPaymentStatusLabel,
                                                (_orderDetails!['amountPaid'] !=
                                                            null &&
                                                        (_orderDetails![
                                                                    'amountPaid']
                                                                as num) >
                                                            0)
                                                    ? l10n.viewOrderPaymentPaid
                                                    : l10n
                                                        .viewOrderPaymentPending),

                                          Row(
                                            children: [
                                              Text(
                                                l10n.viewOrderStatusLabel,
                                                style: isArabic
                                                    ? GoogleFonts.cairo(
                                                        fontSize: 15.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white54,
                                                      )
                                                    : GoogleFonts.spaceGrotesk(
                                                        fontSize: 15.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                              l10n.viewOrderActionsTitle,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white54,
                                                    )
                                                  : GoogleFonts.spaceGrotesk(
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white54,
                                                    ),
                                            ),
                                            SizedBox(height: 10.h),
                                            // Add note field for actions
                                            TextField(
                                              controller: _noteController,
                                              maxLines: 3,
                                              textDirection: isRtl
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      color: Colors.white)
                                                  : GoogleFonts.spaceGrotesk(
                                                      color: Colors.white),
                                              decoration: InputDecoration(
                                                hintText: l10n
                                                    .viewOrderNotePlaceholder,
                                                hintStyle: isArabic
                                                    ? GoogleFonts.cairo(
                                                        color: Colors.white38)
                                                    : GoogleFonts.spaceGrotesk(
                                                        color: Colors.white38),
                                                filled: true,
                                                fillColor: Colors.white
                                                    .withOpacity(0.05),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.r),
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
                                                      BorderRadius.circular(
                                                          12.r),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 12.h),
                                                minimumSize:
                                                    Size(double.infinity, 45.h),
                                              ),
                                              onPressed:
                                                  _startCustomerOrderPreparation,
                                              child: Text(
                                                l10n.viewOrderStartPreparingButton,
                                                style: isArabic
                                                    ? GoogleFonts.cairo(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      )
                                                    : GoogleFonts.spaceGrotesk(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                              ),
                                            ),
                                          ],

                                          // For Customer Preparing status, show completion buttons
                                          if (_localOrder.type == "Customer" &&
                                              _localOrder.status ==
                                                  "Preparing") ...[
                                            SizedBox(height: 20.h),
                                            Text(
                                              l10n.viewOrderActionsTitle,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white54,
                                                    )
                                                  : GoogleFonts.spaceGrotesk(
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white54,
                                                    ),
                                            ),
                                            SizedBox(height: 10.h),
                                            // Add note field for actions
                                            TextField(
                                              controller: _noteController,
                                              maxLines: 3,
                                              textDirection: isRtl
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      color: Colors.white)
                                                  : GoogleFonts.spaceGrotesk(
                                                      color: Colors.white),
                                              decoration: InputDecoration(
                                                hintText: l10n
                                                    .viewOrderNotePlaceholder,
                                                hintStyle: isArabic
                                                    ? GoogleFonts.cairo(
                                                        color: Colors.white38)
                                                    : GoogleFonts.spaceGrotesk(
                                                        color: Colors.white38),
                                                filled: true,
                                                fillColor: Colors.white
                                                    .withOpacity(0.05),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.r),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.all(12.w),
                                              ),
                                            ),
                                            SizedBox(height: 16.h),

                                            // Complete preparation button
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        178, 0, 224, 116),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 12.h),
                                                minimumSize:
                                                    Size(double.infinity, 45.h),
                                              ),
                                              onPressed:
                                                  _completeCustomerOrderPreparation,
                                              child: Text(
                                                l10n.viewOrderCompletePreparationButton,
                                                style: isArabic
                                                    ? GoogleFonts.cairo(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      )
                                                    : GoogleFonts.spaceGrotesk(
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                              l10n.viewOrderActionsTitle,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white54,
                                                    )
                                                  : GoogleFonts.spaceGrotesk(
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white54,
                                                    ),
                                            ),
                                            SizedBox(height: 10.h),
                                            // Add note field for actions
                                            TextField(
                                              controller: _noteController,
                                              maxLines: 3,
                                              textDirection: isRtl
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      color: Colors.white)
                                                  : GoogleFonts.spaceGrotesk(
                                                      color: Colors.white),
                                              decoration: InputDecoration(
                                                hintText: l10n
                                                    .viewOrderNotePlaceholder,
                                                hintStyle: isArabic
                                                    ? GoogleFonts.cairo(
                                                        color: Colors.white38)
                                                    : GoogleFonts.spaceGrotesk(
                                                        color: Colors.white38),
                                                filled: true,
                                                fillColor: Colors.white
                                                    .withOpacity(0.05),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.r),
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
                                                      BorderRadius.circular(
                                                          12.r),
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
                                                l10n.viewOrderMarkAsDeliveredButton,
                                                style: isArabic
                                                    ? GoogleFonts.cairo(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      )
                                                    : GoogleFonts.spaceGrotesk(
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                                ? l10n
                                                    .viewOrderSupplierInfoTitle
                                                : l10n
                                                    .viewOrderCustomerInfoTitle,
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  )
                                                : GoogleFonts.spaceGrotesk(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                          ),
                                          SizedBox(height: 10.h),
                                          _buildInfoRow(l10n.viewOrderNameLabel,
                                              _localOrder.name),
                                          _buildInfoRow(
                                              l10n.viewOrderPhoneLabel,
                                              _localOrder.phoneNo),
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
        ),
      );
    } catch (e) {
      debugPrint('Error in view order screen build: $e');
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: const Color.fromARGB(255, 29, 41, 57),
          body: SafeArea(
            child: Center(
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
                    l10n.viewOrderErrorDisplaying(e.toString()),
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 16.sp,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: Text(
                      l10n.viewOrderGoBackButton,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              color: Colors.white,
                            )
                          : GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    final isArabic = LocalizationHelper.isArabic(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
          ),
          Expanded(
            child: Text(
              value,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    )
                  : GoogleFonts.spaceGrotesk(
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
    final isArabic = LocalizationHelper.isArabic(context);

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
        _getLocalizedStatus(context, status),
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
