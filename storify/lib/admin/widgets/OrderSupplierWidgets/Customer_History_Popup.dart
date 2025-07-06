// lib/admin/widgets/OrderSupplierWidgets/customer_history_popup.dart (Localized)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
// Localization imports
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
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
      final l10n =
          Localizations.of<AppLocalizations>(context, AppLocalizations)!;
      setState(() {
        _errorMessage = '${l10n.failedToLoadCustomers}: $e';
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
      final l10n =
          Localizations.of<AppLocalizations>(context, AppLocalizations)!;
      setState(() {
        _errorMessage = '${l10n.failedToLoadCustomerHistory}: $e';
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

  Color _getStatusColor(String status, AppLocalizations l10n) {
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

  String _getLocalizedStatusText(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return l10n.statusDelivered;
      case 'shipped':
        return l10n.statusShipped;
      case 'cancelled':
        return l10n.statusCancelled;
      case 'declined':
        return l10n.statusDeclined;
      case 'rejected':
        return l10n.statusRejected;
      case 'accepted':
        return l10n.statusAccepted;
      case 'assigned':
        return l10n.statusAssigned;
      case 'preparing':
        return l10n.statusPreparing;
      case 'prepared':
        return l10n.statusPrepared;
      case 'on_theway':
        return l10n.statusOnTheWay;
      default:
        return status;
    }
  }

  Widget _buildCustomerStats(AppLocalizations l10n, bool isArabic) {
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
          _buildStatItem(l10n.totalCustomers, stats['total']!.toString(),
              Colors.blue, isArabic),
          _buildStatItem(
              l10n.active, stats['active']!.toString(), Colors.green, isArabic),
          _buildStatItem(l10n.totalOrders, stats['totalOrders']!.toString(),
              Colors.orange, isArabic),
          _buildStatItem(l10n.avgOrders, stats['avgOrders']!.toString(),
              Colors.purple, isArabic),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, bool isArabic) {
    return Column(
      children: [
        Text(
          value,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
        ),
        Text(
          label,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: Colors.white70,
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 12.sp,
                  color: Colors.white70,
                ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(
      Customer customer, AppLocalizations l10n, bool isArabic, bool isRtl) {
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
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    )
                                  : GoogleFonts.spaceGrotesk(
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
                              customer.user.isActive == 'Active'
                                  ? l10n.active
                                  : l10n.inactive,
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: customer.user.isActive == 'Active'
                                          ? Colors.green
                                          : Colors.red,
                                    )
                                  : GoogleFonts.spaceGrotesk(
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
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: Colors.white70,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 12.sp,
                                color: Colors.white70,
                              ),
                      ),
                      Text(
                        customer.user.phoneNumber,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: Colors.white60,
                              )
                            : GoogleFonts.spaceGrotesk(
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
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 12.sp,
                                      color: Colors.white54,
                                    )
                                  : GoogleFonts.spaceGrotesk(
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
                      '${customer.orderCount} ${l10n.orders}',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color.fromARGB(255, 105, 65, 198),
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color.fromARGB(255, 105, 65, 198),
                            ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${l10n.balance}: \$${customer.accountBalance}',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${l10n.since} ${CustomerService.formatDate(customer.user.registrationDate)}',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 10.sp,
                              color: Colors.white54,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 10.sp,
                              color: Colors.white54,
                            ),
                    ),
                  ],
                ),

                SizedBox(width: 8.w),
                Transform.flip(
                  flipX: isRtl,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      CustomerOrder order, AppLocalizations l10n, bool isArabic) {
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
                '${l10n.order} #${order.id}',
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status, l10n).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border:
                      Border.all(color: _getStatusColor(order.status, l10n)),
                ),
                child: Text(
                  _getLocalizedStatusText(order.status, l10n),
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(order.status, l10n),
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(order.status, l10n),
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
                      '${l10n.date}: ${order.formattedDate}',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${l10n.items}: ${order.items.length}',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            ),
                    ),
                    if (order.note != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        '${l10n.note}: ${order.note!}',
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: Colors.white60,
                                fontStyle: FontStyle.italic,
                              )
                            : GoogleFonts.spaceGrotesk(
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
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 105, 65, 198),
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 105, 65, 198),
                          ),
                  ),
                  if (order.discount > 0) ...[
                    SizedBox(height: 4.h),
                    Text(
                      '${l10n.discount}: \$${order.discount.toStringAsFixed(2)}',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: Colors.green,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              color: Colors.green,
                            ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    '${l10n.paid}: \$${order.amountPaid.toStringAsFixed(2)}',
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
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
                '${l10n.viewItems} (${order.items.length})',
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )
                    : GoogleFonts.spaceGrotesk(
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
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    )
                                  : GoogleFonts.spaceGrotesk(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                            ),
                            Text(
                              '${l10n.quantity}: ${item.quantity}',
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 12.sp,
                                      color: Colors.white70,
                                    )
                                  : GoogleFonts.spaceGrotesk(
                                      fontSize: 12.sp,
                                      color: Colors.white70,
                                    ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )
                            : GoogleFonts.spaceGrotesk(
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
                    '${l10n.deliveryBy}: ${order.deliveryEmployee!.user.name}',
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
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

  Widget _buildOrderHistoryStats(AppLocalizations l10n, bool isArabic) {
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
          _buildStatItem(
              l10n.total, stats['total'].toString(), Colors.blue, isArabic),
          _buildStatItem(l10n.completed, stats['completed'].toString(),
              Colors.green, isArabic),
          _buildStatItem(
              l10n.active, stats['active'].toString(), Colors.orange, isArabic),
          _buildStatItem(l10n.cancelled, stats['cancelled'].toString(),
              Colors.red, isArabic),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Localization setup
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

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
                        l10n.customerOrdersHistory,
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
                      Text(
                        l10n.viewDetailedCustomerInfo,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 14.sp,
                                color: Colors.white70,
                              )
                            : GoogleFonts.spaceGrotesk(
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
                                    textAlign: isRtl
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    style: isArabic
                                        ? GoogleFonts.cairo(color: Colors.white)
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: l10n.searchCustomers,
                                      hintStyle: isArabic
                                          ? GoogleFonts.cairo(
                                              color: Colors.white54)
                                          : GoogleFonts.spaceGrotesk(
                                              color: Colors.white54),
                                      prefixIcon: isRtl
                                          ? null
                                          : Icon(Icons.search,
                                              color: Colors.white54),
                                      suffixIcon: isRtl
                                          ? Icon(Icons.search,
                                              color: Colors.white54)
                                          : null,
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
                                    style: isArabic
                                        ? GoogleFonts.cairo(color: Colors.white)
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.white),
                                    icon: Transform.flip(
                                      flipX: isRtl,
                                      child: Icon(Icons.arrow_drop_down,
                                          color: Colors.white70),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'All',
                                        child: Text(l10n.all),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Active',
                                        child: Text(l10n.active),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Inactive',
                                        child: Text(l10n.inactive),
                                      ),
                                    ],
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
                          _buildCustomerStats(l10n, isArabic),

                          SizedBox(height: 20.h),

                          // Customers list
                          Text(
                            '${l10n.customers} (${_filteredCustomers.length})',
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
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
                                              l10n.noCustomersFound,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      fontSize: 18.sp,
                                                      color: Colors.white70,
                                                    )
                                                  : GoogleFonts.spaceGrotesk(
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
                                              _filteredCustomers[index],
                                              l10n,
                                              isArabic,
                                              isRtl);
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
                                        ? '${_selectedCustomer!.user.name}${l10n.customerOrderHistory}'
                                        : l10n.orderHistory,
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          )
                                        : GoogleFonts.spaceGrotesk(
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
                                              l10n.selectACustomer,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      fontSize: 18.sp,
                                                      color: Colors.white70,
                                                    )
                                                  : GoogleFonts.spaceGrotesk(
                                                      fontSize: 18.sp,
                                                      color: Colors.white70,
                                                    ),
                                            ),
                                            Text(
                                              l10n.chooseCustomerFromList,
                                              style: isArabic
                                                  ? GoogleFonts.cairo(
                                                      fontSize: 14.sp,
                                                      color: Colors.white54,
                                                    )
                                                  : GoogleFonts.spaceGrotesk(
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
                                                      l10n.noOrdersFound,
                                                      style: isArabic
                                                          ? GoogleFonts.cairo(
                                                              fontSize: 18.sp,
                                                              color: Colors
                                                                  .white70,
                                                            )
                                                          : GoogleFonts
                                                              .spaceGrotesk(
                                                              fontSize: 18.sp,
                                                              color: Colors
                                                                  .white70,
                                                            ),
                                                    ),
                                                    Text(
                                                      l10n.customerHasntPlacedOrders,
                                                      style: isArabic
                                                          ? GoogleFonts.cairo(
                                                              fontSize: 14.sp,
                                                              color: Colors
                                                                  .white54,
                                                            )
                                                          : GoogleFonts
                                                              .spaceGrotesk(
                                                              fontSize: 14.sp,
                                                              color: Colors
                                                                  .white54,
                                                            ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Column(
                                                children: [
                                                  // Order stats
                                                  _buildOrderHistoryStats(
                                                      l10n, isArabic),

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
                                                                .orders[index],
                                                            l10n,
                                                            isArabic);
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
