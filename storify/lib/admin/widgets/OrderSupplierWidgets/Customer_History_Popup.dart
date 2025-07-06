// lib/admin/widgets/OrderSupplierWidgets/customer_history_popup.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/Customer_Service.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/customer_models.dart';

class CustomerHistoryPopup extends StatefulWidget {
  const CustomerHistoryPopup({Key? key}) : super(key: key);

  @override
  State<CustomerHistoryPopup> createState() => _CustomerHistoryPopupState();
}

class _CustomerHistoryPopupState extends State<CustomerHistoryPopup> {
  // Loading states
  bool _isLoadingCustomers = true;
  bool _isLoadingHistory = false;
  String? _errorMessage;

  // Data
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  CustomerOrderHistory? _customerOrderHistory;

  // Search and filter
  String _searchQuery = '';
  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
      _errorMessage = null;
    });

    try {
      final customers = await CustomerService.getCustomers();
      setState(() {
        _customers = customers;
        _isLoadingCustomers = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load customers: $e';
        _isLoadingCustomers = false;
      });
    }
  }

  Future<void> _fetchCustomerHistory(Customer customer) async {
    setState(() {
      _isLoadingHistory = true;
      _selectedCustomer = customer;
      _customerOrderHistory = null;
      _errorMessage = null;
    });

    try {
      final history =
          await CustomerService.getCustomerOrderHistory(customer.id);
      setState(() {
        _customerOrderHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load customer history: $e';
        _isLoadingHistory = false;
      });
    }
  }

  List<Customer> get _filteredCustomers {
    List<Customer> filtered = _customers;

    // Apply status filter
    if (_statusFilter != 'All') {
      filtered = filtered.where((customer) {
        if (_statusFilter == 'Active') {
          return customer.user.isActive == 'Active';
        } else {
          return customer.user.isActive != 'Active';
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        return customer.user.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            customer.user.email
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            customer.user.phoneNumber.contains(_searchQuery) ||
            customer.address.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'shipped':
        return Colors.green;
      case 'cancelled':
      case 'declined':
      case 'rejected':
        return Colors.red;
      case 'accepted':
        return Colors.blue;
      case 'assigned':
        return Colors.cyan;
      case 'preparing':
        return Colors.orange;
      case 'prepared':
        return Colors.amber;
      case 'on_theway':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCustomerStats() {
    if (_customers.isEmpty) return const SizedBox.shrink();

    final stats = CustomerService.getCustomerStats(_customers);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 47, 71, 82),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Total Customers', stats['total']!.toString(), Colors.blue),
          _buildStatItem('Active', stats['active']!.toString(), Colors.green),
          _buildStatItem(
              'Total Orders', stats['totalOrders']!.toString(), Colors.orange),
          _buildStatItem(
              'Avg Orders', stats['avgOrders']!.toString(), Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
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

  Widget _buildCustomerCard(Customer customer) {
    final isSelected = _selectedCustomer?.id == customer.id;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color.fromARGB(255, 105, 65, 198).withOpacity(0.2)
            : const Color.fromARGB(255, 47, 71, 82),
        borderRadius: BorderRadius.circular(12.r),
        border: isSelected
            ? Border.all(
                color: const Color.fromARGB(255, 105, 65, 198), width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => _fetchCustomerHistory(customer),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Profile picture
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: customer.user.profilePicture != null
                      ? ClipOval(
                          child: Image.network(
                            customer.user.profilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                color: Colors.white70,
                                size: 24.sp,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 24.sp,
                        ),
                ),

                SizedBox(width: 16.w),

                // Customer info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.user.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: customer.user.isActive == 'Active'
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: customer.user.isActive == 'Active'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Text(
                              customer.user.isActive,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: customer.user.isActive == 'Active'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        customer.user.email,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        customer.user.phoneNumber,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          color: Colors.white60,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14.sp,
                            color: Colors.white54,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              customer.address,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12.sp,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16.w),

                // Customer stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${customer.orderCount} Orders',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(255, 105, 65, 198),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Balance: \$${customer.accountBalance}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Since ${CustomerService.formatDate(customer.user.registrationDate)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),

                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(CustomerOrder order) {
    final orderStats = CustomerService.getOrderStats([order]);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 47, 71, 82),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            children: [
              Text(
                'Order #${order.id}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _getStatusColor(order.status)),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(order.status),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Order details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${order.formattedDate}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Items: ${order.items.length}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                    if (order.note != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'Note: ${order.note!}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          color: Colors.white60,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${order.totalCost.toStringAsFixed(2)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 105, 65, 198),
                    ),
                  ),
                  if (order.discount > 0) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Discount: \$${order.discount.toStringAsFixed(2)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.green,
                      ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    'Paid: \$${order.amountPaid.toStringAsFixed(2)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Order items
          if (order.items.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ExpansionTile(
              title: Text(
                'View Items (${order.items.length})',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              iconColor: Colors.white70,
              collapsedIconColor: Colors.white70,
              children: order.items.map((item) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      // Product image
                      Container(
                        width: 40.w,
                        height: 40.h,
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
                                      Icons.image,
                                      color: Colors.white70,
                                      size: 20.sp,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.image,
                                color: Colors.white70,
                                size: 20.sp,
                              ),
                      ),

                      SizedBox(width: 12.w),

                      // Product details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Quantity: ${item.quantity}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Delivery info
          if (order.deliveryEmployee != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.delivery_dining,
                    color: Colors.white70,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Delivery by: ${order.deliveryEmployee!.user.name}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderHistoryStats() {
    if (_customerOrderHistory == null ||
        _customerOrderHistory!.orders.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = CustomerService.getOrderStats(_customerOrderHistory!.orders);

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 47, 71, 82),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['total'].toString(), Colors.blue),
          _buildStatItem(
              'Completed', stats['completed'].toString(), Colors.green),
          _buildStatItem('Active', stats['active'].toString(), Colors.orange),
          _buildStatItem(
              'Cancelled', stats['cancelled'].toString(), Colors.red),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt,
                    color: const Color.fromARGB(255, 105, 65, 198),
                    size: 28.sp,
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Orders History',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'View detailed customer information and order history',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side - Customers list
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search and filter
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48.h,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 36, 50, 69),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Search customers...',
                                      hintStyle: GoogleFonts.spaceGrotesk(
                                          color: Colors.white54),
                                      prefixIcon: Icon(Icons.search,
                                          color: Colors.white54),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16.w, vertical: 12.h),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Container(
                                height: 48.h,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 36, 50, 69),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _statusFilter,
                                    dropdownColor:
                                        const Color.fromARGB(255, 36, 50, 69),
                                    style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white),
                                    icon: Icon(Icons.arrow_drop_down,
                                        color: Colors.white70),
                                    items: _statusOptions.map((status) {
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _statusFilter = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20.h),

                          // Customer stats
                          _buildCustomerStats(),

                          SizedBox(height: 20.h),

                          // Customers list
                          Text(
                            'Customers (${_filteredCustomers.length})',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: 12.h),

                          Expanded(
                            child: _isLoadingCustomers
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: const Color.fromARGB(
                                          255, 105, 65, 198),
                                    ),
                                  )
                                : _customers.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.people_outline,
                                              size: 64.sp,
                                              color: Colors.white38,
                                            ),
                                            SizedBox(height: 16.h),
                                            Text(
                                              'No customers found',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 18.sp,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _filteredCustomers.length,
                                        itemBuilder: (context, index) {
                                          return _buildCustomerCard(
                                              _filteredCustomers[index]);
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 24.w),

                    // Right side - Order history
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 36, 50, 69),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // History header
                            Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    color:
                                        const Color.fromARGB(255, 105, 65, 198),
                                    size: 24.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    _selectedCustomer != null
                                        ? '${_selectedCustomer!.user.name}\'s Order History'
                                        : 'Order History',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: _selectedCustomer == null
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_search,
                                              size: 64.sp,
                                              color: Colors.white38,
                                            ),
                                            SizedBox(height: 16.h),
                                            Text(
                                              'Select a customer',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 18.sp,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              'Choose a customer from the list to view their order history',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 14.sp,
                                                color: Colors.white54,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : _isLoadingHistory
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              color: const Color.fromARGB(
                                                  255, 105, 65, 198),
                                            ),
                                          )
                                        : _customerOrderHistory == null ||
                                                _customerOrderHistory!
                                                    .orders.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .receipt_long_outlined,
                                                      size: 64.sp,
                                                      color: Colors.white38,
                                                    ),
                                                    SizedBox(height: 16.h),
                                                    Text(
                                                      'No orders found',
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        fontSize: 18.sp,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    Text(
                                                      'This customer hasn\'t placed any orders yet',
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        fontSize: 14.sp,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Column(
                                                children: [
                                                  // Order stats
                                                  _buildOrderHistoryStats(),

                                                  // Orders list
                                                  Expanded(
                                                    child: ListView.builder(
                                                      itemCount:
                                                          _customerOrderHistory!
                                                              .orders.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return _buildOrderCard(
                                                            _customerOrderHistory!
                                                                .orders[index]);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                              ),
                            ),

                            SizedBox(height: 20.h),
                          ],
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

// Function to show the popup
Future<void> showCustomerHistoryPopup(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return const CustomerHistoryPopup();
    },
  );
}
