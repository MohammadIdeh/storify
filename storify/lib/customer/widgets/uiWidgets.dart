// lib/customer/widgets/category_list.dart
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storify/customer/widgets/modelCustomer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class CategoryList extends StatefulWidget {
  final List<Category> categories;
  final String selectedCategoryId;
  final Function(int) onCategorySelected;

  const CategoryList({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = LocalizationHelper.isRTL(context);

    // Make sure we have enough categories to actually need scrolling
    if (widget.categories.length <= 1) {
      return _buildCategoryItem(
          widget.categories.isNotEmpty ? widget.categories[0] : null, 0);
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            // Handle mouse wheel scrolling
            _scrollController.jumpTo(
              (_scrollController.offset + pointerSignal.scrollDelta.dy)
                  .clamp(0.0, _scrollController.position.maxScrollExtent),
            );
          }
        },
        child: GestureDetector(
          // Enable drag scrolling
          onHorizontalDragUpdate: (details) {
            _scrollController.jumpTo(
              (_scrollController.offset - details.primaryDelta!)
                  .clamp(0.0, _scrollController.position.maxScrollExtent),
            );
          },
          child: Container(
            height: 120,
            child: ScrollConfiguration(
              // This ensures mouse drag works even on platforms where it might not by default
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics:
                    const AlwaysScrollableScrollPhysics(), // Force scrollable
                itemCount: widget.categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryItem(widget.categories[index], index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category? category, int index) {
    if (category == null) return Container(); // Safety check

    final isSelected = widget.selectedCategoryId == category.id.toString();
    final isArabic = LocalizationHelper.isArabic(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click, // Show clickable cursor
      child: GestureDetector(
        onTap: () => widget.onCategorySelected(category.id),
        child: Container(
          width: 100,
          margin: EdgeInsetsDirectional.only(
            end: 16,
            start: index == 0 ? 4 : 0, // Add a small margin to the first item
          ),
          child: Column(
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF283548),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                  border: isSelected
                      ? Border.all(color: const Color(0xFF7B5CFA), width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: CachedNetworkImage(
                    imageUrl: category.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF7B5CFA),
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.category,
                      color: isSelected ? const Color(0xFF7B5CFA) : Colors.grey,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color:
                            isSelected ? const Color(0xFF7B5CFA) : Colors.white,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color:
                            isSelected ? const Color(0xFF7B5CFA) : Colors.white,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(CartItem) onAddToCart;
  final bool isLoading;

  const ProductGrid({
    Key? key,
    required this.products,
    required this.onAddToCart,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF7B5CFA),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.categoryWidgetsNoProductsAvailable,
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
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
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
                  flex: 4,
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
                              onAddToCart(cartItem);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B5CFA),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor:
                                  const Color(0xFF7B5CFA).withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              l10n.categoryWidgetsAddToCart,
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
        },
      ),
    );
  }
}

class CartWidget extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(int, int) updateQuantity;
  final Function(int) removeItem; // NEW: Remove individual item
  final Function() clearCart; // NEW: Clear all items
  final Function() placeOrder;
  final bool isPlacingOrder;

  const CartWidget({
    Key? key,
    required this.cartItems,
    required this.updateQuantity,
    required this.removeItem, // NEW
    required this.clearCart, // NEW
    required this.placeOrder,
    this.isPlacingOrder = false,
  }) : super(key: key);

  @override
  State<CartWidget> createState() => _CartWidgetState();
}

class _CartWidgetState extends State<CartWidget> with TickerProviderStateMixin {
  List<TextEditingController> _quantityControllers = [];
  List<FocusNode> _focusNodes = [];
  late AnimationController _clearAllAnimationController;
  late Animation<double> _clearAllScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _clearAllAnimationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );

    _clearAllScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _clearAllAnimationController,
      curve: Curves.easeInOut,
    ));

    // Use post frame callback to avoid initState issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  @override
  void didUpdateWidget(CartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always update controllers when cart items change
    _updateControllersForCurrentItems();
  }

  void _initializeControllers() {
    _disposeControllers();
    _quantityControllers = [];
    _focusNodes = [];

    for (int i = 0; i < widget.cartItems.length; i++) {
      _quantityControllers.add(
          TextEditingController(text: widget.cartItems[i].quantity.toString()));
      _focusNodes.add(FocusNode());
    }
  }

  void _updateControllersForCurrentItems() {
    // Handle case where items were removed
    if (widget.cartItems.length < _quantityControllers.length) {
      // Remove excess controllers
      for (int i = widget.cartItems.length;
          i < _quantityControllers.length;
          i++) {
        _quantityControllers[i].dispose();
        _focusNodes[i].dispose();
      }
      _quantityControllers =
          _quantityControllers.take(widget.cartItems.length).toList();
      _focusNodes = _focusNodes.take(widget.cartItems.length).toList();
    }

    // Handle case where items were added
    while (_quantityControllers.length < widget.cartItems.length) {
      int index = _quantityControllers.length;
      _quantityControllers.add(TextEditingController(
          text: widget.cartItems[index].quantity.toString()));
      _focusNodes.add(FocusNode());
    }

    // Update existing controllers with current quantities
    for (int i = 0;
        i < widget.cartItems.length && i < _quantityControllers.length;
        i++) {
      String currentText = _quantityControllers[i].text;
      String expectedText = widget.cartItems[i].quantity.toString();

      // Only update if the text doesn't match and the field is not focused
      // This prevents overwriting while user is typing
      if (currentText != expectedText && !_focusNodes[i].hasFocus) {
        _quantityControllers[i].text = expectedText;
      }
    }
  }

  void _disposeControllers() {
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    _clearAllAnimationController.dispose();
    super.dispose();
  }

  void _onQuantityChanged(int index, String value) {
    if (value.isEmpty) return;

    final quantity = int.tryParse(value);
    if (quantity != null && quantity > 0 && quantity <= 999) {
      // Update the cart item quantity
      widget.updateQuantity(index, quantity);
    }
  }

  void _onQuantitySubmitted(int index, String value) {
    if (value.isEmpty || value == '0') {
      // Reset to current quantity if invalid
      if (index < widget.cartItems.length &&
          index < _quantityControllers.length) {
        _quantityControllers[index].text =
            widget.cartItems[index].quantity.toString();
      }
    } else {
      final quantity = int.tryParse(value);
      if (quantity != null && quantity > 0 && quantity <= 999) {
        widget.updateQuantity(index, quantity);
      } else {
        // Reset to current quantity if invalid
        _quantityControllers[index].text =
            widget.cartItems[index].quantity.toString();
      }
    }

    // Remove focus
    if (index < _focusNodes.length) {
      _focusNodes[index].unfocus();
    }
  }

  void _increaseQuantity(int index) {
    if (index < widget.cartItems.length) {
      int newQuantity = widget.cartItems[index].quantity + 1;
      widget.updateQuantity(index, newQuantity);
    }
  }

  void _decreaseQuantity(int index) {
    if (index < widget.cartItems.length) {
      int newQuantity = widget.cartItems[index].quantity - 1;
      widget.updateQuantity(index, newQuantity);
    }
  }

  // NEW: Handle clear all button with animation
  void _handleClearAll() {
    _clearAllAnimationController.forward().then((_) {
      _clearAllAnimationController.reverse();
      widget.clearCart();
    });
  }

  double getSubtotal() {
    return widget.cartItems.fold(0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF283548),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cart Header with Clear All Button
            Padding(
              padding: EdgeInsetsDirectional.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cart title and count
                  Row(
                    children: [
                      Text(
                        "Your Cart",
                        style: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                      ),
                      if (widget.cartItems.isNotEmpty) ...[
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsetsDirectional.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B5CFA),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            "${widget.cartItems.length} items",
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Clear All Button
                  if (widget.cartItems.isNotEmpty)
                    AnimatedBuilder(
                      animation: _clearAllScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _clearAllScaleAnimation.value,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _handleClearAll,
                              child: Container(
                                padding: EdgeInsetsDirectional.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_sweep_rounded,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Clear All",
                                      style: isArabic
                                          ? GoogleFonts.cairo(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            )
                                          : GoogleFonts.spaceGrotesk(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Empty Cart Message
            if (widget.cartItems.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[800]?.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Your cart is empty",
                        style: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.grey[400],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.grey[400],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add items to start shopping",
                        style: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.grey[500],
                                fontSize: 14,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                      ),
                    ],
                  ),
                ),
              ),

            // Cart Items
            if (widget.cartItems.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 20.0),
                  child: ListView.separated(
                    itemCount: widget.cartItems.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey[800],
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];

                      // Ensure controllers exist for this index
                      if (index >= _quantityControllers.length) {
                        return Container(); // Safety check
                      }

                      return Padding(
                        padding:
                            EdgeInsetsDirectional.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            // Product Image
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: item.product.image,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: const Color(0xFF7B5CFA),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Product Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          )
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "\$${item.product.sellPrice.toStringAsFixed(2)} each",
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          )
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Selector
                            Row(
                              children: [
                                // Decrease button
                                InkWell(
                                  onTap: () => _decreaseQuantity(index),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D2939),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey[700]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),

                                // Editable Quantity Field
                                Container(
                                  margin: EdgeInsetsDirectional.symmetric(
                                      horizontal: 8),
                                  width: 55,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D2939),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _focusNodes[index].hasFocus
                                          ? const Color(0xFF7B5CFA)
                                          : Colors.grey[700]!,
                                      width:
                                          _focusNodes[index].hasFocus ? 2 : 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _quantityControllers[index],
                                    focusNode: _focusNodes[index],
                                    textAlign: TextAlign.center,
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
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsetsDirectional.symmetric(
                                              vertical: 8),
                                      isDense: true,
                                    ),
                                    onChanged: (value) =>
                                        _onQuantityChanged(index, value),
                                    onSubmitted: (value) =>
                                        _onQuantitySubmitted(index, value),
                                    onTap: () {
                                      // Select all text when tapped
                                      _quantityControllers[index].selection =
                                          TextSelection(
                                        baseOffset: 0,
                                        extentOffset:
                                            _quantityControllers[index]
                                                .text
                                                .length,
                                      );
                                    },
                                  ),
                                ),

                                // Increase button
                                InkWell(
                                  onTap: () => _increaseQuantity(index),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D2939),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey[700]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Item Total and Remove Button
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Total price
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "\$${item.total.toStringAsFixed(2)}",
                                        style: isArabic
                                            ? GoogleFonts.cairo(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              )
                                            : GoogleFonts.spaceGrotesk(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                        textAlign: TextAlign.right,
                                      ),
                                      Text(
                                        "x${item.quantity}",
                                        style: isArabic
                                            ? GoogleFonts.cairo(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              )
                                            : GoogleFonts.spaceGrotesk(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 8),

                                  // Individual Remove Button
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => widget.removeItem(index),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Cart Summary
            if (widget.cartItems.isNotEmpty)
              Container(
                padding: EdgeInsetsDirectional.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D2939),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Subtotal info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Subtotal (${widget.cartItems.fold(0, (sum, item) => sum + item.quantity)} items)",
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
                        Text(
                          "\$${getSubtotal().toStringAsFixed(2)}",
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
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                        Text(
                          "\$${getSubtotal().toStringAsFixed(2)}",
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Place Order Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            widget.isPlacingOrder ? null : widget.placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B5CFA),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(0xFF7B5CFA).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding:
                              EdgeInsetsDirectional.symmetric(vertical: 12),
                        ),
                        child: widget.isPlacingOrder
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                "Place Order",
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
}
