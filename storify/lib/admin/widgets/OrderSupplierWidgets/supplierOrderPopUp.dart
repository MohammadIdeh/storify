import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SupplierOrderPopup extends StatefulWidget {
  const SupplierOrderPopup({super.key});

  @override
  State<SupplierOrderPopup> createState() => _SupplierOrderPopupState();
}

class _SupplierOrderPopupState extends State<SupplierOrderPopup> {
  // Selected supplier
  String? _selectedSupplier;

  // Selected product
  ProductItem? _selectedProduct;

  // Cart items
  final List<CartItem> _cartItems = [];

  // Quantity for the selected product
  int _quantity = 1;

  // List of suppliers (will come from API)
  final List<String> _suppliers = [
    'Ralph Edwards Supplies',
    'Mohammad Trading Co.',
    'Global Distributors Ltd.',
    'Quality Essentials Inc.',
    'Premium Merchant Supply'
  ];

  // Fake products per supplier (will come from API)
  final Map<String, List<ProductItem>> _productsMap = {
    'Ralph Edwards Supplies': [
      ProductItem(
        id: '1',
        name: 'Premium Coffee Beans',
        description: 'High-quality Arabica coffee beans, 500g bag',
        price: 15.99,
        image: 'assets/images/product1.png',
        stock: 24,
        lowPriceSupplier: 'Mohammad Trading Co.',
        lowPrice: 14.50,
      ),
      ProductItem(
        id: '2',
        name: 'Organic Tea Selection',
        description: 'Assorted organic teas, 50 tea bags',
        price: 8.99,
        image: 'assets/images/product2.png',
        stock: 36,
      ),
      ProductItem(
        id: '3',
        name: 'Chocolate Cookies',
        description: 'Premium chocolate cookies, 250g package',
        price: 4.99,
        image: 'assets/images/product3.png',
        stock: 48,
      ),
      ProductItem(
        id: '4',
        name: 'Sparkling Water',
        description: 'Carbonated natural spring water, 12x500ml',
        price: 9.99,
        image: 'assets/images/product4.png',
        stock: 30,
      ),
      ProductItem(
        id: '5',
        name: 'Honey Jar',
        description: 'Pure organic honey, 500g jar',
        price: 7.50,
        image: 'assets/images/product5.png',
        stock: 20,
        lowPriceSupplier: 'Global Distributors Ltd.',
        lowPrice: 6.99,
      ),
    ],
    'Mohammad Trading Co.': [
      ProductItem(
        id: '6',
        name: 'Premium Coffee Beans',
        description: 'High-quality Arabica coffee beans, 500g bag',
        price: 14.50,
        image: 'assets/images/product1.png',
        stock: 32,
      ),
      ProductItem(
        id: '7',
        name: 'Pistachio Nuts',
        description: 'Roasted and salted pistachios, 200g bag',
        price: 11.99,
        image: 'assets/images/product6.png',
        stock: 15,
      ),
      ProductItem(
        id: '8',
        name: 'Cashew Nuts',
        description: 'Premium cashew nuts, 300g package',
        price: 12.99,
        image: 'assets/images/product7.png',
        stock: 25,
      ),
    ],
    'Global Distributors Ltd.': [
      ProductItem(
        id: '9',
        name: 'Honey Jar',
        description: 'Pure organic honey, 500g jar',
        price: 6.99,
        image: 'assets/images/product5.png',
        stock: 40,
      ),
      ProductItem(
        id: '10',
        name: 'Olive Oil',
        description: 'Extra virgin olive oil, 750ml bottle',
        price: 16.50,
        image: 'assets/images/product8.png',
        stock: 18,
      ),
    ],
    'Quality Essentials Inc.': [
      ProductItem(
        id: '11',
        name: 'Almond Milk',
        description: 'Unsweetened almond milk, 1L carton',
        price: 3.99,
        image: 'assets/images/product9.png',
        stock: 50,
      ),
      ProductItem(
        id: '12',
        name: 'Mixed Nuts',
        description: 'Assorted premium nuts, 400g container',
        price: 15.99,
        image: 'assets/images/product10.png',
        stock: 22,
      ),
    ],
    'Premium Merchant Supply': [
      ProductItem(
        id: '13',
        name: 'Dark Chocolate',
        description: '70% cacao dark chocolate, 100g bar',
        price: 4.50,
        image: 'assets/images/product11.png',
        stock: 60,
      ),
      ProductItem(
        id: '14',
        name: 'Dried Apricots',
        description: 'Sun-dried organic apricots, 250g package',
        price: 7.25,
        image: 'assets/images/product12.png',
        stock: 28,
      ),
      ProductItem(
        id: '15',
        name: 'Granola Mix',
        description: 'Artisanal granola with nuts and berries, 350g',
        price: 8.75,
        image: 'assets/images/product13.png',
        stock: 35,
      ),
    ],
  };

  // Get the list of products for the selected supplier
  List<ProductItem> get _productsList {
    if (_selectedSupplier == null) {
      return [];
    }
    return _productsMap[_selectedSupplier!] ?? [];
  }

  // Calculate the total price of the cart
  double get _cartTotal {
    return _cartItems.fold(
        0, (total, item) => total + (item.price * item.quantity));
  }

  // Select a product
  void _selectProduct(ProductItem product) {
    setState(() {
      _selectedProduct = product;
      _quantity = 1; // Reset quantity when selecting a new product
    });
  }

  // Add product to cart
  void _addToCart() {
    if (_selectedProduct != null && _quantity > 0) {
      setState(() {
        // Check if product already exists in cart
        final existingItemIndex =
            _cartItems.indexWhere((item) => item.id == _selectedProduct!.id);

        if (existingItemIndex >= 0) {
          // Update quantity if product already in cart
          _cartItems[existingItemIndex] = _cartItems[existingItemIndex]
              .copyWith(
                  quantity: _cartItems[existingItemIndex].quantity + _quantity);
        } else {
          // Add new item to cart
          _cartItems.add(CartItem(
            id: _selectedProduct!.id,
            name: _selectedProduct!.name,
            price: _selectedProduct!.price,
            quantity: _quantity,
            image: _selectedProduct!.image,
          ));
        }

        // Reset quantity
        _quantity = 1;
      });
    }
  }

  // Remove item from cart
  void _removeFromCart(String id) {
    setState(() {
      _cartItems.removeWhere((item) => item.id == id);
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

  // Place the order
  void _placeOrder() {
    if (_cartItems.isNotEmpty) {
      // Here you would send the order to your API
      // For now, we'll just close the dialog and show a confirmation
      Navigator.of(context).pop(_cartItems);
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
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
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
                                items: _suppliers.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedSupplier = newValue;
                                    _selectedProduct =
                                        null; // Clear selected product
                                  });
                                },
                              ),
                            ),
                          ),

                          SizedBox(height: 30.h),

                          // Cart
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
                                        '(${_cartItems.length} items)',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 14.sp,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 16.h),

                                  // Cart items
                                  Expanded(
                                    child: _cartItems.isEmpty
                                        ? _buildEmptyState(
                                            icon:
                                                'assets/images/empty_cart.svg',
                                            message: 'Your cart is empty',
                                            description:
                                                'Add products from the list to place an order',
                                            placeholderIcon:
                                                Icons.shopping_cart_outlined,
                                          )
                                        : ListView.separated(
                                            itemCount: _cartItems.length,
                                            separatorBuilder:
                                                (context, index) => Divider(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              height: 20.h,
                                            ),
                                            itemBuilder: (context, index) {
                                              final item = _cartItems[index];
                                              return Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  // Product image
                                                  Container(
                                                    width: 50.w,
                                                    height: 50.h,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.r),
                                                    ),
                                                    child: Center(
                                                      child: Image.asset(
                                                        item.image,
                                                        width: 40.w,
                                                        height: 40.h,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return Icon(
                                                            Icons.image,
                                                            size: 24.sp,
                                                            color:
                                                                Colors.white70,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),

                                                  SizedBox(width: 12.w),

                                                  // Product details
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item.name,
                                                          style: GoogleFonts
                                                              .spaceGrotesk(
                                                            fontSize: 16.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        SizedBox(height: 4.h),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              '${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                                                              style: GoogleFonts
                                                                  .spaceGrotesk(
                                                                fontSize: 14.sp,
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                            ),
                                                            const Spacer(),
                                                            Text(
                                                              '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                                              style: GoogleFonts
                                                                  .spaceGrotesk(
                                                                fontSize: 16.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .white,
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
                                                      size: 20.sp,
                                                    ),
                                                    onPressed: () =>
                                                        _removeFromCart(
                                                            item.id),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                  ),

                                  // Cart summary and confirm button
                                  if (_cartItems.isNotEmpty) ...[
                                    Divider(
                                      color: Colors.white.withOpacity(0.1),
                                      height: 24.h,
                                    ),

                                    // Total
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '\$${_cartTotal.toStringAsFixed(2)}',
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

                                    // Confirm button
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
                                        onPressed: _placeOrder,
                                        child: Text(
                                          'Confirm Order',
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
                            'Products ${_selectedSupplier != null ? "(${_productsList.length})" : ""}',
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
                            child: _selectedSupplier == null
                                ? _buildEmptyState(
                                    icon: 'assets/images/choose_supplier.svg',
                                    message: 'No products to display',
                                    description:
                                        'Please select a supplier first',
                                    placeholderIcon: Icons.inventory_2_outlined,
                                  )
                                : _productsList.isEmpty
                                    ? _buildEmptyState(
                                        icon: 'assets/images/no_products.svg',
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
                                        itemCount: _productsList.length,
                                        itemBuilder: (context, index) {
                                          final product = _productsList[index];
                                          final isSelected =
                                              _selectedProduct?.id ==
                                                  product.id;

                                          return GestureDetector(
                                            onTap: () =>
                                                _selectProduct(product),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? const Color.fromARGB(
                                                            255, 105, 65, 198)
                                                        .withOpacity(0.2)
                                                    : Colors.white
                                                        .withOpacity(0.05),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? const Color.fromARGB(
                                                          255, 105, 65, 198)
                                                      : Colors.transparent,
                                                  width: 1.5,
                                                ),
                                              ),
                                              padding: EdgeInsets.all(12.w),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // Product image
                                                  Expanded(
                                                    child: Image.asset(
                                                      product.image,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Icon(
                                                          Icons.image,
                                                          size: 40.sp,
                                                          color: Colors.white70,
                                                        );
                                                      },
                                                    ),
                                                  ),

                                                  SizedBox(height: 8.h),

                                                  // Product name
                                                  Text(
                                                    product.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
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
                                                    '\$${product.price.toStringAsFixed(2)}',
                                                    style: GoogleFonts
                                                        .spaceGrotesk(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              105,
                                                              65,
                                                              198),
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
                                          child: Image.asset(
                                            _selectedProduct!.image,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.image,
                                                size: 60.sp,
                                                color: Colors.white70,
                                              );
                                            },
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
                                                    '\$${_selectedProduct!.price.toStringAsFixed(2)}',
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
                                                      'In Stock: ${_selectedProduct!.stock}',
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
                                                _selectedProduct!.description,
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 14.sp,
                                                  color: Colors.white70,
                                                ),
                                              ),

                                              SizedBox(height: 16.h),

                                              // Better price indicator
                                              if (_selectedProduct!
                                                      .lowPriceSupplier !=
                                                  null) ...[
                                                Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.all(10.w),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                            255, 255, 232, 29)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.r),
                                                    border: Border.all(
                                                      color:
                                                          const Color.fromARGB(
                                                                  255,
                                                                  255,
                                                                  232,
                                                                  29)
                                                              .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.info_outline,
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 255, 232, 29),
                                                        size: 18.sp,
                                                      ),
                                                      SizedBox(width: 8.w),
                                                      Expanded(
                                                        child: Text(
                                                          'This product is available for \$${_selectedProduct!.lowPrice!.toStringAsFixed(2)} from ${_selectedProduct!.lowPriceSupplier}',
                                                          style: GoogleFonts
                                                              .spaceGrotesk(
                                                            fontSize: 14.sp,
                                                            color: const Color
                                                                .fromARGB(255,
                                                                255, 232, 29),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 16.h),
                                              ],

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
                                                        color: Color.fromARGB(
                                                            255, 255, 255, 255),
                                                        Icons.add_shopping_cart,
                                                        size: 18.sp,
                                                      ),
                                                      label: Text(
                                                        'Add to Cart',
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Color.fromARGB(
                                                              255,
                                                              255,
                                                              255,
                                                              255),
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
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

// Model for product
class ProductItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final int stock;
  final String? lowPriceSupplier;
  final double? lowPrice;

  ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.stock,
    this.lowPriceSupplier,
    this.lowPrice,
  });
}

// Model for cart item
class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String image;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
  });

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? image,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
    );
  }
}

// Helper method to show the popup
void showSupplierOrderPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const SupplierOrderPopup();
    },
  );
}
