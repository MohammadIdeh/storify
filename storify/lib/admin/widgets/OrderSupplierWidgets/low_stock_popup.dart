// lib/admin/widgets/OrderSupplierWidgets/low_stock_popup.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/low_stock_models.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/low_stock_service.dart';

class LowStockPopup extends StatefulWidget {
  final List<LowStockItem> lowStockItems;
  final VoidCallback? onOrdersGenerated;

  const LowStockPopup({
    Key? key,
    required this.lowStockItems,
    this.onOrdersGenerated,
  }) : super(key: key);

  @override
  State<LowStockPopup> createState() => _LowStockPopupState();
}

class _LowStockPopupState extends State<LowStockPopup> {
  late List<LowStockItem> _items;
  bool _isGeneratingOrders = false;
  bool _selectAll = false;
  Map<int, List<SupplierInfo>> _productSuppliers = {};
  Map<int, SupplierInfo?> _selectedSuppliers = {};

  // Advanced features
  bool _useGlobalSupplier = false;
  SupplierInfo? _globalSupplier;
  List<SupplierInfo> _allSuppliers = [];
  Map<int, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _items = widget.lowStockItems.map((item) => item.copyWith()).toList();
    _initializeControllers();
    _initializeSuppliers();
  }

  @override
  void dispose() {
    // Dispose all text controllers
    _quantityControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initializeControllers() {
    for (var item in _items) {
      _quantityControllers[item.product.productId] = TextEditingController(
        text: item.stockDeficit.toString(),
      );
    }
  }

  void _initializeSuppliers() {
    for (var item in _items) {
      _loadProductSuppliers(item.product.productId);
    }
    _loadAllSuppliers();
  }

  Future<void> _loadAllSuppliers() async {
    try {
      // Get unique suppliers from all product suppliers
      Set<SupplierInfo> uniqueSuppliers = {};

      for (var item in _items) {
        final response =
            await LowStockService.getProductSuppliers(item.product.productId);
        if (response != null) {
          uniqueSuppliers.addAll(response.suppliers);
        }
      }

      setState(() {
        _allSuppliers = uniqueSuppliers.toList();
      });
    } catch (e) {
      print('Error loading all suppliers: $e');
    }
  }

  Future<void> _loadProductSuppliers(int productId) async {
    try {
      final response = await LowStockService.getProductSuppliers(productId);
      if (response != null && mounted) {
        setState(() {
          _productSuppliers[productId] = response.suppliers;

          final itemIndex =
              _items.indexWhere((item) => item.product.productId == productId);
          if (itemIndex != -1) {
            final item = _items[itemIndex];
            if (item.lastOrder != null && response.suppliers.isNotEmpty) {
              final lastOrderSupplierId = item.lastOrder!.supplier.id;
              final lastOrderSupplierName = item.lastOrder!.supplier.user.name;
              final lastOrderSupplierEmail =
                  item.lastOrder!.supplier.user.email;

              SupplierInfo? matchingSupplier;
              try {
                matchingSupplier = response.suppliers.firstWhere(
                  (supplier) => supplier.id == lastOrderSupplierId,
                );
              } catch (e) {
                try {
                  matchingSupplier = response.suppliers.firstWhere(
                    (supplier) =>
                        supplier.name.toLowerCase() ==
                        lastOrderSupplierName.toLowerCase(),
                  );
                } catch (e) {
                  matchingSupplier = response.suppliers.first;
                }
              }

              if (matchingSupplier != null) {
                _selectedSuppliers[productId] = matchingSupplier;
                print(
                    'Set default supplier for product $productId: ${matchingSupplier.name}');
              }
            } else if (response.suppliers.isNotEmpty) {
              _selectedSuppliers[productId] = response.suppliers.first;
              print(
                  'Set first available supplier for product $productId: ${response.suppliers.first.name}');
            }
          }
        });
      } else {
        print('Failed to load suppliers for product $productId');
      }
    } catch (e) {
      print('Error loading suppliers for product $productId: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(isSelected: _selectAll);
      }
    });
  }

  void _toggleItemSelection(int index) {
    setState(() {
      _items[index] =
          _items[index].copyWith(isSelected: !_items[index].isSelected);
      _updateSelectAllState();
    });
  }

  void _updateSelectAllState() {
    final selectedCount = _items.where((item) => item.isSelected).length;
    setState(() {
      _selectAll = selectedCount == _items.length && _items.isNotEmpty;
    });
  }

  void _updateQuantity(int productId, String value) {
    final quantity = int.tryParse(value);
    if (quantity != null && quantity > 0) {
      final itemIndex =
          _items.indexWhere((item) => item.product.productId == productId);
      if (itemIndex != -1) {
        setState(() {
          _items[itemIndex] =
              _items[itemIndex].copyWith(customQuantity: quantity);
        });
      }
    }
  }

  void _updateSupplier(int productId, SupplierInfo? supplier) {
    setState(() {
      _selectedSuppliers[productId] = supplier;
    });
  }

  Future<void> _generateOrders() async {
    final selectedItems = _items.where((item) => item.isSelected).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one item to generate orders'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingOrders = true;
    });

    try {
      // Prepare request data
      Map<int, int>? customQuantities;
      Map<int, int>? customSuppliers;
      int? globalSupplierId;

      // Handle global supplier override
      if (_useGlobalSupplier && _globalSupplier != null) {
        globalSupplierId = _globalSupplier!.id;
      }

      // Collect custom quantities
      Map<int, int> quantities = {};
      for (var item in selectedItems) {
        final controller = _quantityControllers[item.product.productId];
        if (controller != null) {
          final quantity = int.tryParse(controller.text) ?? item.stockDeficit;
          if (quantity != item.stockDeficit) {
            quantities[item.product.productId] = quantity;
          }
        }
      }
      if (quantities.isNotEmpty) {
        customQuantities = quantities;
      }

      // Collect custom suppliers (only if not using global supplier)
      if (!_useGlobalSupplier) {
        Map<int, int> suppliers = {};
        for (var item in selectedItems) {
          final selectedSupplier = _selectedSuppliers[item.product.productId];
          if (selectedSupplier != null && item.lastOrder != null) {
            // Only add if different from default supplier
            if (selectedSupplier.id != item.lastOrder!.supplier.id) {
              suppliers[item.product.productId] = selectedSupplier.id;
            }
          } else if (selectedSupplier != null) {
            // Add if there's no last order but supplier is selected
            suppliers[item.product.productId] = selectedSupplier.id;
          }
        }
        if (suppliers.isNotEmpty) {
          customSuppliers = suppliers;
        }
      }

      GenerateOrdersResponse? response;

      if (_selectAll) {
        response = await LowStockService.generateOrders(
          selectAll: true,
          customQuantities: customQuantities,
          customSupplierId: globalSupplierId,
          customSuppliers: customSuppliers,
        );
      } else {
        final selectedProductIds =
            selectedItems.map((item) => item.product.productId).toList();
        response = await LowStockService.generateOrders(
          selectedProductIds: selectedProductIds,
          selectAll: false,
          customQuantities: customQuantities,
          customSupplierId: globalSupplierId,
          customSuppliers: customSuppliers,
        );
      }

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onOrdersGenerated != null) {
          widget.onOrdersGenerated!();
        }

        Navigator.of(context).pop();
      } else {
        throw Exception('Failed to generate orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingOrders = false;
        });
      }
    }
  }

  Color _getAlertColor(String alertLevel) {
    switch (alertLevel.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'LOW':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _items.where((item) => item.isSelected).length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 29, 41, 57),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
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
              child: Column(
                children: [
                  // Title Row
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 28.sp,
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Stock Alert - Advanced Order Generation',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_items.length} items need restocking',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: (value) => _toggleSelectAll(),
                            activeColor:
                                const Color.fromARGB(255, 105, 65, 198),
                            checkColor: Colors.white,
                          ),
                          Text(
                            'Select All',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 16.w),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Global Options Row
                  Row(
                    children: [
                      // Global Supplier Toggle
                      Row(
                        children: [
                          Checkbox(
                            value: _useGlobalSupplier,
                            onChanged: (value) {
                              setState(() {
                                _useGlobalSupplier = value ?? false;
                              });
                            },
                            activeColor:
                                const Color.fromARGB(255, 105, 65, 198),
                          ),
                          Text(
                            'Use same supplier for all items:',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12.w),

                      // Global Supplier Dropdown
                      if (_useGlobalSupplier)
                        Container(
                          width: 200.w,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: const Color.fromARGB(255, 105, 65, 198),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SupplierInfo>(
                              value: _globalSupplier,
                              hint: Text(
                                'Select Global Supplier',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12.sp,
                                  color: Colors.white54,
                                ),
                              ),
                              dropdownColor:
                                  const Color.fromARGB(255, 36, 50, 69),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12.sp,
                                color: Colors.white,
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white70,
                                size: 20.sp,
                              ),
                              isExpanded: true,
                              items: _allSuppliers.map((supplier) {
                                return DropdownMenuItem<SupplierInfo>(
                                  value: supplier,
                                  child: Text(
                                    supplier.name,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (supplier) {
                                setState(() {
                                  _globalSupplier = supplier;
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    // Summary Stats
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 36, 50, 69),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                              'Critical',
                              LowStockService.getAlertLevelCounts(
                                      _items)['CRITICAL'] ??
                                  0,
                              Colors.red),
                          _buildStatItem(
                              'Warning',
                              LowStockService.getAlertLevelCounts(
                                      _items)['WARNING'] ??
                                  0,
                              Colors.orange),
                          _buildStatItem(
                              'Low',
                              LowStockService.getAlertLevelCounts(
                                      _items)['LOW'] ??
                                  0,
                              Colors.yellow),
                          _buildStatItem('Selected', selectedCount,
                              const Color.fromARGB(255, 105, 65, 198)),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Items List
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 36, 50, 69),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                            // List Header
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 47, 71, 82),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12.r),
                                  topRight: Radius.circular(12.r),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 40.w), // Checkbox space
                                  SizedBox(width: 60.w), // Image space
                                  Expanded(
                                      flex: 2,
                                      child: Text('Product',
                                          style: _headerStyle())),
                                  Expanded(
                                      flex: 1,
                                      child: Text('Current/Min',
                                          style: _headerStyle())),
                                  Expanded(
                                      flex: 1,
                                      child: Text('Order Qty',
                                          style: _headerStyle())),
                                  Expanded(
                                      flex: 1,
                                      child:
                                          Text('Alert', style: _headerStyle())),
                                  if (!_useGlobalSupplier)
                                    Expanded(
                                        flex: 2,
                                        child: Text('Supplier',
                                            style: _headerStyle())),
                                ],
                              ),
                            ),

                            // Items List
                            Expanded(
                              child: ListView.separated(
                                padding: EdgeInsets.all(16.w),
                                itemCount: _items.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.white.withOpacity(0.1),
                                  height: 16.h,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildItemRow(_items[index], index);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer with Generate Orders Button
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$selectedCount of ${_items.length} items selected',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16.sp,
                          color: Colors.white70,
                        ),
                      ),
                      if (_useGlobalSupplier && _globalSupplier != null)
                        Text(
                          'Global supplier: ${_globalSupplier!.name}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            color: const Color.fromARGB(255, 105, 65, 198),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 200.w,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isGeneratingOrders || selectedCount == 0
                          ? null
                          : _generateOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 105, 65, 198),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isGeneratingOrders
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'Generating...',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Generate Orders',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.sp,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.spaceGrotesk(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
  }

  Widget _buildItemRow(LowStockItem item, int index) {
    final suppliers = _productSuppliers[item.product.productId] ?? [];
    final selectedSupplier = _selectedSuppliers[item.product.productId];
    final quantityController = _quantityControllers[item.product.productId];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 40.w,
            child: Checkbox(
              value: item.isSelected,
              onChanged: (value) => _toggleItemSelection(index),
              activeColor: const Color.fromARGB(255, 105, 65, 198),
              checkColor: Colors.white,
            ),
          ),

          // Product Image
          SizedBox(
            width: 60.w,
            child: Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: item.product.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        item.product.image!,
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
                      Icons.inventory_outlined,
                      color: Colors.white54,
                      size: 24.sp,
                    ),
            ),
          ),

          // Product Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.product.category.categoryName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Current/Min Stock
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.product.quantity}/${item.product.lowStock}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Need: ${item.stockDeficit}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Order Quantity Input
          Expanded(
            flex: 1,
            child: Container(
              width: 80.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) =>
                    _updateQuantity(item.product.productId, value),
              ),
            ),
          ),

          // Alert Level
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _getAlertColor(item.alertLevel).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _getAlertColor(item.alertLevel),
                  width: 1,
                ),
              ),
              child: Text(
                item.alertLevel.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _getAlertColor(item.alertLevel),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Supplier Dropdown (only show if not using global supplier)
          if (!_useGlobalSupplier)
            Expanded(
              flex: 2,
              child: Container(
                margin: EdgeInsets.only(left: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: _buildSupplierDropdown(
                    suppliers, selectedSupplier, item.product.productId),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierDropdown(List<SupplierInfo> suppliers,
      SupplierInfo? selectedSupplier, int productId) {
    try {
      if (suppliers.isEmpty) {
        return Center(
          child: Text(
            'No suppliers',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.sp,
              color: Colors.white54,
            ),
          ),
        );
      }

      final validSelectedSupplier =
          suppliers.any((s) => s.id == selectedSupplier?.id)
              ? selectedSupplier
              : null;

      return DropdownButtonHideUnderline(
        child: DropdownButton<SupplierInfo>(
          value: validSelectedSupplier,
          hint: Text(
            'Select Supplier',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.sp,
              color: Colors.white54,
            ),
          ),
          dropdownColor: const Color.fromARGB(255, 36, 50, 69),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.sp,
            color: Colors.white,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.white70,
            size: 20.sp,
          ),
          isExpanded: true,
          items: suppliers.map((supplier) {
            return DropdownMenuItem<SupplierInfo>(
              value: supplier,
              child: Text(
                supplier.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.sp,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (supplier) {
            if (supplier != null) {
              _updateSupplier(productId, supplier);
            }
          },
        ),
      );
    } catch (e) {
      print('Error building supplier dropdown for product $productId: $e');
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'Error loading suppliers',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.sp,
            color: Colors.red,
          ),
        ),
      );
    }
  }
}

// Function to show the popup
Future<void> showLowStockPopup(
  BuildContext context,
  List<LowStockItem> lowStockItems, {
  VoidCallback? onOrdersGenerated,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return LowStockPopup(
        lowStockItems: lowStockItems,
        onOrdersGenerated: onOrdersGenerated,
      );
    },
  );
}
