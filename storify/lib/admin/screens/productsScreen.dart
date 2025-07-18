import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/admin/screens/track.dart';
import 'package:storify/admin/widgets/productsWidgets/RequestedProductsTable.dart';
import 'package:storify/admin/widgets/productsWidgets/addNewProductPopUp.dart';
import 'package:storify/admin/widgets/productsWidgets/cardsModel.dart';
import 'package:storify/admin/widgets/productsWidgets/exportPopUp.dart';
import 'package:storify/GeneralWidgets/longPressDraggable.dart';
import 'package:storify/admin/widgets/productsWidgets/productsCards.dart';
import 'package:storify/admin/widgets/productsWidgets/productsListable.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class Productsscreen extends StatefulWidget {
  const Productsscreen({super.key});

  @override
  State<Productsscreen> createState() => _ProductsscreenState();
}

class _ProductsscreenState extends State<Productsscreen> {
  int _currentIndex = 1;
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: UnActive
  int _selectedRequestFilterIndex =
      0; // 0: All, 1: Pending, 2: Accepted, 3: Declined
  String _searchQuery = "";
  String _requestSearchQuery = "";
  String? profilePictureUrl;

  // View mode: 'products' or 'requests'
  String _viewMode = 'products';

  // Create GlobalKeys to access table states
  final GlobalKey<ProductslistTableState> _tableKey =
      GlobalKey<ProductslistTableState>();
  final GlobalKey<RequestedProductsTableState> _requestTableKey =
      GlobalKey<RequestedProductsTableState>();

  // Service instance
  final ProductStatsService _statsService = ProductStatsService();

  // Dashboard stats
  late ProductStats _stats = ProductStats.empty();

  // List to track the order of cards
  late List<int> _cardOrder = [0, 1, 2, 3];

  // List of product card widgets
  late List<Widget> _productCards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load all necessary data
  Future<void> _loadData() async {
    await Future.wait([
      _loadProfilePicture(),
      _loadCardOrder(),
      _loadDashboardStats(),
    ]);
  }

  // Load profile picture from SharedPreferences
  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  // Load card order from SharedPreferences
  Future<void> _loadCardOrder() async {
    final order = await _statsService.getCardOrder();
    setState(() {
      _cardOrder = order;
    });
    _updateProductCards();
  }

  // Fetch dashboard stats from API
  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _statsService.fetchProductStats();
      setState(() {
        _stats = stats;
      });
      _updateProductCards();
    } catch (e) {
      final l10n =
          Localizations.of<AppLocalizations>(context, AppLocalizations)!;
      // Handle error - maybe show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToLoadDashboardStats(e.toString()))),
      );
    }
  }

  // Update product cards with latest stats
  void _updateProductCards() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    final List<Widget> cards = [
      ProductsCards(
        title: l10n.totalProducts,
        value: _stats.totalProducts.toString(),
        subtext: '',
        key: UniqueKey(),
      ),
      ProductsCards(
        title: l10n.activeProducts,
        value: _stats.activeProducts.toString(),
        subtext: '',
        key: UniqueKey(),
      ),
      ProductsCards(
        title: l10n.inactiveProducts,
        value: _stats.inactiveProducts.toString(),
        subtext: '',
        key: UniqueKey(),
      ),
      ProductsCards(
        title: l10n.totalCategories,
        value: _stats.totalCategories.toString(),
        subtext: '',
        key: UniqueKey(),
      ),
    ];

    // Reorder cards based on saved order
    final orderedCards = List<Widget>.filled(cards.length, Container());
    for (int i = 0; i < _cardOrder.length; i++) {
      final originalIndex = _cardOrder[i];
      if (originalIndex < cards.length) {
        orderedCards[i] = cards[originalIndex];
      }
    }

    setState(() {
      _productCards = orderedCards;
    });
  }

  // Refresh stats after operations that might change them
  Future<void> refreshStats() async {
    await _loadDashboardStats();
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
        // Current Products screen - no navigation needed
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
        Navigator.pushNamed(context, '/admin/tracking');
        break;
    }
  }

  /// Builds one toggle chip.
  Widget _buildFilterChip(String label, int index, bool isRequestFilter) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    final bool isSelected = isRequestFilter
        ? (_selectedRequestFilterIndex == index)
        : (_selectedFilterIndex == index);

    return InkWell(
      onTap: () {
        setState(() {
          if (isRequestFilter) {
            _selectedRequestFilterIndex = index;
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

  Widget _buildDraggableProductCardItem(int index, double cardWidth) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: SizedBox(
        width: cardWidth,
        child: DragTarget<int>(
          builder: (context, candidateData, rejectedData) {
            return CustomLongPressDraggable<int>(
              data: index,
              feedback: SizedBox(
                width: cardWidth,
                child: Material(
                  color: Colors.transparent,
                  child: _productCards[index],
                ),
              ),
              childWhenDragging: SizedBox(
                width: cardWidth,
                child: Opacity(
                  opacity: 0.3,
                  child: _productCards[index],
                ),
              ),
              child: _productCards[index],
            );
          },
          onWillAccept: (oldIndex) => oldIndex != index,
          onAccept: (oldIndex) {
            setState(() {
              // Swap the widgets in the UI
              final temp = _productCards[oldIndex];
              _productCards[oldIndex] = _productCards[index];
              _productCards[index] = temp;

              // Update the order tracking
              final oldCardType = _cardOrder[oldIndex];
              final newCardType = _cardOrder[index];
              _cardOrder[oldIndex] = newCardType;
              _cardOrder[index] = oldCardType;

              // Save the updated order to SharedPreferences
              _statsService.saveCardOrder(_cardOrder);
            });
          },
        ),
      ),
    );
  }

  // Build the view mode toggle buttons
  Widget _buildViewModeToggle() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    return Container(
      width: isArabic ? 250.w : 300.w,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        children: [
          _buildViewModeButton(l10n.products, 'products'),
          SizedBox(width: 8.w),
          _buildViewModeButton(l10n.requestedProducts, 'requests'),
        ],
      ),
    );
  }

  // Build individual view mode button
  Widget _buildViewModeButton(String label, String mode) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    final bool isSelected = (_viewMode == mode);

    return InkWell(
      onTap: () {
        setState(() {
          _viewMode = mode;
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

  // Update the search query based on the current view mode
  void _updateSearchQuery(String query) {
    setState(() {
      if (_viewMode == 'products') {
        _searchQuery = query;
      } else {
        _requestSearchQuery = query;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Get localized filter arrays
    final List<String> _filters = [l10n.all, l10n.active, l10n.inactive];
    final List<String> _requestFilters = [
      l10n.all,
      l10n.pending,
      l10n.accepted,
      l10n.declined
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: MyNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavItemTap,
          profilePictureUrl: profilePictureUrl,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: isRtl ? 45.w : 45.w,
            top: 20.h,
            right: isRtl ? 45.w : 45.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Products title and Filter button.
              Row(
                children: [
                  Text(
                    l10n.products,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 35.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 246, 246, 246),
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 35.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 246, 246, 246),
                          ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),

              /// --- Draggable ProductsCards (in a single-row Wrap) ---
              _productCards.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        const numberOfCards = 4;
                        const spacing = 40.0;
                        final cardWidth =
                            (availableWidth - ((numberOfCards - 1) * spacing)) /
                                numberOfCards;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: 20,
                          children:
                              List.generate(_productCards.length, (index) {
                            return _buildDraggableProductCardItem(
                                index, cardWidth);
                          }),
                        );
                      },
                    ),
              SizedBox(height: 40.h),

              /// --- View Mode Toggle: Products vs Requested Products ---
              _buildViewModeToggle(),
              SizedBox(height: 24.h),

              /// --- Row Under the Cards (Product List + Filters + Search + Buttons) ---
              _viewMode == 'products'
                  ? _buildProductsControls(_filters)
                  : _buildRequestedProductsControls(_requestFilters),
              SizedBox(height: 30.h),

              /// --- Table based on view mode ---
              _viewMode == 'products'
                  ? ProductslistTable(
                      key: _tableKey,
                      selectedFilterIndex: _selectedFilterIndex,
                      searchQuery: _searchQuery,
                      onOperationCompleted: () {
                        // Refresh stats when any operation completes in the table
                        refreshStats();
                      },
                    )
                  : RequestedProductsTable(
                      key: _requestTableKey,
                      selectedFilterIndex: _selectedRequestFilterIndex,
                      searchQuery: _requestSearchQuery,
                      onOperationCompleted: () {
                        // Refresh when a request is processed
                        refreshStats();
                      },
                    ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // Build controls for Products view
  Widget _buildProductsControls(List<String> filters) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Row(
      children: [
        // "Product List" text.
        Text(
          l10n.productList,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
        ),
        SizedBox(width: 24.w),
        // Container for filter chips.
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 36, 50, 69),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            children: [
              _buildFilterChip(filters[0], 0, false),
              SizedBox(width: 8.w),
              _buildFilterChip(filters[1], 1, false),
              SizedBox(width: 8.w),
              _buildFilterChip(filters[2], 2, false),
            ],
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
          onPressed: () async {
            // Check if user is authenticated before showing the popup
            final isLoggedIn = await AuthService.isLoggedIn();
            if (!isLoggedIn) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.mustBeLoggedInToAddProducts)),
              );
              return;
            }

            // Show the add product popup
            showDialog(
              context: context,
              builder: (context) => const AddProductPopUp(),
            ).then((result) {
              // If the product was added successfully, refresh both the product list and stats
              if (result == true) {
                // Refresh the table by calling the fetchProducts method
                _tableKey.currentState?.refreshProducts();

                // Refresh the dashboard stats
                refreshStats();
              }
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
          height: 55.h,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 36, 50, 69),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120.w,
                child: TextField(
                  onChanged: _updateSearchQuery,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.white)
                      : GoogleFonts.spaceGrotesk(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    hintStyle: isArabic
                        ? GoogleFonts.cairo(color: Colors.white70)
                        : GoogleFonts.spaceGrotesk(color: Colors.white70),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const Spacer(),
              SvgPicture.asset(
                'assets/images/search.svg',
                width: 20.w,
                height: 20.h,
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        // Bulk Export button.
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 36, 50, 69),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            fixedSize: Size(150.w, 55.h),
            elevation: 1,
          ),
          onPressed: () {
            // Retrieve filtered products from the table using the GlobalKey.
            final productsToExport =
                _tableKey.currentState?.filteredProducts ?? [];

            showDialog(
              context: context,
              builder: (context) => ExportPopUp(products: productsToExport),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.bulkExport,
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
      ],
    );
  }

  // Build controls for Requested Products view
  Widget _buildRequestedProductsControls(List<String> requestFilters) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Row(
      children: [
        // "Requested Products" text.
        Text(
          l10n.requestedProducts,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
        ),
        SizedBox(width: 24.w),
        // Container for filter chips.
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 36, 50, 69),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            children: [
              _buildFilterChip(requestFilters[0], 0, true),
              SizedBox(width: 8.w),
              _buildFilterChip(requestFilters[1], 1, true),
              SizedBox(width: 8.w),
              _buildFilterChip(requestFilters[2], 2, true),
              SizedBox(width: 8.w),
              _buildFilterChip(requestFilters[3], 3, true),
            ],
          ),
        ),
        const Spacer(),
        Container(
          width: 300.w,
          height: 55.h,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 36, 50, 69),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120.w,
                child: TextField(
                  onChanged: _updateSearchQuery,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.white)
                      : GoogleFonts.spaceGrotesk(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    hintStyle: isArabic
                        ? GoogleFonts.cairo(color: Colors.white70)
                        : GoogleFonts.spaceGrotesk(color: Colors.white70),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const Spacer(),
              SvgPicture.asset(
                'assets/images/search.svg',
                width: 20.w,
                height: 20.h,
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        // Refresh button for requested products
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 36, 50, 69),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            fixedSize: Size(150.w, 55.h),
            elevation: 1,
          ),
          onPressed: () {
            // Refresh the requested products table
            _requestTableKey.currentState?.refreshProducts();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 20.sp,
                color: const Color.fromARGB(255, 105, 123, 123),
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.refresh,
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
      ],
    );
  }
}
