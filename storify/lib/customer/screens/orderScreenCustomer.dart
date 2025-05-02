// lib/Customer/widgets/CustomerOrders.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/customer/screens/historyScreenCustomer.dart';
import 'package:storify/customer/widgets/navbarCus.dart';

// Models
class FoodCategory {
  final String name;
  final String image;

  FoodCategory({required this.name, required this.image});
}

class FoodItem {
  final String name;
  final double price;
  final String image;
  final String category;
  final String? size;
  final String? description;

  FoodItem(
      {required this.name,
      required this.price,
      required this.image,
      required this.category,
      this.size,
      this.description});
}

class CartItem {
  final FoodItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get total => item.price * quantity;
}

class Order {
  final String id;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String deliveryTime;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double serviceCharge;
  final double vat;
  final double grandTotal;
  final double amountPaid;
  final double changeDue;
  final String paymentMethod;
  final String status;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;

  Order({
    required this.id,
    required this.orderDate,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.vat,
    required this.grandTotal,
    required this.amountPaid,
    required this.changeDue,
    required this.paymentMethod,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerAddress,
  });
}

class CustomerOrders extends StatefulWidget {
  const CustomerOrders({super.key});

  @override
  State<CustomerOrders> createState() => _CustomerOrdersState();
}

class _CustomerOrdersState extends State<CustomerOrders> {
  int _currentIndex = 0;
  String? profilePictureUrl;
  String _searchQuery = "";

  // Selected category
  String _selectedCategory = "All";

  // Date and time selection
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isPM = true;

  // Orders state
  List<CartItem> _cartItems = [];
  double _customerPaidAmount = 150.0;
  String _paymentMethod = "Cash";

  // Fake data
  List<FoodCategory> _categories = [
    FoodCategory(name: "Vegetables", image: "assets/icons/vegetables.png"),
    FoodCategory(name: "Fresh Fruits", image: "assets/icons/fruits.png"),
    FoodCategory(name: "Milk & Dairy", image: "assets/icons/milk.png"),
    FoodCategory(name: "Meat & Fish", image: "assets/icons/meat.png"),
    FoodCategory(name: "Snacks", image: "assets/icons/snacks.png"),
    FoodCategory(name: "Beverage", image: "assets/icons/beverage.png"),
  ];

  List<FoodItem> _foodItems = [
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),
    FoodItem(
        name: "Tomato",
        price: 16.00,
        image: "assets/images/tomato.png",
        category: "Vegetables"),

    // Add preloaded cart items for demo
    FoodItem(
        name: "Chicken Dumplings",
        price: 10.0,
        image: "assets/images/chicken_dumplings.png",
        category: "Snacks",
        size: "Large",
        description: "Extra, Onion, Sauce"),
    FoodItem(
        name: "Tuna Salad",
        price: 35.0,
        image: "assets/images/tuna_salad.png",
        category: "Snacks",
        size: "1:1"),
    FoodItem(
        name: "Cheese Burger",
        price: 15.0,
        image: "assets/images/burger.png",
        category: "Snacks",
        size: "Small"),
    FoodItem(
        name: "Hot & Sour Soup",
        price: 50.80,
        image: "assets/images/soup.png",
        category: "Snacks",
        size: "4:3"),
    FoodItem(
        name: "Steak Sandwich",
        price: 8.0,
        image: "assets/images/sandwich.png",
        category: "Snacks",
        size: "Medium"),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _preloadCartItems();
  }

  void _preloadCartItems() {
    // Preload cart with demo items
    final demoItems = _foodItems
        .where((item) => [
              "Chicken Dumplings",
              "Tuna Salad",
              "Cheese Burger",
              "Hot & Sour Soup",
              "Steak Sandwich"
            ].contains(item.name))
        .toList();

    setState(() {
      _cartItems = [
        CartItem(item: demoItems[0], quantity: 1),
        CartItem(item: demoItems[1], quantity: 1),
        CartItem(item: demoItems[2], quantity: 2),
        CartItem(item: demoItems[3], quantity: 1),
        CartItem(item: demoItems[4], quantity: 3),
      ];
    });
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
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

  void _addToCart(FoodItem item) {
    setState(() {
      // Check if item already exists in cart
      int existingIndex =
          _cartItems.indexWhere((cartItem) => cartItem.item.name == item.name);

      if (existingIndex != -1) {
        // If exists, increase quantity
        _cartItems[existingIndex].quantity++;
      } else {
        // If not exists, add new item
        _cartItems.add(CartItem(item: item, quantity: 1));
      }
    });
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

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _placeOrder() {
    // Create a new order with current data
    final order = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      orderDate: DateTime.now(),
      deliveryDate: _selectedDate,
      deliveryTime: _isPM
          ? '${_selectedTime.format(context)} PM'
          : '${_selectedTime.format(context)} AM',
      items: List.from(_cartItems),
      subtotal: _getSubtotal(),
      discount: _getDiscount(),
      serviceCharge: 0.0,
      vat: 0.0,
      grandTotal: _getGrandTotal(),
      amountPaid: _customerPaidAmount,
      changeDue: _customerPaidAmount - _getGrandTotal(),
      paymentMethod: _paymentMethod,
      status: "Placed",
      customerName: "Alex Rose",
      customerPhone: "+1 (555) 000-0000",
      customerEmail: "rosealex@gmail.com",
      customerAddress: "11h Burma, Uttara 19, Dhaka-1230",
    );

    // Save order to history (Would be API call in real app)
    // For now we'll just show a success message and reset cart

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Order placed successfully! Order ID: ${order.id}')),
    );

    // Reset cart and create new order
    setState(() {
      _cartItems = [];
      _customerPaidAmount = 0.0;
    });
  }

  double _getSubtotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.total);
  }

  double _getDiscount() {
    return _getSubtotal() * 0.1; // 10% discount
  }

  double _getGrandTotal() {
    return _getSubtotal() - _getDiscount();
  }

  List<FoodItem> _getFilteredItems() {
    if (_selectedCategory == "All") {
      return _foodItems;
    }

    return _foodItems
        .where((item) =>
            item.category == _selectedCategory &&
            ![
              "Chicken Dumplings",
              "Tuna Salad",
              "Cheese Burger",
              "Hot & Sour Soup",
              "Steak Sandwich"
            ].contains(item.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(250),
        child: NavigationBarCustomer(
          currentIndex: _currentIndex,
          onTap: _onNavItemTap,
          profilePictureUrl: profilePictureUrl,
        ),
      ),
      body: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Items and categories
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF283548),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Search Item",
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Item Categories
                    const Text(
                      "Item Category",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Category icons
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return GestureDetector(
                            onTap: () => _selectCategory(category.name),
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 15),
                              child: Column(
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF283548),
                                      borderRadius: BorderRadius.circular(15),
                                      border: _selectedCategory == category.name
                                          ? Border.all(
                                              color: const Color(0xFF7B5CFA),
                                              width: 2)
                                          : null,
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        "assets/icons/vegetables.png", // Using a placeholder since actual assets might differ
                                        height: 30,
                                        color:
                                            _selectedCategory == category.name
                                                ? const Color(0xFF7B5CFA)
                                                : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      color: _selectedCategory == category.name
                                          ? const Color(0xFF7B5CFA)
                                          : Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Products grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: _getFilteredItems().length,
                      itemBuilder: (context, index) {
                        final item = _getFilteredItems()[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF283548),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Image.asset(
                                    "assets/images/tomato.png", // Using a placeholder since actual assets might differ
                                    height: 80,
                                  ),
                                ),
                              ),
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "\$${item.price.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0),
                                child: ElevatedButton.icon(
                                  onPressed: () => _addToCart(item),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text("Add"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7B5CFA),
                                    foregroundColor: Colors.white,
                                    minimumSize:
                                        const Size(double.infinity, 30),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Right side - Order details and checkout
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0, top: 75),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    color: Color(0xFF283548),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Delivery Date Section
                          ExpansionTile(
                            title: const Text(
                              "Delivery Date",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            iconColor: Colors.white,
                            collapsedIconColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            collapsedBackgroundColor: Colors.transparent,
                            children: [
                              // Date Calendar
                              Container(
                                height: 280,
                                color: const Color(0xFF283548),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left,
                                              color: Colors.white),
                                          onPressed: () {
                                            // Previous month logic
                                          },
                                        ),
                                        Text(
                                          "April 2023",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right,
                                              color: Colors.white),
                                          onPressed: () {
                                            // Next month logic
                                          },
                                        ),
                                      ],
                                    ),

                                    // Days of week
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          "Sun",
                                          "Mon",
                                          "Tue",
                                          "Wed",
                                          "Thu",
                                          "Fri",
                                          "Sat"
                                        ]
                                            .map((day) => Text(
                                                  day,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),

                                    // Calendar grid (simplified)
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        childAspectRatio: 1.2,
                                      ),
                                      itemCount: 30, // Simplified
                                      itemBuilder: (context, index) {
                                        final day = index + 1;
                                        final isSelected =
                                            day == 15; // Example selected day
                                        return GestureDetector(
                                          onTap: () {
                                            // Select date logic
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF7B5CFA)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "$day",
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.grey,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
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
                            ],
                          ),

                          const Divider(color: Color(0xFF222E41)),

                          // Delivery Time Section
                          ExpansionTile(
                            title: const Text(
                              "Delivery Time",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            iconColor: Colors.white,
                            collapsedIconColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            collapsedBackgroundColor: Colors.transparent,
                            initiallyExpanded: false,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    // Time selector (simplified)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Hour
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "06",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          " : ",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        // Minute
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "27",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          " : ",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        // Second
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "54",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    // AM/PM selector
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "06",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "28",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          ":",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "55",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 15),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Text(
                                            "PM",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    // AM selector
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "06",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "27",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          ":",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "54",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 15),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Text(
                                            "AM",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
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

                          const Divider(color: Color(0xFF222E41)),

                          // Cart items
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Item",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "Price",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "Qty",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "Total",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Cart items list
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _cartItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 15),
                            itemBuilder: (context, index) {
                              final cartItem = _cartItems[index];
                              return Row(
                                children: [
                                  // Color indicator
                                  Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B5CFA),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Item details
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cartItem.item.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (cartItem.item.description != null)
                                          Text(
                                            cartItem.item.description!,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                            ),
                                          ),
                                        if (cartItem.item.size != null)
                                          Text(
                                            "Size: ${cartItem.item.size}",
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Price
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "\$${cartItem.item.price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                  // Quantity
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () => _updateCartItemQuantity(
                                              index, cartItem.quantity - 1),
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D2939),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: const Icon(
                                              Icons.remove,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D2939),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            "${cartItem.quantity}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _updateCartItemQuantity(
                                              index, cartItem.quantity + 1),
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D2939),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Total
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "\$${cartItem.total.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFF222E41)),
                          const SizedBox(height: 10),

                          // Order summary
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Subtotal",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "\$${_getSubtotal().toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Discount(10%)",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "\$${_getDiscount().toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Service Charge(0%)",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                "\$0.00",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Vat (%)",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                "\$0.00",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: Color(0xFF222E41)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Grand total",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "\$${_getGrandTotal().toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Customer paid amount",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "\$${_customerPaidAmount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Change due",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "\$${(_customerPaidAmount - _getGrandTotal()).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Payment method
                          const Text(
                            "Payment Method",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              // Cash option
                              Row(
                                children: [
                                  Radio(
                                    value: "Cash",
                                    groupValue: _paymentMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        _paymentMethod = value.toString();
                                      });
                                    },
                                    activeColor: Colors.white,
                                    fillColor:
                                        MaterialStateProperty.all(Colors.white),
                                  ),
                                  const Text(
                                    "Cash",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              // Card option
                              Row(
                                children: [
                                  Radio(
                                    value: "Card",
                                    groupValue: _paymentMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        _paymentMethod = value.toString();
                                      });
                                    },
                                    activeColor: Colors.white,
                                    fillColor:
                                        MaterialStateProperty.all(Colors.white),
                                  ),
                                  const Text(
                                    "Card",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // Cancel order
                                  setState(() {
                                    _cartItems = [];
                                  });
                                },
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 15),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _placeOrder,
                                child: const Text("Place Order"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7B5CFA),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 15),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
