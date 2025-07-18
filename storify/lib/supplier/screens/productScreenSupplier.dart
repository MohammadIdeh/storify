// lib/supplier/screens/productScreenSupplier.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import 'package:storify/supplier/screens/ordersScreensSupplier.dart';
import 'package:storify/supplier/widgets/navbar.dart';
import 'package:storify/supplier/widgets/productwidgets/addNewProductWidget.dart';
import 'package:storify/supplier/widgets/productwidgets/products_table_Supplier.dart';
import 'package:storify/supplier/widgets/productwidgets/requestedProductsTable.dart';

class SupplierProducts extends StatefulWidget {
  const SupplierProducts({super.key});

  @override
  State<SupplierProducts> createState() => _SupplierProductsState();
}

class _SupplierProductsState extends State<SupplierProducts> {
  final _productsTableKey = GlobalKey<ProductsTableSupplierState>();
  final _requestedProductsTableKey = GlobalKey<RequestedProductsTableState>();

  // Bottom navigation index.
  int _currentIndex = 1;
  String? profilePictureUrl;
  int? supplierId;

  int _selectedFilterIndex = 0;
  int _selectedRequestedFilterIndex = 0;
  String _searchQuery = "";
  String _requestedSearchQuery = "";
  bool _showAddProductForm = false; // Control visibility of add product form

  // Show products or requested products
  bool _showRequestedProducts = false;

  // Refresh loading states
  bool _isRefreshingProducts = false;
  bool _isRefreshingRequestedProducts = false;

  // Filter options - will be localized in build method
  List<String> _filterOptions = [];
  List<String> _requestedFilterOptions = [];

  // Flag to prevent multiple calls
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadProfileAndSupplierId(); // Safe to call in initState as it doesn't use localization
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only run once and only after the localization context is available
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeFilterOptions();
    }
  }

  void _initializeFilterOptions() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    _filterOptions = [
      l10n.allProducts,
      l10n.activeProducts,
      l10n.inactiveProducts
    ];

    _requestedFilterOptions = [
      l10n.allRequests,
      l10n.pendingRequests,
      l10n.acceptedRequests,
      l10n.declinedRequests
    ];
  }

  Future<void> _loadProfileAndSupplierId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
      supplierId = prefs.getInt('supplierId');
    });
    debugPrint(
        '📦 Loaded supplierId: $supplierId and profilePic: $profilePictureUrl');
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        // Navigate to supplier orders with URL change
        Navigator.pushNamed(context, '/supplier/orders');
        break;
      case 1:
        // Stay on current screen
        break;
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      if (_showRequestedProducts) {
        _requestedSearchQuery = query;
      } else {
        _searchQuery = query;
      }
    });
  }

  // Manual refresh for products table
  Future<void> _manualRefreshProducts() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    setState(() {
      _isRefreshingProducts = true;
    });

    try {
      if (_productsTableKey.currentState != null) {
        _productsTableKey.currentState!.refreshProducts();
        debugPrint('Products table refresh called manually');
      }

      // Wait a bit for the refresh to complete
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isRefreshingProducts = false;
      });

      // Show success message
    } catch (e) {
      setState(() {
        _isRefreshingProducts = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Manual refresh for requested products table
  Future<void> _manualRefreshRequestedProducts() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    setState(() {
      _isRefreshingRequestedProducts = true;
    });

    try {
      if (_requestedProductsTableKey.currentState != null) {
        _requestedProductsTableKey.currentState!.refreshProducts();
        debugPrint('Requested products table refresh called manually');
      }

      // Wait a bit for the refresh to complete
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isRefreshingRequestedProducts = false;
      });

      // Show success message
    } catch (e) {
      setState(() {
        _isRefreshingRequestedProducts = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing requested products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onProductAdded(Map<String, dynamic> newProduct) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    setState(() {
      _showAddProductForm = false;
    });

    debugPrint('Product added, refreshing tables after delay...');

    // Increase the delay to 2 seconds to ensure API has time to process
    Future.delayed(const Duration(milliseconds: 2000), () {
      // Refresh product tables
      if (_productsTableKey.currentState != null) {
        _productsTableKey.currentState!.refreshProducts();
        debugPrint('Products table refresh called');
      } else {
        debugPrint('Products table state is null, cannot refresh');
      }

      // Also refresh requested products table
      if (_requestedProductsTableKey.currentState != null) {
        _requestedProductsTableKey.currentState!.refreshProducts();
        debugPrint('Requested products table refresh called');
      } else {
        debugPrint('Requested products table state is null, cannot refresh');
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.productAddedSuccessfully),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3), // Increase duration
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
          preferredSize: const Size.fromHeight(250),
          child: NavigationBarSupplier(
            currentIndex: _currentIndex,
            onTap: _onNavItemTap,
            profilePictureUrl: profilePictureUrl,
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(30.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.productManagement,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
                SizedBox(height: 24.h),

                // Tab selection
                Row(
                  children: [
                    _buildTabButton(
                      label: l10n.products,
                      isSelected: !_showRequestedProducts,
                      onPressed: () {
                        setState(() {
                          _showRequestedProducts = false;
                        });
                      },
                    ),
                    SizedBox(width: 16.w),
                    _buildTabButton(
                      label: l10n.requestedProducts,
                      isSelected: _showRequestedProducts,
                      onPressed: () {
                        setState(() {
                          _showRequestedProducts = true;
                        });
                      },
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Show either Products or Requested Products UI
                if (_showRequestedProducts)
                  _buildRequestedProductsUI()
                else
                  _buildProductsUI(),

                // Show Add Product Form if enabled
                if (_showAddProductForm)
                  Addnewproductwidget(
                    onCancel: () {
                      setState(() {
                        _showAddProductForm = false;
                      });
                    },
                    onAddProduct: _onProductAdded,
                    supplierId: supplierId ?? 0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tab button for switching between products and requested products
  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    final isArabic = LocalizationHelper.isArabic(context);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color.fromARGB(255, 105, 65, 198)
            : const Color.fromARGB(255, 36, 50, 69),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        fixedSize: Size(220.w, 55.h),
        elevation: isSelected ? 2 : 0,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: isArabic
            ? GoogleFonts.cairo(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : const Color.fromARGB(255, 105, 123, 123),
              )
            : GoogleFonts.spaceGrotesk(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : const Color.fromARGB(255, 105, 123, 123),
              ),
      ),
    );
  }

  // Products UI with filter, search and table
  Widget _buildProductsUI() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter and Search Row with Refresh Icon
        Row(
          children: [
            Text(
              l10n.productsList,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
            ),
            SizedBox(width: 10.w),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                children: List.generate(
                  _filterOptions.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      left: isRtl ? 8.w : 0,
                      right: isRtl ? 0 : 8.w,
                    ),
                    child: _buildFilterChip(_filterOptions[index], index,
                        isRequestedProducts: false),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w), // Add some spacing

            // Refresh Icon Button for Products
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                onPressed:
                    _isRefreshingProducts ? null : _manualRefreshProducts,
                icon: _isRefreshingProducts
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: const Color.fromARGB(255, 105, 65, 198),
                        size: 24.sp,
                      ),
                // tooltip: l10n.refreshProducts ?? 'Refresh Products',
              ),
            ),

            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 36, 50, 69),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                fixedSize: Size(180.w, 55.h),
                elevation: 1,
              ),
              onPressed: () {
                setState(() {
                  _showAddProductForm = !_showAddProductForm;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 20.sp,
                    color: const Color.fromARGB(255, 105, 123, 123),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.addProduct,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 105, 123, 123),
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 105, 123, 123),
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 15.w),
            Container(
              width: 300.w,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextField(
                style: isArabic
                    ? GoogleFonts.cairo(color: Colors.white70)
                    : GoogleFonts.spaceGrotesk(color: Colors.white70),
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: l10n.searchProductByNameOrId,
                  hintStyle: isArabic
                      ? GoogleFonts.cairo(color: Colors.white30)
                      : GoogleFonts.spaceGrotesk(color: Colors.white30),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white30,
                    size: 20.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onChanged: _updateSearchQuery,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Products Table
        ProductsTableSupplier(
          key: _productsTableKey,
          selectedFilterIndex: _selectedFilterIndex,
          searchQuery: _searchQuery,
        ),
      ],
    );
  }

  // Requested Products UI with filter, search and table
  Widget _buildRequestedProductsUI() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter and Search Row with Refresh Icon
        Row(
          children: [
            Text(
              l10n.requestedProductsList,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
            ),
            SizedBox(width: 10.w),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                children: List.generate(
                  _requestedFilterOptions.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      left: isRtl ? 8.w : 0,
                      right: isRtl ? 0 : 8.w,
                    ),
                    child: _buildFilterChip(
                        _requestedFilterOptions[index], index,
                        isRequestedProducts: true),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w), // Add some spacing

            // Refresh Icon Button for Requested Products
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                onPressed: _isRefreshingRequestedProducts
                    ? null
                    : _manualRefreshRequestedProducts,
                icon: _isRefreshingRequestedProducts
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: const Color.fromARGB(255, 105, 65, 198),
                        size: 24.sp,
                      ),
                // tooltip: l10n.refreshRequestedProducts ?? 'Refresh Requested Products',
              ),
            ),

            const Spacer(),
            Container(
              width: 300.w,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextField(
                style: isArabic
                    ? GoogleFonts.cairo(color: Colors.white70)
                    : GoogleFonts.spaceGrotesk(color: Colors.white70),
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: l10n.searchRequestByNameOrId,
                  hintStyle: isArabic
                      ? GoogleFonts.cairo(color: Colors.white30)
                      : GoogleFonts.spaceGrotesk(color: Colors.white30),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white30,
                    size: 20.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onChanged: _updateSearchQuery,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Requested Products Table
        RequestedProductsTable(
          key: _requestedProductsTableKey,
          selectedFilterIndex: _selectedRequestedFilterIndex,
          searchQuery: _requestedSearchQuery,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index,
      {required bool isRequestedProducts}) {
    final bool isSelected = isRequestedProducts
        ? _selectedRequestedFilterIndex == index
        : _selectedFilterIndex == index;
    final isArabic = LocalizationHelper.isArabic(context);

    return InkWell(
      onTap: () {
        setState(() {
          if (isRequestedProducts) {
            _selectedRequestedFilterIndex = index;
          } else {
            _selectedFilterIndex = index;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 105, 65, 198)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : const Color.fromARGB(255, 230, 230, 230),
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : const Color.fromARGB(255, 230, 230, 230),
                ),
        ),
      ),
    );
  }
}
