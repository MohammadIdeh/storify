// lib/supplier/widgets/SupplierProducts.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final List<String> _filterOptions = ["All", "Active", "Not Active"];
  final List<String> _requestedFilterOptions = [
    "All",
    "Pending",
    "Accepted",
    "Declined"
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileAndSupplierId();
  }

  Future<void> _loadProfileAndSupplierId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
      supplierId = prefs.getInt('supplierId');
    });
    print(
        '📦 Loaded supplierId: $supplierId and profilePic: $profilePictureUrl');
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
                const SupplierOrders(),
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

  void _updateSearchQuery(String query) {
    setState(() {
      if (_showRequestedProducts) {
        _requestedSearchQuery = query;
      } else {
        _searchQuery = query;
      }
    });
  }

  void _onProductAdded(Map<String, dynamic> newProduct) {
    setState(() {
      _showAddProductForm = false;
    });

    print('Product added, refreshing tables after delay...');

    // Increase the delay to 2 seconds to ensure API has time to process
    Future.delayed(const Duration(milliseconds: 2000), () {
      // Refresh product tables
      if (_productsTableKey.currentState != null) {
        _productsTableKey.currentState!.refreshProducts();
        print('Products table refresh called');
      } else {
        print('Products table state is null, cannot refresh');
      }

      // Also refresh requested products table
      if (_requestedProductsTableKey.currentState != null) {
        _requestedProductsTableKey.currentState!.refreshProducts();
        print('Requested products table refresh called');
      } else {
        print('Requested products table state is null, cannot refresh');
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product added successfully'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3), // Increase duration
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                "Product Management",
                style: GoogleFonts.spaceGrotesk(
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
                    label: "Products",
                    isSelected: !_showRequestedProducts,
                    onPressed: () {
                      setState(() {
                        _showRequestedProducts = false;
                      });
                    },
                  ),
                  SizedBox(width: 16.w),
                  _buildTabButton(
                    label: "Requested Products",
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
    );
  }

  // Tab button for switching between products and requested products
  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
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
        style: GoogleFonts.spaceGrotesk(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter and Search Row
        Row(
          children: [
            Text(
              "Products list",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 25.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 10.w,
            ),
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
                    padding: EdgeInsets.only(right: 8.w),
                    child: _buildFilterChip(_filterOptions[index], index,
                        isRequestedProducts: false),
                  ),
                ),
              ),
            ),
            Spacer(),
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
                    'Add Product',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 105, 123, 123),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 15.w,
            ),
            Container(
              width: 300.w,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextField(
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                ),
                decoration: InputDecoration(
                  hintText: "Search Product by name or id",
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white30,
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter and Search Row
        Row(
          children: [
            Text(
              "Requested products",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 25.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 10.w,
            ),
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
                    padding: EdgeInsets.only(right: 8.w),
                    child: _buildFilterChip(
                        _requestedFilterOptions[index], index,
                        isRequestedProducts: true),
                  ),
                ),
              ),
            ),
            Spacer(),
            Container(
              width: 300.w,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextField(
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                ),
                decoration: InputDecoration(
                  hintText: "Search request by name or id",
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white30,
                  ),
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
          style: GoogleFonts.spaceGrotesk(
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
