// lib/customer/screens/customer_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/customer/screens/historyScreenCustomer.dart';
import 'package:storify/customer/widgets/CustomerOrderService.dart';
import 'package:storify/customer/widgets/modelCustomer.dart'
    show CartItem, Category, Order, Product;
import 'package:storify/customer/widgets/navbarCus.dart';
import 'package:storify/customer/widgets/uiWidgets.dart';

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
    _loadProfilePicture();
    _loadData();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  Future<void> _loadData() async {
    await _loadCategories();
    if (_categories.isNotEmpty) {
      await _loadProductsByCategory(_categories[0].id);
      setState(() {
        _selectedCategoryId = _categories[0].id.toString();
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await CustomerOrderService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      _showErrorSnackbar("Failed to load categories: $e");
    }
  }

  Future<void> _loadProductsByCategory(int categoryId) async {
    setState(() {
      _isLoadingProducts = true;
      _products = [];
    });

    try {
      final products =
          await CustomerOrderService.getProductsByCategory(categoryId);
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      _showErrorSnackbar("Failed to load products: $e");
    }
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HistoryScreenCustomer(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.product.name} added to cart'),
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
    if (_cartItems.isEmpty) {
      _showErrorSnackbar("Your cart is empty");
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isPlacingOrder = false;
      });

      // Handle insufficient stock exception
      if (e is InsufficientStockException) {
        _showStockLimitDialog(e);
      } else {
        _showErrorSnackbar("Failed to place order: $e");
      }
    }
  }

  void _showStockLimitDialog(InsufficientStockException exception) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF283548),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Insufficient Stock",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Product: ${exception.productName}",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Available: ${exception.available}",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              Text(
                "Requested: ${exception.requested}",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Would you like to update the quantity to the maximum available?",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.white,
                ),
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
              child: const Text("Update Quantity"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Search
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
    return Scaffold(
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // New Order Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "New Order",
                        style: TextStyle(
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
                        tooltip: "Refresh",
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search products",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Categories section - Now at top horizontally
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Categories",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Categories list - Horizontal scrolling
                      _isLoadingCategories
                          ? Center(
                              child: CircularProgressIndicator(
                                color: const Color(0xFF7B5CFA),
                              ),
                            )
                          : SizedBox(
                              height: 120,
                              child: CategoryList(
                                categories: _categories,
                                selectedCategoryId: _selectedCategoryId,
                                onCategorySelected: _selectCategory,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Products section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Products",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_products.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF283548),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${_getFilteredProducts().length} items",
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Products grid
                        Expanded(
                          child: ProductGrid(
                            products: _getFilteredProducts(),
                            onAddToCart: _addToCart,
                            isLoading: _isLoadingProducts,
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
              padding:
                  const EdgeInsets.only(top: 24.0, right: 24.0, bottom: 24.0),
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
    );
  }
}
