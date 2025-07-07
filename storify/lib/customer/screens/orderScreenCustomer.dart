// lib/customer/screens/customer_orders_screen.dart
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/customer/widgets/CustomerOrderService.dart';
import 'package:storify/customer/widgets/mapPopUp.dart';
import 'package:storify/customer/widgets/modelCustomer.dart'
    show CartItem, Category, Order, Product;
import 'package:storify/customer/widgets/navbarCus.dart';
import 'package:storify/customer/widgets/uiWidgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class CustomerOrders extends StatefulWidget {
  const CustomerOrders({Key? key}) : super(key: key);

  @override
  State<CustomerOrders> createState() => _CustomerOrdersState();
}

class _CustomerOrdersState extends State<CustomerOrders> {
  int _currentIndex = 0;
  String? profilePictureUrl;
  String _searchQuery = "";

  // States
  List<Category> _categories = [];
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  String _selectedCategoryId = "all";

  // Loading states
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = false;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    // Use post frame callback to avoid initState issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilePicture();
      _loadData();
    });
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        profilePictureUrl = prefs.getString('profilePicture');
      });
    }
  }

  Future<void> _loadData() async {
    await _loadCategories();
    if (_categories.isNotEmpty && mounted) {
      await _loadProductsByCategory(_categories[0].id);
      if (mounted) {
        setState(() {
          _selectedCategoryId = _categories[0].id.toString();
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        _isLoadingCategories = true;
      });
    }

    try {
      final categories = await CustomerOrderService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        final l10n =
            Localizations.of<AppLocalizations>(context, AppLocalizations)!;
        _showErrorSnackbar("${l10n.customerOrdersLoadCategoriesError}$e");
      }
    }
  }

  Future<void> _loadProductsByCategory(int categoryId) async {
    if (mounted) {
      setState(() {
        _isLoadingProducts = true;
        _products = [];
      });
    }

    try {
      final products =
          await CustomerOrderService.getProductsByCategory(categoryId);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
        final l10n =
            Localizations.of<AppLocalizations>(context, AppLocalizations)!;
        _showErrorSnackbar("${l10n.customerOrdersLoadProductsError}$e");
      }
    }
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        // Current Orders - no navigation needed
        break;
      case 1:
        Navigator.pushNamed(context, '/customer/history');
        break;
    }
  }

  void _selectCategory(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId.toString();
    });
    _loadProductsByCategory(categoryId);
  }

  void _addToCart(CartItem item) {
    setState(() {
      // Check if item already exists in cart
      int existingIndex = _cartItems
          .indexWhere((cartItem) => cartItem.product.id == item.product.id);

      if (existingIndex != -1) {
        // If exists, increase quantity
        _cartItems[existingIndex].quantity++;
      } else {
        // If not exists, add new item
        _cartItems.add(item);
      }
    });

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.customerOrdersItemAddedToCart(item.product.name),
          style: isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF7B5CFA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _updateCartItemQuantity(int index, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
    });
  }

  Future<void> _placeOrder() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    if (_cartItems.isEmpty) {
      _showErrorSnackbar(l10n.customerOrdersCartEmpty);
      return;
    }

    // Check if location is set using backend API
    final bool locationSet = await CustomerOrderService.isLocationSet();

    if (!locationSet) {
      // Show location popup if location is not set
      _showLocationPopup();
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final order = Order(items: _cartItems);
      final result = await CustomerOrderService.placeOrder(order);

      // Clear cart after successful order
      setState(() {
        _cartItems = [];
        _isPlacingOrder = false;
      });

      final isArabic = LocalizationHelper.isArabic(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.customerOrdersOrderPlacedSuccess,
            style: isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      // Error handling remains the same
      setState(() {
        _isPlacingOrder = false;
      });

      if (e is InsufficientStockException) {
        _showStockLimitDialog(e);
      } else {
        _showErrorSnackbar("${l10n.customerOrdersPlaceOrderError}$e");
      }
    }
  }

  // UI Helpers for showing dialogs and popups
  void _showLocationPopup() {
    debugPrint('📍 Showing location popup');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationSelectionPopup(
        onLocationSaved: () {
          debugPrint('📍 Location saved callback - placing order again');
          // After saving location, try placing order again
          _placeOrder();
        },
      ),
    );
  }

  void _showStockLimitDialog(InsufficientStockException exception) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: const Color(0xFF283548),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l10n.customerOrdersInsufficientStockTitle,
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
                Text(
                  l10n.customerOrdersStockDialogProduct(exception.productName),
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.white)
                      : GoogleFonts.spaceGrotesk(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.customerOrdersStockDialogAvailable(
                      exception.available.toString()),
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.white)
                      : GoogleFonts.spaceGrotesk(color: Colors.white),
                ),
                Text(
                  l10n.customerOrdersStockDialogRequested(
                      exception.requested.toString()),
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.white)
                      : GoogleFonts.spaceGrotesk(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.customerOrdersStockDialogUpdateQuestion,
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.white)
                      : GoogleFonts.spaceGrotesk(color: Colors.white),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  l10n.customerOrdersStockDialogCancel,
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.white)
                      : GoogleFonts.spaceGrotesk(color: Colors.white),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5CFA),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Update the cart item quantity to maximum available
                  final index = _cartItems.indexWhere(
                    (item) => item.product.name == exception.productName,
                  );

                  if (index != -1) {
                    setState(() {
                      _cartItems[index].quantity = exception.available;
                    });
                  }

                  Navigator.of(context).pop();
                },
                child: Text(
                  l10n.customerOrdersStockDialogUpdateQuantity,
                  style: isArabic
                      ? GoogleFonts.cairo()
                      : GoogleFonts.spaceGrotesk(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    final isArabic = LocalizationHelper.isArabic(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Search helper
  List<Product> _getFilteredProducts() {
    if (_searchQuery.isEmpty) {
      return _products;
    }

    return _products
        .where((product) =>
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 29, 41, 57),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: NavigationBarCustomer(
            currentIndex: _currentIndex,
            onTap: _onNavItemTap,
            profilePictureUrl: profilePictureUrl,
          ),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Categories and Products
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsetsDirectional.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Order Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.customerOrdersNewOrderTitle,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                        IconButton(
                          onPressed: _loadData,
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.white70,
                            size: 28,
                          ),
                          tooltip: l10n.customerOrdersRefreshTooltip,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF283548),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: isArabic
                            ? GoogleFonts.cairo(color: Colors.white)
                            : GoogleFonts.spaceGrotesk(color: Colors.white),
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: l10n.customerOrdersSearchPlaceholder,
                          hintStyle: isArabic
                              ? GoogleFonts.cairo(color: Colors.grey[400])
                              : GoogleFonts.spaceGrotesk(
                                  color: Colors.grey[400]),
                          prefixIcon: isRtl
                              ? null
                              : Icon(Icons.search, color: Colors.grey[400]),
                          suffixIcon: isRtl
                              ? Icon(Icons.search, color: Colors.grey[400])
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Categories section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.customerOrdersCategoriesTitle,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                        const SizedBox(height: 15),

                        // Horizontal scrollable categories
                        _isLoadingCategories
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: const Color(0xFF7B5CFA),
                                ),
                              )
                            : Container(
                                height: 120,
                                child: CategoryList(
                                  categories: _categories,
                                  selectedCategoryId: _selectedCategoryId,
                                  onCategorySelected: _selectCategory,
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Products section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Products header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.customerOrdersProductsTitle,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                              ),
                              if (_products.isNotEmpty)
                                Container(
                                  padding: EdgeInsetsDirectional.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF283548),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    l10n.customerOrdersItemsCount(
                                        _getFilteredProducts()
                                            .length
                                            .toString()),
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            color: Colors.grey[300],
                                            fontSize: 14,
                                          )
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.grey[300],
                                            fontSize: 14,
                                          ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Products grid
                          Expanded(
                            child: _isLoadingProducts
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: const Color(0xFF7B5CFA),
                                    ),
                                  )
                                : _getFilteredProducts().isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              l10n.customerOrdersNoProductsMessage,
                                              textAlign: TextAlign.center,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      color: Colors.grey[400],
                                                      fontSize: 16,
                                                    )
                                                  : GoogleFonts.spaceGrotesk(
                                                      color: Colors.grey[400],
                                                      fontSize: 16,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          childAspectRatio: 0.9,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 16,
                                        ),
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemCount:
                                            _getFilteredProducts().length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              _getFilteredProducts()[index];
                                          return _buildProductItem(product);
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right side - Cart
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                    top: 24.0, end: 24.0, bottom: 24.0),
                child: CartWidget(
                  cartItems: _cartItems,
                  updateQuantity: _updateCartItemQuantity,
                  placeOrder: _placeOrder,
                  isPlacingOrder: _isPlacingOrder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF283548),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: product.image,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF7B5CFA),
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          // Product Details
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsetsDirectional.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name and Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${product.sellPrice.toStringAsFixed(2)}",
                        style: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 14,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                      ),
                    ],
                  ),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final cartItem = CartItem(
                          product: product,
                          quantity: 1,
                        );
                        _addToCart(cartItem);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5CFA),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFF7B5CFA).withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.customerOrdersAddToCartButton,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
    );
  }
}
