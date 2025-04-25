import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/supplier_models.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/supplier_service.dart';

class SupplierOrderPopup extends StatefulWidget {
  const SupplierOrderPopup({super.key});

  @override
  State<SupplierOrderPopup> createState() => _SupplierOrderPopupState();
}

class _SupplierOrderPopupState extends State<SupplierOrderPopup> {
  // Loading states
  bool _isLoadingSuppliers = true;
  bool _isLoadingProducts = false;
  bool _isPlacingOrder = false;
  String? _errorMessage;

  // Selected supplier
  Supplier? _selectedSupplier;

  // Selected product
  SupplierProduct? _selectedProduct;

  // Cart items (now grouped by supplier)
  final Map<int, List<CartItem>> _cartItemsBySupplierId = {};

  // All products from all suppliers - used for price comparison
  final Map<int, List<SupplierProduct>> _allProductsMap = {};

  // All suppliers
  List<Supplier> _suppliers = [];

  // Products for the selected supplier
  List<SupplierProduct> _products = [];

  // Quantity for the selected product
  int _quantity = 1;

  // Order queue - track pending orders
  final List<OrderRequest> _orderQueue = [];

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  // Fetch list of suppliers
  Future<void> _fetchSuppliers() async {
    setState(() {
      _isLoadingSuppliers = true;
      _errorMessage = null;
    });

    try {
      final suppliers = await SupplierService.getSuppliers();
      setState(() {
        _suppliers = suppliers;
        _isLoadingSuppliers = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load suppliers: $e';
        _isLoadingSuppliers = false;
      });
    }
  }

  // Fetch products for selected supplier
  Future<void> _fetchProducts(int supplierId) async {
    setState(() {
      _isLoadingProducts = true;
      _errorMessage = null;
      _selectedProduct = null;
    });

    try {
      final products = await SupplierService.getSupplierProducts(supplierId);
      setState(() {
        _products = products;
        // Store products for future price comparison
        _allProductsMap[supplierId] = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoadingProducts = false;
      });
    }
  }

  // Check if a product has a better price from another supplier
  Future<void> _checkForBetterPrice(SupplierProduct product) async {
    try {
      final result = await SupplierService.findLowerPriceProduct(
          product, _selectedSupplier!.id);

      if (result != null) {
        final lowerPriceProduct = result['product'] as SupplierProduct;
        final lowerPriceSupplier = result['supplier'] as Supplier;

        // Show the alert
        if (mounted) {
          _showBetterPriceAlert(
            product,
            lowerPriceProduct,
            lowerPriceSupplier,
          );
        }
      }
    } catch (e) {
      print('Error checking for better price: $e');
    }
  }

  // Show alert for better price
  void _showBetterPriceAlert(
    SupplierProduct currentProduct,
    SupplierProduct betterProduct,
    Supplier betterSupplier,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final priceDifference =
            currentProduct.costPrice - betterProduct.costPrice;
        final percentageSaving =
            (priceDifference / currentProduct.costPrice) * 100;

        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 36, 50, 69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Better Price Available!',
            style: GoogleFonts.spaceGrotesk(
              color: const Color.fromARGB(255, 255, 232, 29),
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This product is available at a lower price:',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 16.h),
              _buildPriceComparisonRow(
                'Current: ${_selectedSupplier!.name}',
                '\$${currentProduct.costPrice.toStringAsFixed(2)}',
              ),
              _buildPriceComparisonRow(
                'Better: ${betterSupplier.name}',
                '\$${betterProduct.costPrice.toStringAsFixed(2)}',
                isHighlighted: true,
              ),
              Divider(color: Colors.white24),
              _buildPriceComparisonRow(
                'You Save:',
                '\$${priceDifference.toStringAsFixed(2)} (${percentageSaving.toStringAsFixed(0)}%)',
                isHighlighted: true,
              ),
              SizedBox(height: 16.h),
              Text(
                'Would you like to switch suppliers for this product?',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Keep Current',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Switch to the better supplier
                _selectSupplier(betterSupplier);
              },
              child: Text(
                'Switch Supplier',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriceComparisonRow(String label, String price,
      {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 15.sp,
            ),
          ),
          Text(
            price,
            style: GoogleFonts.spaceGrotesk(
              color: isHighlighted
                  ? const Color.fromARGB(255, 0, 224, 116)
                  : Colors.white,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              fontSize: 15.sp,
            ),
          ),
        ],
      ),
    );
  }

  // Select a supplier from the dropdown
  void _selectSupplier(Supplier supplier) {
    setState(() {
      _selectedSupplier = supplier;
      _selectedProduct = null;
    });
    _fetchProducts(supplier.id);
  }

  // Select a product
  void _selectProduct(SupplierProduct product) {
    setState(() {
      _selectedProduct = product;
      _quantity = 1; // Reset quantity when selecting a new product
    });

    // Check if this product is available at a better price
    _checkForBetterPrice(product);
  }

  // Add product to cart
  void _addToCart() {
    if (_selectedProduct != null &&
        _quantity > 0 &&
        _selectedSupplier != null) {
      setState(() {
        // Get the cart for this supplier or create a new one
        final supplierCart =
            _cartItemsBySupplierId[_selectedSupplier!.id] ?? [];

        // Check if product already exists in cart
        final existingItemIndex = supplierCart.indexWhere(
            (item) => item.productId == _selectedProduct!.productId);

        if (existingItemIndex >= 0) {
          // Update quantity if product already in cart
          final updatedItem = supplierCart[existingItemIndex].copyWith(
              quantity: supplierCart[existingItemIndex].quantity + _quantity);
          supplierCart[existingItemIndex] = updatedItem;
        } else {
          // Add new item to cart
          supplierCart.add(CartItem(
            productId: _selectedProduct!.productId,
            name: _selectedProduct!.name,
            price: _selectedProduct!.costPrice,
            quantity: _quantity,
            image: _selectedProduct!.image,
            supplierId: _selectedSupplier!.id,
            supplierName: _selectedSupplier!.name,
          ));
        }

        // Update the cart for this supplier
        _cartItemsBySupplierId[_selectedSupplier!.id] = supplierCart;

        // Reset quantity
        _quantity = 1;
      });
    }
  }

  // Remove item from cart
  void _removeFromCart(int supplierId, int productId) {
    setState(() {
      final supplierCart = _cartItemsBySupplierId[supplierId];
      if (supplierCart != null) {
        supplierCart.removeWhere((item) => item.productId == productId);

        // If cart is empty after removal, remove the supplier entry
        if (supplierCart.isEmpty) {
          _cartItemsBySupplierId.remove(supplierId);
        } else {
          _cartItemsBySupplierId[supplierId] = supplierCart;
        }
      }
    });
  }

  // Update quantity for selected product
  void _updateQuantity(int value) {
    if (value >= 1) {
      setState(() {
        _quantity = value;
      });
    }
  }

  // Calculate total for a specific supplier's cart
  double _getSupplierCartTotal(int supplierId) {
    final supplierCart = _cartItemsBySupplierId[supplierId];
    if (supplierCart == null || supplierCart.isEmpty) {
      return 0.0;
    }

    return supplierCart.fold(
        0.0, (total, item) => total + (item.price * item.quantity));
  }

  // Calculate grand total across all suppliers
  double get _grandTotal {
    double total = 0.0;
    _cartItemsBySupplierId.forEach((supplierId, items) {
      total += _getSupplierCartTotal(supplierId);
    });
    return total;
  }

  // Place order for a specific supplier
  Future<bool> _placeSupplierOrder(int supplierId) async {
    final supplierCart = _cartItemsBySupplierId[supplierId];
    if (supplierCart == null || supplierCart.isEmpty) {
      return false;
    }

    try {
      final orderItems = supplierCart
          .map((item) => OrderItem(
                productId: item.productId,
                quantity: item.quantity,
              ))
          .toList();

      final orderRequest = OrderRequest(
        supplierId: supplierId,
        items: orderItems,
      );

      final success = await SupplierService.placeOrder(orderRequest);

      if (success) {
        // Remove this supplier's items from cart
        setState(() {
          _cartItemsBySupplierId.remove(supplierId);
        });

        // If this was the last supplier in the cart, close with refresh signal
        if (_cartItemsBySupplierId.isEmpty) {
          Navigator.of(context).pop(true); // Return true to trigger refresh
        }

        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }

  // Place all orders sequentially
  Future<void> _placeAllOrders() async {
    if (_cartItemsBySupplierId.isEmpty) {
      return;
    }

    setState(() {
      _isPlacingOrder = true;
      _orderQueue.clear();
    });

    // Create order queue
    _cartItemsBySupplierId.forEach((supplierId, items) {
      final orderItems = items
          .map((item) => OrderItem(
                productId: item.productId,
                quantity: item.quantity,
              ))
          .toList();

      _orderQueue.add(OrderRequest(
        supplierId: supplierId,
        items: orderItems,
      ));
    });

    // Process each order sequentially
    bool hasError = false;
    String? errorMsg;

    for (var order in _orderQueue) {
      try {
        final success = await SupplierService.placeOrder(order);
        if (success) {
          // Remove this supplier's items from cart
          setState(() {
            _cartItemsBySupplierId.remove(order.supplierId);
          });
        } else {
          hasError = true;
          errorMsg = 'Failed to place order for supplier #${order.supplierId}';
          break;
        }
      } catch (e) {
        hasError = true;
        errorMsg = 'Error placing order: $e';
        break;
      }
    }

    setState(() {
      _isPlacingOrder = false;
      if (hasError) {
        _errorMessage = errorMsg;
      }
    });

    // If no errors and all orders placed, close the dialog with refresh signal
    if (!hasError && _cartItemsBySupplierId.isEmpty) {
      Navigator.of(context).pop(true); // Return true to trigger refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(24.w),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height * 0.8,
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
            // Header with close button
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Text(
                    'Place Order from Suppliers',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // Error message if any
            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[300],
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.red[300],
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.red[300],
                        size: 16.sp,
                      ),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side (Supplier selection and Cart)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Supplier selection
                          Text(
                            'Select Supplier',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 36, 50, 69),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color.fromARGB(255, 47, 71, 82),
                                width: 1,
                              ),
                            ),
                            child: _isLoadingSuppliers
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.w),
                                      child: CircularProgressIndicator(
                                        color: const Color.fromARGB(
                                            255, 105, 65, 198),
                                      ),
                                    ),
                                  )
                                : DropdownButtonHideUnderline(
                                    child: DropdownButton<Supplier>(
                                      value: _selectedSupplier,
                                      hint: Text(
                                        'Please choose a supplier',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white70,
                                        size: 24.sp,
                                      ),
                                      isExpanded: true,
                                      dropdownColor:
                                          const Color.fromARGB(255, 36, 50, 69),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16.sp,
                                        color: Colors.white,
                                      ),
                                      items: _suppliers
                                          .map<DropdownMenuItem<Supplier>>(
                                              (Supplier supplier) {
                                        return DropdownMenuItem<Supplier>(
                                          value: supplier,
                                          child: Text(supplier.name),
                                        );
                                      }).toList(),
                                      onChanged: (Supplier? newValue) {
                                        if (newValue != null) {
                                          _selectSupplier(newValue);
                                        }
                                      },
                                    ),
                                  ),
                          ),

                          SizedBox(height: 30.h),

                          // Cart - Now with sections by supplier
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 50, 69),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Cart header
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/cart.svg',
                                        width: 24.w,
                                        height: 24.h,
                                        placeholderBuilder:
                                            (BuildContext context) => Icon(
                                          Icons.shopping_cart,
                                          size: 24.sp,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'Cart',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        '(${_cartItemsBySupplierId.values.fold<int>(0, (total, items) => total + items.length)} items)',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 14.sp,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 16.h),

                                  // Cart items (grouped by supplier)
                                  Expanded(
                                    child: _cartItemsBySupplierId.isEmpty
                                        ? _buildEmptyState(
                                            icon:
                                                'assets/images/empty_cart.svg',
                                            message: 'Your cart is empty',
                                            description:
                                                'Add products from the list to place an order',
                                            placeholderIcon:
                                                Icons.shopping_cart_outlined,
                                          )
                                        : ListView(
                                            children: _cartItemsBySupplierId
                                                .entries
                                                .map((entry) {
                                              final supplierId = entry.key;
                                              final supplierItems = entry.value;
                                              final supplierName =
                                                  supplierItems.isNotEmpty
                                                      ? supplierItems
                                                          .first.supplierName
                                                      : 'Unknown Supplier';

                                              return _buildSupplierCartSection(
                                                supplierId,
                                                supplierName,
                                                supplierItems,
                                              );
                                            }).toList(),
                                          ),
                                  ),

                                  // Cart summary and confirm button for all orders
                                  if (_cartItemsBySupplierId.isNotEmpty) ...[
                                    Divider(
                                      color: Colors.white.withOpacity(0.1),
                                      height: 24.h,
                                    ),

                                    // Grand Total
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Grand Total',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '\$${_grandTotal.toStringAsFixed(2)}',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color.fromARGB(
                                                255, 105, 65, 198),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 16.h),

                                    // Confirm all orders button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 105, 65, 198),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 14.h),
                                        ),
                                        onPressed: _isPlacingOrder
                                            ? null
                                            : _placeAllOrders,
                                        child: _isPlacingOrder
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 20.w,
                                                    height: 20.h,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.w,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10.w),
                                                  Text(
                                                    'Processing Orders...',
                                                    style: GoogleFonts
                                                        .spaceGrotesk(
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                'Confirm All Orders',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 20.w),

                    // Right side (Products list and Product details)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Products list
                          Text(
                            'Products ${_selectedSupplier != null ? "(${_products.length})" : ""}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            height: 300.h,
                            width: double.infinity,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 36, 50, 69),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: _isLoadingProducts
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: const Color.fromARGB(
                                          255, 105, 65, 198),
                                    ),
                                  )
                                : _selectedSupplier == null
                                    ? _buildEmptyState(
                                        icon:
                                            'assets/images/choose_supplier.svg',
                                        message: 'No products to display',
                                        description:
                                            'Please select a supplier first',
                                        placeholderIcon:
                                            Icons.inventory_2_outlined,
                                      )
                                    : _products.isEmpty
                                        ? _buildEmptyState(
                                            icon:
                                                'assets/images/no_products.svg',
                                            message: 'No products available',
                                            description:
                                                'This supplier has no products listed',
                                            placeholderIcon:
                                                Icons.inventory_2_outlined,
                                          )
                                        : GridView.builder(
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              childAspectRatio: 1.2,
                                              crossAxisSpacing: 16.w,
                                              mainAxisSpacing: 16.h,
                                            ),
                                            itemCount: _products.length,
                                            itemBuilder: (context, index) {
                                              final product = _products[index];
                                              final isSelected =
                                                  _selectedProduct?.productId ==
                                                      product.productId;

                                              return GestureDetector(
                                                onTap: () =>
                                                    _selectProduct(product),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? const Color.fromARGB(
                                                                255,
                                                                105,
                                                                65,
                                                                198)
                                                            .withOpacity(0.2)
                                                        : Colors.white
                                                            .withOpacity(0.05),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.r),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? const Color
                                                              .fromARGB(
                                                              255, 105, 65, 198)
                                                          : Colors.transparent,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  padding: EdgeInsets.all(12.w),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      // Product image
                                                      Expanded(
                                                        child: product.image !=
                                                                null
                                                            ? Image.network(
                                                                product.image!,
                                                                errorBuilder:
                                                                    (context,
                                                                        error,
                                                                        stackTrace) {
                                                                  return Icon(
                                                                    Icons.image,
                                                                    size: 40.sp,
                                                                    color: Colors
                                                                        .white70,
                                                                  );
                                                                },
                                                              )
                                                            : Icon(
                                                                Icons.image,
                                                                size: 40.sp,
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                      ),

                                                      SizedBox(height: 8.h),

                                                      // Product name
                                                      Text(
                                                        product.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          fontSize: 14.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),

                                                      SizedBox(height: 4.h),

                                                      // Price
                                                      Text(
                                                        '\$${product.costPrice.toStringAsFixed(2)}',
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          fontSize: 14.sp,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: const Color
                                                              .fromARGB(255,
                                                              105, 65, 198),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                          ),

                          SizedBox(height: 20.h),

                          // Product details
                          Text(
                            'Product Details',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 50, 69),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: _selectedProduct == null
                                  ? _buildEmptyState(
                                      icon: 'assets/images/select_product.svg',
                                      message: 'No product selected',
                                      description:
                                          'Select a product from the list to see details',
                                      placeholderIcon:
                                          Icons.shopping_bag_outlined,
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Product image
                                        Container(
                                          width: 150.w,
                                          height: 150.h,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                          ),
                                          padding: EdgeInsets.all(12.w),
                                          child: _selectedProduct!.image != null
                                              ? Image.network(
                                                  _selectedProduct!.image!,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Icon(
                                                      Icons.image,
                                                      size: 60.sp,
                                                      color: Colors.white70,
                                                    );
                                                  },
                                                )
                                              : Icon(
                                                  Icons.image,
                                                  size: 60.sp,
                                                  color: Colors.white70,
                                                ),
                                        ),

                                        SizedBox(width: 20.w),

                                        // Product details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Name and price
                                              Text(
                                                _selectedProduct!.name,
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 22.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Row(
                                                children: [
                                                  Text(
                                                    '\$${_selectedProduct!.costPrice.toStringAsFixed(2)}',
                                                    style: GoogleFonts
                                                        .spaceGrotesk(
                                                      fontSize: 20.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              105,
                                                              65,
                                                              198),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 8.w,
                                                      vertical: 4.h,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color.fromARGB(
                                                                  255,
                                                                  0,
                                                                  224,
                                                                  116)
                                                              .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.r),
                                                    ),
                                                    child: Text(
                                                      'In Stock: ${_selectedProduct!.quantity}',
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 0, 224, 116),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              SizedBox(height: 16.h),

                                              // Description
                                              Text(
                                                'Description',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                _selectedProduct!.description ??
                                                    'No description available',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 14.sp,
                                                  color: Colors.white70,
                                                ),
                                              ),

                                              const Spacer(),

                                              // Quantity selector and add button
                                              Row(
                                                children: [
                                                  // Quantity controls
                                                  Container(
                                                    height: 42.h,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.05),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.r),
                                                      border: Border.all(
                                                        color: Colors.white
                                                            .withOpacity(0.1),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        // Decrease button
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.remove,
                                                            color:
                                                                Colors.white70,
                                                            size: 18.sp,
                                                          ),
                                                          onPressed: () =>
                                                              _updateQuantity(
                                                                  _quantity -
                                                                      1),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              BoxConstraints(
                                                            minWidth: 36.w,
                                                            minHeight: 36.h,
                                                          ),
                                                        ),

                                                        // Quantity input
                                                        SizedBox(
                                                          width: 50.w,
                                                          child: TextField(
                                                            controller:
                                                                TextEditingController(
                                                                    text: _quantity
                                                                        .toString()),
                                                            onChanged: (value) {
                                                              final intValue =
                                                                  int.tryParse(
                                                                      value);
                                                              if (intValue !=
                                                                  null) {
                                                                _updateQuantity(
                                                                    intValue);
                                                              }
                                                            },
                                                            textAlign: TextAlign
                                                                .center,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            style: GoogleFonts
                                                                .spaceGrotesk(
                                                              fontSize: 16.sp,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            decoration:
                                                                const InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                          ),
                                                        ),

                                                        // Increase button
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.add,
                                                            color:
                                                                Colors.white70,
                                                            size: 18.sp,
                                                          ),
                                                          onPressed: () =>
                                                              _updateQuantity(
                                                                  _quantity +
                                                                      1),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              BoxConstraints(
                                                            minWidth: 36.w,
                                                            minHeight: 36.h,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  SizedBox(width: 16.w),

                                                  // Add to cart button
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color
                                                                .fromARGB(255,
                                                                105, 65, 198),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.r),
                                                        ),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: 16.w,
                                                          vertical: 12.h,
                                                        ),
                                                      ),
                                                      onPressed: _addToCart,
                                                      icon: Icon(
                                                        Icons.add_shopping_cart,
                                                        size: 18.sp,
                                                        color: Colors.white,
                                                      ),
                                                      label: Text(
                                                        'Add to Cart',
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
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

  // Build a supplier cart section
  Widget _buildSupplierCartSection(
    int supplierId,
    String supplierName,
    List<CartItem> items,
  ) {
    final supplierTotal = _getSupplierCartTotal(supplierId);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier header
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Icon(
                  Icons.store,
                  size: 18.sp,
                  color: const Color.fromARGB(255, 105, 65, 198),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    supplierName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '\$${supplierTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 105, 65, 198),
                  ),
                ),
              ],
            ),
          ),

          // Cart items for this supplier
          Container(
            constraints: BoxConstraints(
              maxHeight: 200.h,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.white.withOpacity(0.1),
                height: 12.h,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product image
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: item.image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.network(
                                item.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image,
                                    size: 20.sp,
                                    color: Colors.white70,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.image,
                              size: 20.sp,
                              color: Colors.white70,
                            ),
                    ),

                    SizedBox(width: 12.w),

                    // Product details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Text(
                                '${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12.sp,
                                  color: Colors.white70,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Remove button
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[300],
                        size: 18.sp,
                      ),
                      onPressed: () =>
                          _removeFromCart(supplierId, item.productId),
                      constraints: BoxConstraints(
                        minWidth: 30.w,
                        minHeight: 30.h,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                );
              },
            ),
          ),

          // Confirm order button for this supplier
          Padding(
            padding: EdgeInsets.all(12.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 224, 116),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                onPressed: _isPlacingOrder
                    ? null
                    : () async {
                        setState(() {
                          _isPlacingOrder = true;
                        });

                        try {
                          final success = await _placeSupplierOrder(supplierId);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Order placed successfully for $supplierName',
                                  style: GoogleFonts.spaceGrotesk(),
                                ),
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 224, 116),
                              ),
                            );
                          } else {
                            setState(() {
                              _errorMessage =
                                  'Failed to place order for $supplierName';
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _errorMessage = 'Error placing order: $e';
                          });
                        } finally {
                          setState(() {
                            _isPlacingOrder = false;
                          });
                        }
                      },
                child: _isPlacingOrder
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.w,
                        ),
                      )
                    : Text(
                        'Confirm Order',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build empty state widgets
  Widget _buildEmptyState({
    required String icon,
    required String message,
    required String description,
    required IconData placeholderIcon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            width: 60.w,
            height: 60.h,
            placeholderBuilder: (BuildContext context) => Icon(
              placeholderIcon,
              size: 60.sp,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.sp,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showSupplierOrderPopup(BuildContext context) async {
  // Show the dialog and wait for the result
  final shouldRefresh = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const SupplierOrderPopup();
    },
  );

  // Return true if orders were placed, false otherwise
  return shouldRefresh ?? false;
}
