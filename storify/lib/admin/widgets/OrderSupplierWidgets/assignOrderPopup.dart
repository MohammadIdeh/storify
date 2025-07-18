// lib/admin/widgets/OrderSupplierWidgets/assignOrderPopup.dart (Localized)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
// Localization imports
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/delivery_models.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/delivery_service.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderModel.dart';

/// Show the assign order popup
Future<bool?> showAssignOrderPopup(BuildContext context,
    {List<OrderItem>? existingOrders}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AssignOrderPopup(existingOrders: existingOrders);
    },
  );
}

class AssignOrderPopup extends StatefulWidget {
  final List<OrderItem>? existingOrders;

  const AssignOrderPopup({Key? key, this.existingOrders}) : super(key: key);

  @override
  State<AssignOrderPopup> createState() => _AssignOrderPopupState();
}

class _AssignOrderPopupState extends State<AssignOrderPopup> {
  // Loading states
  bool _isLoadingOrders = true;
  bool _isLoadingEmployees = true;
  bool _isAssigning = false;

  // Data
  List<OrderItem> _preparedOrders = []; // Using OrderItem for consistency
  List<DeliveryEmployee> _deliveryEmployees = [];

  // Selected items
  final Set<String> _selectedOrderIds = {}; // String to match OrderItem.orderId
  DeliveryEmployee? _selectedEmployee;

  // Form data
  final TextEditingController _estimatedTimeController =
      TextEditingController(text: '30');
  final TextEditingController _notesController = TextEditingController();

  // Error handling
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _estimatedTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // If existing orders are provided, filter for prepared orders
      if (widget.existingOrders != null) {
        setState(() {
          _preparedOrders = widget.existingOrders!
              .where((order) => order.status == "Prepared")
              .toList();
          _isLoadingOrders = false;
        });
      } else {
        // Fallback: try to fetch unassigned orders from API
        try {
          final unassignedOrdersFromApi =
              await DeliveryService.getPreparedOrders();
          // Convert PreparedOrder to OrderItem format
          setState(() {
            _preparedOrders = unassignedOrdersFromApi.map((preparedOrder) {
              return OrderItem(
                orderId: preparedOrder.id.toString(),
                storeName: preparedOrder.customer.user.name,
                phoneNo: preparedOrder.customer.user.phoneNumber,
                orderDate: _formatDate(preparedOrder.createdAt),
                totalProducts: preparedOrder.items.length,
                totalAmount: preparedOrder.totalCost,
                status: preparedOrder.status,
                note: preparedOrder.note,
                supplierId: preparedOrder.customerId,
                items: [], // We don't need detailed items for assignment
              );
            }).toList();
            _isLoadingOrders = false;
          });
        } catch (e) {
          setState(() {
            _errorMessage = e.toString();
            _isLoadingOrders = false;
          });
        }
      }

      // Load delivery employees
      final employees = await DeliveryService.getDeliveryEmployees();
      setState(() {
        _deliveryEmployees = employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingOrders = false;
        _isLoadingEmployees = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _selectAllOrders() {
    setState(() {
      if (_selectedOrderIds.length == _preparedOrders.length) {
        _selectedOrderIds.clear();
      } else {
        _selectedOrderIds.clear();
        _selectedOrderIds.addAll(_preparedOrders.map((order) => order.orderId));
      }
    });
  }

  Future<void> _assignOrders() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    if (_selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectAtLeastOneOrder),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectDeliveryEmployee),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final estimatedTime = int.tryParse(_estimatedTimeController.text);
    if (estimatedTime == null || estimatedTime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidEstimatedTime),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      // Clear any existing queue
      final queue = OrderAssignmentQueue();
      queue.clearQueue();

      // Convert string order IDs to integers
      final orderIdsAsInt = _selectedOrderIds
          .map((id) => int.tryParse(id))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      if (orderIdsAsInt.isEmpty) {
        throw Exception(l10n.invalidOrderIds);
      }

      // Create assignment request
      final request = AssignOrdersRequest(
        deliveryEmployeeId: _selectedEmployee!.id,
        orderIds: orderIdsAsInt,
        estimatedTime: estimatedTime,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Add to queue and process
      queue.addRequest(request);
      final result = await queue.processQueue();

      setState(() {
        _isAssigning = false;
      });

      // Show result dialog
      await _showResultDialog(result);

      // Close popup and return success if any assignments were successful
      if (mounted) {
        Navigator.of(context).pop(result.hasSuccessfulAssignments);
      }
    } catch (e) {
      setState(() {
        _isAssigning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorAssigningOrders}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showResultDialog(OrderAssignmentResult result) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 36, 50, 69),
          title: Text(
            l10n.assignmentResult,
            style: isArabic
                ? GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )
                : GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.hasSuccessfulAssignments) ...[
                Text(
                  '✅ ${l10n.successfullyAssigned} ${result.successCount} ${l10n.orders}',
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                ),
                SizedBox(height: 8.h),
              ],
              if (result.hasErrors) ...[
                Text(
                  '❌ ${l10n.failedToAssign} ${result.errorCount} ${l10n.orders}',
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                ),
                SizedBox(height: 8.h),
                ...result.errors.map((error) => Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        '• $error',
                        style: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                      ),
                    )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.ok,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: const Color.fromARGB(255, 105, 65, 198),
                        fontWeight: FontWeight.w600,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: const Color.fromARGB(255, 105, 65, 198),
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Localization setup
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive dialog dimensions
    final dialogWidth = (screenWidth * 0.85).clamp(600.0, 1000.0);
    final dialogHeight = (screenHeight * 0.85).clamp(500.0, 800.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 29, 41, 57),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    color: const Color.fromARGB(255, 105, 65, 198),
                    size: 28.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    l10n.assignOrdersToDelivery,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Body - Using Flexible instead of Expanded to prevent overflow
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: _isLoadingOrders || _isLoadingEmployees
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: const Color.fromARGB(255, 105, 65, 198),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              l10n.loadingData,
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      color: Colors.white70,
                                      fontSize: 16.sp,
                                    )
                                  : GoogleFonts.spaceGrotesk(
                                      color: Colors.white70,
                                      fontSize: 16.sp,
                                    ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48.sp,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  l10n.errorLoadingData,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  _errorMessage!,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          color: Colors.white70,
                                          fontSize: 14.sp,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white70,
                                          fontSize: 14.sp,
                                        ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton(
                                  onPressed: _loadData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 105, 65, 198),
                                  ),
                                  child: Text(
                                    l10n.retry,
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          )
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side - Orders list
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Orders header with select all
                                    Row(
                                      children: [
                                        Text(
                                          '${l10n.preparedOrders} (${_preparedOrders.length})',
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w600,
                                                )
                                              : GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                        ),
                                        const Spacer(),
                                        if (_preparedOrders.isNotEmpty)
                                          TextButton(
                                            onPressed: _selectAllOrders,
                                            child: Text(
                                              _selectedOrderIds.length ==
                                                      _preparedOrders.length
                                                  ? l10n.deselectAll
                                                  : l10n.selectAll,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              105,
                                                              65,
                                                              198),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    )
                                                  : GoogleFonts.spaceGrotesk(
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              105,
                                                              65,
                                                              198),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    // Orders list - Using Flexible instead of Expanded
                                    Flexible(
                                      child: _preparedOrders.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.inbox_outlined,
                                                    color: Colors.white38,
                                                    size: 48.sp,
                                                  ),
                                                  SizedBox(height: 16.h),
                                                  Text(
                                                    l10n.noPreparedOrdersAvailable,
                                                    style: isArabic
                                                        ? GoogleFonts.cairo(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 16.sp,
                                                          )
                                                        : GoogleFonts
                                                            .spaceGrotesk(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 16.sp,
                                                          ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true, // Add this
                                              itemCount: _preparedOrders.length,
                                              itemBuilder: (context, index) {
                                                final order =
                                                    _preparedOrders[index];
                                                final isSelected =
                                                    _selectedOrderIds.contains(
                                                        order.orderId);
                                                return Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: 8.h),
                                                  padding: EdgeInsets.all(16.w),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? const Color.fromARGB(
                                                                255,
                                                                105,
                                                                65,
                                                                198)
                                                            .withOpacity(0.2)
                                                        : const Color.fromARGB(
                                                            255, 36, 50, 69),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.r),
                                                    border: isSelected
                                                        ? Border.all(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                105, 65, 198),
                                                            width: 2,
                                                          )
                                                        : null,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      // Adjust checkbox position for RTL
                                                      if (!isRtl) ...[
                                                        Checkbox(
                                                          value: isSelected,
                                                          onChanged: (value) =>
                                                              _toggleOrderSelection(
                                                                  order
                                                                      .orderId),
                                                          activeColor:
                                                              const Color
                                                                  .fromARGB(255,
                                                                  105, 65, 198),
                                                        ),
                                                        SizedBox(width: 12.w),
                                                      ],
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  '${l10n.order} #${order.orderId}',
                                                                  style: isArabic
                                                                      ? GoogleFonts.cairo(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              16.sp,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        )
                                                                      : GoogleFonts.spaceGrotesk(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              16.sp,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                ),
                                                                const Spacer(),
                                                                Text(
                                                                  '\$${order.totalAmount.toStringAsFixed(2)}',
                                                                  style: isArabic
                                                                      ? GoogleFonts.cairo(
                                                                          color: const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              0,
                                                                              196,
                                                                              255),
                                                                          fontSize:
                                                                              16.sp,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        )
                                                                      : GoogleFonts.spaceGrotesk(
                                                                          color: const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              0,
                                                                              196,
                                                                              255),
                                                                          fontSize:
                                                                              16.sp,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(
                                                                height: 4.h),
                                                            Text(
                                                              order.storeName,
                                                              style: isArabic
                                                                  ? GoogleFonts
                                                                      .cairo(
                                                                      color: Colors
                                                                          .white70,
                                                                      fontSize:
                                                                          14.sp,
                                                                    )
                                                                  : GoogleFonts
                                                                      .spaceGrotesk(
                                                                      color: Colors
                                                                          .white70,
                                                                      fontSize:
                                                                          14.sp,
                                                                    ),
                                                            ),
                                                            Text(
                                                              order.phoneNo,
                                                              style: isArabic
                                                                  ? GoogleFonts
                                                                      .cairo(
                                                                      color: Colors
                                                                          .white60,
                                                                      fontSize:
                                                                          12.sp,
                                                                    )
                                                                  : GoogleFonts
                                                                      .spaceGrotesk(
                                                                      color: Colors
                                                                          .white60,
                                                                      fontSize:
                                                                          12.sp,
                                                                    ),
                                                            ),
                                                            SizedBox(
                                                                height: 4.h),
                                                            Text(
                                                              '${order.totalProducts} ${l10n.items}',
                                                              style: isArabic
                                                                  ? GoogleFonts
                                                                      .cairo(
                                                                      color: Colors
                                                                          .white54,
                                                                      fontSize:
                                                                          12.sp,
                                                                    )
                                                                  : GoogleFonts
                                                                      .spaceGrotesk(
                                                                      color: Colors
                                                                          .white54,
                                                                      fontSize:
                                                                          12.sp,
                                                                    ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Checkbox on right for RTL
                                                      if (isRtl) ...[
                                                        SizedBox(width: 12.w),
                                                        Checkbox(
                                                          value: isSelected,
                                                          onChanged: (value) =>
                                                              _toggleOrderSelection(
                                                                  order
                                                                      .orderId),
                                                          activeColor:
                                                              const Color
                                                                  .fromARGB(255,
                                                                  105, 65, 198),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 24.w),

                              // Right side - Assignment form
                              Expanded(
                                flex: 1,
                                child: SingleChildScrollView(
                                  // Wrap the entire right side in SingleChildScrollView
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: dialogHeight -
                                          200, // Ensure minimum height
                                    ),
                                    child: IntrinsicHeight(
                                      // Use IntrinsicHeight for proper layout
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.assignmentDetails,
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    color: Colors.white,
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w600,
                                                  )
                                                : GoogleFonts.spaceGrotesk(
                                                    color: Colors.white,
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                          ),
                                          SizedBox(height: 20.h),

                                          // Delivery employee dropdown
                                          Text(
                                            l10n.deliveryEmployee,
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    color: Colors.white70,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                  )
                                                : GoogleFonts.spaceGrotesk(
                                                    color: Colors.white70,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                          ),
                                          SizedBox(height: 8.h),
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16.w),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 36, 50, 69),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              border: Border.all(
                                                color: const Color.fromARGB(
                                                    255, 60, 75, 95),
                                              ),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<
                                                  DeliveryEmployee>(
                                                value: _selectedEmployee,
                                                hint: Text(
                                                  l10n.selectEmployee,
                                                  style: isArabic
                                                      ? GoogleFonts.cairo(
                                                          color: Colors.white54)
                                                      : GoogleFonts
                                                          .spaceGrotesk(
                                                              color: Colors
                                                                  .white54),
                                                ),
                                                dropdownColor:
                                                    const Color.fromARGB(
                                                        255, 36, 50, 69),
                                                style: isArabic
                                                    ? GoogleFonts.cairo(
                                                        color: Colors.white)
                                                    : GoogleFonts.spaceGrotesk(
                                                        color: Colors.white),
                                                icon: Transform.flip(
                                                  flipX: isRtl,
                                                  child: const Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                isExpanded: true,
                                                items: _deliveryEmployees
                                                    .map((employee) {
                                                  return DropdownMenuItem<
                                                      DeliveryEmployee>(
                                                    value: employee,
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          employee.isAvailable
                                                              ? Icons.circle
                                                              : Icons
                                                                  .circle_outlined,
                                                          color: employee
                                                                  .isAvailable
                                                              ? Colors.green
                                                              : Colors.red,
                                                          size: 12.sp,
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                employee
                                                                    .user.name,
                                                                style: isArabic
                                                                    ? GoogleFonts
                                                                        .cairo(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            14.sp,
                                                                      )
                                                                    : GoogleFonts
                                                                        .spaceGrotesk(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            14.sp,
                                                                      ),
                                                              ),
                                                              Text(
                                                                employee.user
                                                                    .phoneNumber,
                                                                style: isArabic
                                                                    ? GoogleFonts
                                                                        .cairo(
                                                                        color: Colors
                                                                            .white60,
                                                                        fontSize:
                                                                            12.sp,
                                                                      )
                                                                    : GoogleFonts
                                                                        .spaceGrotesk(
                                                                        color: Colors
                                                                            .white60,
                                                                        fontSize:
                                                                            12.sp,
                                                                      ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (employee) {
                                                  setState(() {
                                                    _selectedEmployee =
                                                        employee;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: 20.h),

                                          // Estimated time
                                          Text(
                                            l10n.estimatedTimeMinutes,
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    color: Colors.white70,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                  )
                                                : GoogleFonts.spaceGrotesk(
                                                    color: Colors.white70,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                          ),
                                          SizedBox(height: 8.h),
                                          TextField(
                                            controller:
                                                _estimatedTimeController,
                                            keyboardType: TextInputType.number,
                                            textAlign: isRtl
                                                ? TextAlign.right
                                                : TextAlign.left,
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    color: Colors.white)
                                                : GoogleFonts.spaceGrotesk(
                                                    color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText: l10n.enterMinutes,
                                              hintStyle: isArabic
                                                  ? GoogleFonts.cairo(
                                                      color: Colors.white54)
                                                  : GoogleFonts.spaceGrotesk(
                                                      color: Colors.white54),
                                              filled: true,
                                              fillColor: const Color.fromARGB(
                                                  255, 36, 50, 69),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                borderSide: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 60, 75, 95),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                borderSide: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 60, 75, 95),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                borderSide: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 105, 65, 198),
                                                ),
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: 20.h),

                                          // Notes
                                          Text(
                                            l10n.notesOptional,
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    color: Colors.white70,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                  )
                                                : GoogleFonts.spaceGrotesk(
                                                    color: Colors.white70,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                          ),
                                          SizedBox(height: 8.h),
                                          TextField(
                                            controller: _notesController,
                                            maxLines: 3,
                                            textAlign: isRtl
                                                ? TextAlign.right
                                                : TextAlign.left,
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    color: Colors.white)
                                                : GoogleFonts.spaceGrotesk(
                                                    color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText: l10n.addDeliveryNotes,
                                              hintStyle: isArabic
                                                  ? GoogleFonts.cairo(
                                                      color: Colors.white54)
                                                  : GoogleFonts.spaceGrotesk(
                                                      color: Colors.white54),
                                              filled: true,
                                              fillColor: const Color.fromARGB(
                                                  255, 36, 50, 69),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                borderSide: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 60, 75, 95),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                borderSide: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 60, 75, 95),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                borderSide: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 105, 65, 198),
                                                ),
                                              ),
                                            ),
                                          ),

                                          SizedBox(
                                              height: 20
                                                  .h), // Fixed spacing instead of Spacer

                                          // Selected orders summary
                                          if (_selectedOrderIds.isNotEmpty) ...[
                                            Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.all(16.w),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 36, 50, 69),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    l10n.selectedOrders,
                                                    style: isArabic
                                                        ? GoogleFonts.cairo(
                                                            color: Colors.white,
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          )
                                                        : GoogleFonts
                                                            .spaceGrotesk(
                                                            color: Colors.white,
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                  ),
                                                  SizedBox(height: 8.h),
                                                  Text(
                                                    '${_selectedOrderIds.length} ${l10n.ordersSelected}',
                                                    style: isArabic
                                                        ? GoogleFonts.cairo(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                105, 65, 198),
                                                            fontSize: 16.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          )
                                                        : GoogleFonts
                                                            .spaceGrotesk(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                105, 65, 198),
                                                            fontSize: 16.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 20.h),
                                          ],

                                          // Assign button - Always at bottom
                                          SizedBox(
                                            width: double.infinity,
                                            height: 48.h,
                                            child: ElevatedButton(
                                              onPressed: _isAssigning
                                                  ? null
                                                  : _assignOrders,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 105, 65, 198),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: _isAssigning
                                                  ? Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        SizedBox(
                                                          width: 20.w,
                                                          height: 20.h,
                                                          child:
                                                              CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12.w),
                                                        Text(
                                                          l10n.assigning,
                                                          style: isArabic
                                                              ? GoogleFonts
                                                                  .cairo(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      16.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                )
                                                              : GoogleFonts
                                                                  .spaceGrotesk(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      16.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      l10n.assignOrders,
                                                      style: isArabic
                                                          ? GoogleFonts.cairo(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 16.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            )
                                                          : GoogleFonts
                                                              .spaceGrotesk(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 16.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
