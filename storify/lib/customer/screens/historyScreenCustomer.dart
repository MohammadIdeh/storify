// lib/customer/screens/historyScreenCustomer.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/customer/screens/orderScreenCustomer.dart';
import 'package:storify/customer/widgets/navbarCus.dart';
import 'package:intl/intl.dart';

// Import models from CustomerOrders.dart (in a real app these would be in separate files)
// Using the same models as defined in CustomerOrders.dart

class HistoryScreenCustomer extends StatefulWidget {
  const HistoryScreenCustomer({super.key});

  @override
  State<HistoryScreenCustomer> createState() => _HistoryScreenCustomerState();
}

class _HistoryScreenCustomerState extends State<HistoryScreenCustomer> {
  int _currentIndex = 1;
  String? profilePictureUrl;
  String _searchQuery = "";

  // Selected order for details view
  Order? _selectedOrder;

  // Fake orders data
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _loadFakeOrders();
  }

  void _loadFakeOrders() {
    // Create some fake orders for demonstration
    setState(() {
      _orders = [
        _createFakeOrder("ORD-6504267", DateTime(2023, 2, 15),
            DateTime(2023, 2, 15), "9:30 PM", "Delivered", "Paid", "Cash"),
        _createFakeOrder("ORD-6504266", DateTime(2023, 2, 10),
            DateTime(2023, 2, 10), "7:45 PM", "Delivered", "Paid", "Card"),
        _createFakeOrder("ORD-6504265", DateTime(2023, 2, 5),
            DateTime(2023, 2, 5), "6:15 PM", "Delivered", "Paid", "Cash"),
        _createFakeOrder("ORD-6504264", DateTime(2023, 1, 28),
            DateTime(2023, 1, 28), "8:00 PM", "Delivered", "Paid", "Card"),
      ];

      // Set the first order as selected by default
      if (_orders.isNotEmpty) {
        _selectedOrder = _orders[0];
      }
    });
  }

  Order _createFakeOrder(
      String id,
      DateTime orderDate,
      DateTime deliveryDate,
      String deliveryTime,
      String status,
      String paymentStatus,
      String paymentMethod) {
    // Create fake cart items
    List<CartItem> items = [
      CartItem(
          item: FoodItem(
              name: "Chicken Dumplings",
              price: 10.0,
              image: "assets/images/chicken_dumplings.png",
              category: "Snacks",
              size: "Large",
              description: "Extra, Onion, Sauce"),
          quantity: 1),
      CartItem(
          item: FoodItem(
              name: "Tuna Salad",
              price: 35.0,
              image: "assets/images/tuna_salad.png",
              category: "Snacks",
              size: "1:1"),
          quantity: 1),
      CartItem(
          item: FoodItem(
              name: "Cheese Burger",
              price: 15.0,
              image: "assets/images/burger.png",
              category: "Snacks",
              size: "Small"),
          quantity: 2),
      CartItem(
          item: FoodItem(
              name: "Hot & Sour Soup",
              price: 50.80,
              image: "assets/images/soup.png",
              category: "Snacks",
              size: "4:3"),
          quantity: 1),
      CartItem(
          item: FoodItem(
              name: "Steak Sandwich",
              price: 8.0,
              image: "assets/images/sandwich.png",
              category: "Snacks",
              size: "Medium"),
          quantity: 3),
    ];

    double subtotal = items.fold(0, (sum, item) => sum + item.total);
    double discount = subtotal * 0.1; // 10% discount
    double grandTotal = subtotal - discount;

    return Order(
      id: id,
      orderDate: orderDate,
      deliveryDate: deliveryDate,
      deliveryTime: deliveryTime,
      items: items,
      subtotal: subtotal,
      discount: discount,
      serviceCharge: 0.0,
      vat: 0.0,
      grandTotal: grandTotal,
      amountPaid: 150.0,
      changeDue: 150.0 - grandTotal,
      paymentMethod: paymentMethod,
      status: status,
      customerName: "Alex Rose",
      customerPhone: "+1 (555) 000-0000",
      customerEmail: "rosealex@gmail.com",
      customerAddress: "11h Burma, Uttara 19, Dhaka-1230",
    );
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
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CustomerOrders(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 1:
        break;
    }
  }

  void _selectOrder(Order order) {
    setState(() {
      _selectedOrder = order;
    });
  }

  String _formatDate(DateTime date) {
    return "${date.day} ${DateFormat('MMM').format(date)}, ${date.year}";
  }

  Widget _buildOrderStatusBadge(String status) {
    Color badgeColor;

    switch (status.toLowerCase()) {
      case "delivered":
        badgeColor = Colors.green;
        break;
      case "pending":
        badgeColor = Colors.orange;
        break;
      case "cancelled":
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: status.toLowerCase() == "paid" ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBadge(String method) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        method,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
            // Left side - Order History List
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order History",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                          hintText: "Search Orders",
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Orders list
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return GestureDetector(
                          onTap: () => _selectOrder(order),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _selectedOrder?.id == order.id
                                  ? const Color(0xFF7B5CFA).withOpacity(0.2)
                                  : const Color(0xFF283548),
                              borderRadius: BorderRadius.circular(10),
                              border: _selectedOrder?.id == order.id
                                  ? Border.all(
                                      color: const Color(0xFF7B5CFA), width: 1)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                // Order header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Order #${order.id}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Date: ${_formatDate(order.orderDate)}",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "\$${order.grandTotal.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),

                                // Order details
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${order.items.length} items",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Delivery: ${_formatDate(order.deliveryDate)} at ${order.deliveryTime}",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildOrderStatusBadge(order.status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Right side - Order Details
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 70.0, right: 20),
                child: Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF222E41),
                      borderRadius: BorderRadius.all(Radius.circular(20))),

                  height: MediaQuery.of(context).size.height -
                      280, // Adjust height to match screen
                  child: _selectedOrder != null
                      ? SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order Details Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Order Details",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.print),
                                      label: const Text("Print Invoice"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF7B5CFA),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // Order items table
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF283548),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      // Table header
                                      Row(
                                        children: [
                                          const SizedBox(
                                            width: 40,
                                            child: Text(
                                              "SL",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: const Text(
                                                "Item",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: const Text(
                                                "Size",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: const Text(
                                                "Unit Price",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: const Text(
                                                "Quantity",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              alignment: Alignment.centerRight,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: const Text(
                                                "Total Price",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Table rows
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _selectedOrder!.items.length,
                                        separatorBuilder: (context, index) =>
                                            const Divider(
                                          color: Color(0xFF222E41),
                                          height: 1,
                                        ),
                                        itemBuilder: (context, index) {
                                          final item =
                                              _selectedOrder!.items[index];
                                          return Row(
                                            children: [
                                              // Serial number
                                              SizedBox(
                                                width: 40,
                                                child: Text(
                                                  "${index + 1}",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),

                                              // Item with image
                                              Expanded(
                                                flex: 3,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                  child: Row(
                                                    children: [
                                                      // Item image
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Icon(
                                                          Icons.fastfood,
                                                          color: Colors.white
                                                              .withOpacity(0.7),
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),

                                                      // Item details
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              item.item.name,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            if (item.item
                                                                    .description !=
                                                                null)
                                                              Text(
                                                                item.item
                                                                    .description!,
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      400],
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              // Size
                                              Expanded(
                                                flex: 1,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                  child: Text(
                                                    item.item.size ?? "-",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Unit Price
                                              Expanded(
                                                flex: 1,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                  child: Text(
                                                    "\$${item.item.price.toStringAsFixed(2)}",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Quantity
                                              Expanded(
                                                flex: 1,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                  child: Text(
                                                    "${item.quantity}",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Total Price
                                              Expanded(
                                                flex: 1,
                                                child: Container(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                  child: Text(
                                                    "\$${item.total.toStringAsFixed(2)}",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),

                                      // Order summary
                                      const Divider(
                                          color: Color(0xFF222E41),
                                          thickness: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Container(),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "Subtotal",
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "\$${_selectedOrder!.subtotal.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Container(),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "Discount(10%)",
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "\$${_selectedOrder!.discount.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Container(),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "Service Charge(0%)",
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "\$${_selectedOrder!.serviceCharge.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Container(),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "Vat (%)",
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "\$${_selectedOrder!.vat.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(
                                          color: Color(0xFF222E41),
                                          thickness: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Container(),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "Grand total",
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "\$${_selectedOrder!.grandTotal.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Container(),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "Customer paid amount",
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "\$${_selectedOrder!.amountPaid.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Container(),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "Change due",
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "\$${_selectedOrder!.changeDue.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Order Info and Customer Info sections
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Order Info
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF283548),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Order Info",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 20),

                                            // Order No
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    "Order No:",
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    _selectedOrder!.id,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),

                                            // Order Date
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    "Order Date:",
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    _formatDate(_selectedOrder!
                                                        .orderDate),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),

                                            // Delivery Date
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    "Delivery Date:",
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    _formatDate(_selectedOrder!
                                                        .deliveryDate),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),

                                            // Delivery Time
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    "Delivery Time:",
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    _selectedOrder!
                                                        .deliveryTime,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),

                                            // Order Status
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    "Order Status:",
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child:
                                                        _buildOrderStatusBadge(
                                                            _selectedOrder!
                                                                .status),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),

                                            // Payment Status
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    "Payment Status:",
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child:
                                                        _buildPaymentStatusBadge(
                                                            "Paid"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),

                                            // Payment Method
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    "Payment Method:",
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child:
                                                        _buildPaymentMethodBadge(
                                                            _selectedOrder!
                                                                .paymentMethod),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),

                                    // Customer Info
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF283548),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Customer Info",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 20),

                                            Row(
                                              children: [
                                                // Customer avatar
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 15),

                                                // Customer name
                                                Text(
                                                  _selectedOrder!.customerName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            // Phone
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  color: Colors.grey[400],
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  _selectedOrder!.customerPhone,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),

                                            // Email
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.email,
                                                  color: Colors.grey[400],
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  _selectedOrder!.customerEmail,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),

                                            // Address
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  color: Colors.grey[400],
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    _selectedOrder!
                                                        .customerAddress,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Branch Info
                                const SizedBox(height: 30),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF283548),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Branch Info",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      Row(
                                        children: [
                                          // Branch icon
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.store,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 15),

                                          // Branch name
                                          const Text(
                                            "Main Branch",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // Phone
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            color: Colors.grey[400],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            "+1 (555) 000-0000",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),

                                      // Email
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email,
                                            color: Colors.grey[400],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            "rosealex@gmail.com",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),

                                      // Address
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.grey[400],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 10),
                                          const Expanded(
                                            child: Text(
                                              "11h Burma, Uttara 19, Dhaka-1230",
                                              style: TextStyle(
                                                color: Colors.white,
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
                        )
                      : const Center(
                          child: Text(
                            "No order selected",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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

// These models would normally be in separate files and imported
// For simplicity, we're using the same model definitions from CustomerOrders.dart here

// Model classes (same as in CustomerOrders.dart)
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
