import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import 'dart:convert';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/admin/widgets/trackingWidgets/cards.dart';
import 'package:storify/admin/widgets/trackingWidgets/advanced_tracking_map.dart';

class Track extends StatefulWidget {
  const Track({super.key});

  @override
  State<Track> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<Track> {
  int _currentIndex = 5;
  String? profilePictureUrl;
  List<Map<String, String>> _trackData = [];
  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  bool _isLoadingOrders = false;
  String? _errorMessage;
  String? _ordersErrorMessage;

  // Filter and pagination for orders history
  String _orderStatusFilter = 'all';
  int _currentPage = 1;
  final int _ordersPerPage = 10;

  // ADD THIS: Key to force map refresh
  GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _fetchTrackingData();
    _fetchAllOrders();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  Future<void> _fetchTrackingData() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final headers = await AuthService.getAuthHeaders(role: 'Admin');

      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/dashboard/tracking-cards'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _trackData = [
            {
              'title': l10n.totalShipment,
              'value': data['totalShipment'].toString(),
            },
            {
              'title': l10n.completed,
              'value': data['completed'].toString(),
            },
            {
              'title': l10n.pending,
              'value': data['pending'].toString(),
            },
          ];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = l10n.authenticationFailed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              '${l10n.failedToLoadTrackingData}: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.errorFetchingTrackingData}: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllOrders() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    try {
      setState(() {
        _isLoadingOrders = true;
        _ordersErrorMessage = null;
      });

      final headers = await AuthService.getAuthHeaders(role: 'Admin');

      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/customer-order/all-orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allOrders = data['orders'] ?? [];
          _isLoadingOrders = false;
        });
      } else {
        setState(() {
          _ordersErrorMessage =
              '${l10n.failedToLoadOrders}: ${response.statusCode}';
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      setState(() {
        _ordersErrorMessage = '${l10n.errorFetchingOrders}: $e';
        _isLoadingOrders = false;
      });
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    try {
      // Show reason input dialog
      final cancelReason = await _showCancelReasonDialog(orderId);
      if (cancelReason == null || cancelReason.trim().isEmpty) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 36, 50, 69),
          content: Row(
            children: [
              CircularProgressIndicator(
                color: const Color.fromARGB(255, 99, 102, 241),
              ),
              SizedBox(width: 16.w),
              Text(
                l10n.cancelingOrder,
                style: isArabic
                    ? GoogleFonts.cairo(color: Colors.white)
                    : GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      final headers = await AuthService.getAuthHeaders(role: 'Admin');
      headers['Content-Type'] = 'application/json';
      final requestBody = json.encode({"reason": cancelReason.trim()});

      final response = await http.post(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/customer-order/$orderId/cancel'),
        headers: headers,
        body: requestBody,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        // Show success message
        _showSuccessMessage('${l10n.orderCanceledSuccessfully} #$orderId');

        // Refresh data
        await _fetchTrackingData();
        await _fetchAllOrders();

        // REFRESH THE MAP
        final mapState = _mapKey.currentState;
        if (mapState != null) {
          try {
            // Use dynamic to call the method
            await (mapState as dynamic).refreshMapData();
          } catch (e) {
            print('Failed to refresh map: $e');
          }
        }
      } else {
        final errorData =
            response.body.isNotEmpty ? json.decode(response.body) : {};
        final errorMessage = errorData['message'] ??
            '${l10n.failedToCancelOrder}: ${response.statusCode}';
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if still open
      _showErrorMessage('${l10n.errorCancelingOrder}: $e');
    }
  }

  Future<String?> _showCancelReasonDialog(int orderId) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return await showDialog<String>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(255, 36, 50, 69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.cancel,
                color: Colors.red,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${l10n.cancelOrder} #$orderId',
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18.sp,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18.sp,
                        ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.provideCancellationReason,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: reasonController,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 200,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 14.sp,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                  decoration: InputDecoration(
                    hintText: l10n.enterCancellationReason,
                    hintStyle: isArabic
                        ? GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 14.sp,
                          )
                        : GoogleFonts.spaceGrotesk(
                            color: Colors.white54,
                            fontSize: 14.sp,
                          ),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 46, 57, 84),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(255, 99, 102, 241),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(16.w),
                    counterStyle: isArabic
                        ? GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 12.sp,
                          )
                        : GoogleFonts.spaceGrotesk(
                            color: Colors.white54,
                            fontSize: 12.sp,
                          ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.cancellationReasonRequired;
                    }
                    if (value.trim().length < 10) {
                      return l10n.reasonMinLength;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.actionCannotBeUndone,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.red.withOpacity(0.8),
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.red.withOpacity(0.8),
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                l10n.keepOrder,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(reasonController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                l10n.cancelOrder,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    final isArabic = LocalizationHelper.isArabic(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: isArabic
                    ? GoogleFonts.cairo(color: Colors.white)
                    : GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    final isArabic = LocalizationHelper.isArabic(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: isArabic
                    ? GoogleFonts.cairo(color: Colors.white)
                    : GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Future<void> _refreshTrackingData() async {
    await Future.wait([
      _fetchTrackingData(),
      _fetchAllOrders(),
    ]);

    // ALSO REFRESH THE MAP
    final mapState = _mapKey.currentState;
    if (mapState != null) {
      try {
        // Use dynamic to call the method
        await (mapState as dynamic).refreshMapData();
      } catch (e) {
        print('Failed to refresh map: $e');
      }
    }
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/admin/dashboard');
        break;
      case 1:
        Navigator.pushNamed(context, '/admin/products');
        break;
      case 2:
        Navigator.pushNamed(context, '/admin/categories');
        break;
      case 3:
        Navigator.pushNamed(context, '/admin/orders');
        break;
      case 4:
        Navigator.pushNamed(context, '/admin/roles');
        break;
      case 5:
        // Current Track screen - no navigation needed
        break;
    }
  }

  Widget _buildTrackingCards() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 99, 102, 241),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color.fromARGB(255, 46, 57, 84),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40.sp,
              ),
              SizedBox(height: 10.h),
              Text(
                l10n.failedToLoadTrackingData,
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
              SizedBox(height: 10.h),
              ElevatedButton(
                onPressed: _refreshTrackingData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 99, 102, 241),
                ),
                child: Text(
                  l10n.retry,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 12.sp,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final numberOfCards = _trackData.length;
        const spacing = 40.0;
        final cardWidth =
            (availableWidth - ((numberOfCards - 1) * spacing)) / numberOfCards;

        return Wrap(
          spacing: spacing,
          runSpacing: 20,
          children: List.generate(_trackData.length, (index) {
            final data = _trackData[index];
            return SizedBox(
              width: cardWidth,
              child: TrackCards(
                title: data['title'] ?? '',
                value: data['value'] ?? '',
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildOrdersHistorySection() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Container(
      margin: EdgeInsets.only(top: 40.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: const Color.fromARGB(255, 46, 57, 84),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: const Color.fromARGB(255, 99, 102, 241),
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    l10n.ordersHistory,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                  ),
                  const Spacer(),
                  // Filter dropdown
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 46, 57, 84),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: DropdownButton<String>(
                      value: _orderStatusFilter,
                      dropdownColor: const Color.fromARGB(255, 46, 57, 84),
                      underline: Container(),
                      style: isArabic
                          ? GoogleFonts.cairo(color: Colors.white)
                          : GoogleFonts.spaceGrotesk(color: Colors.white),
                      items: [
                        DropdownMenuItem(
                            value: 'all', child: Text(l10n.allOrdersFilter)),
                        DropdownMenuItem(
                            value: 'on_theway', child: Text(l10n.onTheWay)),
                        DropdownMenuItem(
                            value: 'Shipped', child: Text(l10n.shipped)),
                        DropdownMenuItem(
                            value: 'Cancelled', child: Text(l10n.cancelled)),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _orderStatusFilter = value!;
                          _currentPage = 1;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  IconButton(
                    onPressed: _fetchAllOrders,
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.white70,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Orders content
          if (_isLoadingOrders)
            Container(
              height: 200.h,
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color.fromARGB(255, 99, 102, 241),
                ),
              ),
            )
          else if (_ordersErrorMessage != null)
            Container(
              height: 200.h,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 32.sp),
                    SizedBox(height: 8.h),
                    Text(
                      _ordersErrorMessage!,
                      style: isArabic
                          ? GoogleFonts.cairo(color: Colors.white70)
                          : GoogleFonts.spaceGrotesk(color: Colors.white70),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _fetchAllOrders,
                      child: Text(
                        l10n.retry,
                        style: isArabic
                            ? GoogleFonts.cairo()
                            : GoogleFonts.spaceGrotesk(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildOrdersTable(),
        ],
      ),
    );
  }

  Widget _buildOrdersTable() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    final filteredOrders = _allOrders.where((order) {
      if (_orderStatusFilter == 'all') return true;
      return order['status'] == _orderStatusFilter;
    }).toList();

    final totalPages = (filteredOrders.length / _ordersPerPage).ceil();
    final startIndex = (_currentPage - 1) * _ordersPerPage;
    final endIndex =
        (startIndex + _ordersPerPage).clamp(0, filteredOrders.length);
    final paginatedOrders = filteredOrders.sublist(startIndex, endIndex);

    if (filteredOrders.isEmpty) {
      return Container(
        height: 200.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48.sp,
                color: Colors.white54,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.noOrdersFound,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 16.sp,
                        color: Colors.white70,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        color: Colors.white70,
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          // Table headers
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 46, 57, 84),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    l10n.orderIdHeader,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.customer,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    l10n.status,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    l10n.total,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.date,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    l10n.actions,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          ...paginatedOrders.asMap().entries.map((entry) {
            final index = entry.key;
            final order = entry.value;
            return _buildOrderRow(order, index);
          }).toList(),

          // Pagination
          if (totalPages > 1) _buildPagination(totalPages),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order, int index) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    final isEven = index % 2 == 0;
    final status = order['status'] ?? 'Unknown';
    final customerName =
        order['customer']?['user']?['name'] ?? l10n.unknownCustomer;
    final totalCost = order['totalCost'] ?? 0;
    final createdAt = order['createdAt'] ?? '';
    final orderId = order['id'] ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isEven
            ? const Color.fromARGB(255, 29, 41, 57)
            : const Color.fromARGB(255, 36, 50, 69),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '#$orderId',
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              customerName,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 14.sp,
                      color: Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getLocalizedStatus(status),
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(status),
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(status),
                          ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Add cancellation indicator for cancelled orders
                // Corrected Code
                if (status == 'Cancelled' &&
                    order['cancelledByUser'] != null) ...[
                  SizedBox(width: 4.w),
                  Tooltip(
                    // Call it as a function and pass the 'name'
                    message: l10n
                        .cancelledByTooltip(order['cancelledByUser']['name']),
                    child: Icon(
                      Icons.info_outline,
                      size: 14.sp,
                      color: Colors.red.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '\$${totalCost.toString()}',
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 16, 185, 129),
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 16, 185, 129),
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(createdAt),
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
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                if (status == 'on_theway') ...[
                  IconButton(
                    onPressed: () => _cancelOrder(
                        orderId), // FIX: Actually call the cancel function
                    icon: Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: 20.sp,
                    ),
                    tooltip: l10n.cancelOrder,
                  ),
                ],
                IconButton(
                  onPressed: () => _showOrderDetails(order),
                  icon: Icon(
                    Icons.visibility,
                    color: const Color.fromARGB(255, 99, 102, 241),
                    size: 20.sp,
                  ),
                  tooltip: l10n.viewDetails,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedStatus(String status) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    switch (status.toLowerCase()) {
      case 'on_theway':
        return l10n.onTheWay;
      case 'shipped':
        return l10n.shipped;
      case 'cancelled':
        return l10n.cancelled;
      case 'pending':
        return l10n.pending;
      default:
        return l10n.unknown;
    }
  }

  Widget _buildPagination(int totalPages) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 46, 57, 84),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.page} $_currentPage ${l10n.offf} $totalPages',
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
            Row(
              children: [
                IconButton(
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                  icon: Icon(
                    isRtl ? Icons.chevron_right : Icons.chevron_left,
                    color: _currentPage > 1 ? Colors.white : Colors.white38,
                  ),
                ),
                ...List.generate(
                  totalPages.clamp(0, 5),
                  (index) {
                    final page = index + 1;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: TextButton(
                        onPressed: () => setState(() => _currentPage = page),
                        style: TextButton.styleFrom(
                          backgroundColor: _currentPage == page
                              ? const Color.fromARGB(255, 99, 102, 241)
                              : Colors.transparent,
                          minimumSize: Size(40.w, 40.h),
                        ),
                        child: Text(
                          page.toString(),
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  color: _currentPage == page
                                      ? Colors.white
                                      : Colors.white70,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  color: _currentPage == page
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                  icon: Icon(
                    isRtl ? Icons.chevron_left : Icons.chevron_right,
                    color: _currentPage < totalPages
                        ? Colors.white
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_theway':
        return Colors.orange;
      case 'shipped':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _formatCancellationReason(String reason) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    switch (reason) {
      case 'administrative_decision':
        return l10n.administrativeDecision;
      case 'customer_request':
        return l10n.customerRequest;
      case 'inventory_issue':
        return l10n.inventoryIssue;
      case 'delivery_problem':
        return l10n.deliveryProblem;
      case 'payment_issue':
        return l10n.paymentIssue;
      case 'system_error':
        return l10n.systemError;
      default:
        return reason
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : word)
            .join(' ');
    }
  }

  String _formatDate(String dateString) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return l10n.invalidDate;
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(255, 36, 50, 69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            '${l10n.orderDetailsTitle} #${order['id']}',
            style: isArabic
                ? GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )
                : GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(l10n.status,
                      _getLocalizedStatus(order['status'] ?? 'Unknown')),
                  _buildDetailItem(
                      l10n.customer,
                      order['customer']?['user']?['name'] ??
                          l10n.unknownCustomer),
                  _buildDetailItem(
                      l10n.email,
                      order['customer']?['user']?['email'] ??
                          l10n.unknownEmail),
                  _buildDetailItem(l10n.address,
                      order['customer']?['address'] ?? l10n.unknownAddress),
                  _buildDetailItem(
                      l10n.totalCost, '\$${order['totalCost'] ?? 0}'),
                  _buildDetailItem(l10n.paymentMethod,
                      order['paymentMethod'] ?? l10n.notSpecified),
                  if (order['deliveryEmployee'] != null)
                    _buildDetailItem(
                        l10n.deliveryPerson,
                        order['deliveryEmployee']['user']['name'] ??
                            l10n.unknownDeliveryPerson),
                  _buildDetailItem(
                      l10n.created, _formatDate(order['createdAt'] ?? '')),
                  // Show cancellation reason for cancelled orders
                  if (order['status'] == 'Cancelled' &&
                      order['cancellationReason'] != null) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                l10n.cancellationDetails,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                      ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          _buildDetailItem(
                              l10n.reason,
                              _formatCancellationReason(
                                  order['cancellationReason'])),
                          if (order['cancelledAt'] != null)
                            _buildDetailItem(l10n.cancelledAt,
                                _formatDate(order['cancelledAt'])),

                          // Show admin details who cancelled the order
                          if (order['cancelledByUser'] != null) ...[
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.red,
                                        size: 14.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        l10n.cancelledByAdmin,
                                        style: isArabic
                                            ? GoogleFonts.cairo(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12.sp,
                                              )
                                            : GoogleFonts.spaceGrotesk(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12.sp,
                                              ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                  _buildDetailItem(
                                      l10n.adminName,
                                      order['cancelledByUser']['name'] ??
                                          l10n.unknownAdmin),
                                  _buildDetailItem(
                                      l10n.adminEmail,
                                      order['cancelledByUser']['email'] ??
                                          l10n.noEmail),
                                  _buildDetailItem(l10n.adminId,
                                      '#${order['cancelledByUser']['userId'] ?? l10n.unknown}'),
                                ],
                              ),
                            ),
                          ] else if (order['cancelledBy'] != null) ...[
                            // Fallback to old format if new format not available
                            _buildDetailItem(l10n.cancelledBy,
                                '${l10n.adminIdLabel}: ${order['cancelledBy']}'),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (order['items'] != null && order['items'].isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Text(
                      '${l10n.items}:',
                      style: isArabic
                          ? GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            )
                          : GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                    SizedBox(height: 8.h),
                    ...order['items']
                        .map<Widget>((item) => Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 46, 57, 84),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['product']?['name'] ??
                                          l10n.unknownProduct,
                                      style: isArabic
                                          ? GoogleFonts.cairo(
                                              color: Colors.white)
                                          : GoogleFonts.spaceGrotesk(
                                              color: Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '${l10n.qty}: ${item['quantity']} × ${item['Price']}',
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            color: Colors.white70)
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.white70),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (order['status'] == 'on_theway') ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelOrder(
                      order['id']); // FIX: Actually call the cancel function
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                ),
                child: Text(
                  l10n.cancelOrder,
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.red)
                      : GoogleFonts.spaceGrotesk(color: Colors.red),
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.close,
                style: isArabic
                    ? GoogleFonts.cairo(color: Colors.white70)
                    : GoogleFonts.spaceGrotesk(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final isArabic = LocalizationHelper.isArabic(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: isArabic
                  ? GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    )
                  : GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isArabic
                  ? GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    )
                  : GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
        ],
      ),
    );
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
          preferredSize: const Size.fromHeight(200),
          child: MyNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavItemTap,
            profilePictureUrl: profilePictureUrl,
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshTrackingData,
          color: const Color.fromARGB(255, 99, 102, 241),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                  left: isRtl ? 45.w : 45.w,
                  top: 20.h,
                  right: isRtl ? 45.w : 45.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// --- Dashboard Title ---
                    Row(
                      children: [
                        Text(
                          l10n.tracking,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  fontSize: 35.sp,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      const Color.fromARGB(255, 246, 246, 246),
                                )
                              : GoogleFonts.spaceGrotesk(
                                  fontSize: 35.sp,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      const Color.fromARGB(255, 246, 246, 246),
                                ),
                        ),
                        const Spacer(),
                        // Add refresh button
                        IconButton(
                          onPressed: _refreshTrackingData,
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.white70,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),

                    /// --- Tracking Cards ---
                    const SizedBox(height: 20),
                    _buildTrackingCards(),

                    /// --- Advanced Map Section ---
                    const SizedBox(height: 40),
                    AdvancedTrackingMap(
                      key: _mapKey, // THIS IS THE KEY FIX!
                      onOrderCancel: _cancelOrder,
                    ),

                    /// --- Orders History Section ---
                    _buildOrdersHistorySection(),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
