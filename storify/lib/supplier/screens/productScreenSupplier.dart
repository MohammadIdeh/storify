// lib/supplier/widgets/SupplierProducts.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/supplier/screens/ordersScreensSupplier.dart';
import 'package:storify/supplier/widgets/navbar.dart';
import 'package:storify/supplier/widgets/productwidgets/addNewProductWidget.dart';
import 'package:storify/supplier/widgets/productwidgets/products_table_Supplier.dart';

class SupplierProducts extends StatefulWidget {
  const SupplierProducts({super.key});

  @override
  State<SupplierProducts> createState() => _SupplierProductsState();
}

class _SupplierProductsState extends State<SupplierProducts> {
  final _tableKey = GlobalKey<ProductsTableSupplierState>();

  // Bottom navigation index.
  int _currentIndex = 1;
  String? profilePictureUrl;
  int? supplierId;

  bool _isLoading = false;
  int _selectedFilterIndex = 0;
  String _searchQuery = "";
  bool _showAddProductForm = false; // Control visibility of add product form

  final List<String> _filterOptions = ["All", "Active", "Not Active"];

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
      _searchQuery = query;
    });
  }

  void _onProductAdded(Map<String, dynamic> newProduct) {
    setState(() {
      _showAddProductForm = false;
    });

    print('Product added, refreshing table after delay...');

    // Increase the delay to 2 seconds to ensure API has time to process
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_tableKey.currentState != null) {
        _tableKey.currentState!.refreshProducts();
        print('Table refresh called');
      } else {
        print('Table state is null, cannot refresh');
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
              // Orders Header
              Text(
                "Product Management",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24.h),

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
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    child: Row(
                      children: List.generate(
                        _filterOptions.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: _buildFilterChip(_filterOptions[index], index),
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

              // Add the ProductsTableSupplier widget here
              ProductsTableSupplier(
                key: _tableKey,
                selectedFilterIndex: _selectedFilterIndex,
                searchQuery: _searchQuery,
              ),

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

  Widget _buildFilterChip(String label, int index) {
    final bool isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
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
