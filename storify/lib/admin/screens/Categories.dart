// categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/navigationBar.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/widgets/categoryWidgets/Categoriestable.dart';
import 'package:storify/admin/widgets/categoryWidgets/CategoryProductsRow.dart';
import 'package:storify/admin/widgets/categoryWidgets/addCatPanel.dart';
import 'package:storify/admin/widgets/categoryWidgets/model.dart'; // Contains CategoryItem and ProductDetail

enum PanelType { addCat, products }

/// Holds data about a currently opened panel.
class PanelDescriptor {
  final PanelType type;
  final String? categoryName; // used if type == products
  PanelDescriptor({required this.type, this.categoryName});
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Navigation bar state.
  int _currentIndex = 2;

  // Filter state for chips.
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: UnActive
  final List<String> _filters = ["All", "Active", "UnActive"];

  // Fake master list of categories.
  final List<CategoryItem> _allCategories = [
    CategoryItem(
      image: 'assets/images/image3.png',
      name: 'Fruits',
      products: 5,
      isActive: true,
    ),
    CategoryItem(
      image: 'assets/images/image3.png',
      name: 'Vegetables',
      products: 4,
      isActive: true,
    ),
    CategoryItem(
      image: 'assets/images/image3.png',
      name: 'Candy and Chocolate',
      products: 3,
      isActive: false,
    ),
    CategoryItem(
      image: 'assets/images/image3.png',
      name: 'Snacks',
      products: 6,
      isActive: true,
    ),
    CategoryItem(
      image: 'assets/images/image3.png',
      name: 'Dairy',
      products: 2,
      isActive: false,
    ),
    CategoryItem(
      image: 'assets/images/image3.png',
      name: 'Beverages',
      products: 4,
      isActive: true,
    ),
    CategoryItem(
      image: 'assets/images/image3.png',
      name: 'Meat & Poultry',
      products: 3,
      isActive: false,
    ),
  ];

  // Fake product details for each category in a map.
  final Map<String, List<ProductDetail>> _categoryToProducts = {
    'Fruits': [
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Apple",
          costPrice: 0.50,
          sellingPrice: 0.80,
          myPrice: 2.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Madsngo",
          costPrice: 1.00,
          sellingPrice: 1.40,
          myPrice: 3.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Mango",
          costPrice: 1.00,
          sellingPrice: 1.40,
          myPrice: 3.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Orange",
          costPrice: 0.60,
          sellingPrice: 0.90,
          myPrice: 2.5),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Mangdo",
          costPrice: 1.00,
          sellingPrice: 1.40,
          myPrice: 3.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Banana",
          costPrice: 0.30,
          sellingPrice: 0.60,
          myPrice: 1.5),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Grapes",
          costPrice: 0.80,
          sellingPrice: 1.20,
          myPrice: 2.0),
    ],
    'Vegetables': [
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Carrot",
          costPrice: 0.40,
          sellingPrice: 0.75,
          myPrice: 1.5),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Broccoli",
          costPrice: 0.90,
          sellingPrice: 1.30,
          myPrice: 2.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Spinach",
          costPrice: 0.70,
          sellingPrice: 1.00,
          myPrice: 1.8),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Pepper",
          costPrice: 0.60,
          sellingPrice: 1.00,
          myPrice: 1.7),
    ],
    'Candy and Chocolate': [
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Gummy Bears",
          costPrice: 0.70,
          sellingPrice: 1.10,
          myPrice: 2.5),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Lollipop",
          costPrice: 0.30,
          sellingPrice: 0.60,
          myPrice: 1.2),
    ],
    'Snacks': [
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Chips",
          costPrice: 1.00,
          sellingPrice: 1.50,
          myPrice: 3.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Pretzels",
          costPrice: 0.80,
          sellingPrice: 1.20,
          myPrice: 2.5),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Popcorn",
          costPrice: 0.50,
          sellingPrice: 0.90,
          myPrice: 2.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Nuts",
          costPrice: 1.20,
          sellingPrice: 1.80,
          myPrice: 3.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Granola Bar",
          costPrice: 0.60,
          sellingPrice: 1.00,
          myPrice: 2.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Crackers",
          costPrice: 0.70,
          sellingPrice: 1.10,
          myPrice: 2.5),
    ],
    'Dairy': [
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Milk",
          costPrice: 1.00,
          sellingPrice: 1.50,
          myPrice: 3.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Cheese",
          costPrice: 2.00,
          sellingPrice: 2.80,
          myPrice: 4.0),
    ],
    'Beverages': [
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Water",
          costPrice: 0.30,
          sellingPrice: 0.50,
          myPrice: 1.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Juice",
          costPrice: 0.90,
          sellingPrice: 1.40,
          myPrice: 2.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Soda",
          costPrice: 0.80,
          sellingPrice: 1.20,
          myPrice: 2.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Coffee",
          costPrice: 1.20,
          sellingPrice: 1.80,
          myPrice: 3.0),
    ],
    'Meat & Poultry': [
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Chicken",
          costPrice: 3.00,
          sellingPrice: 4.50,
          myPrice: 8.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Beef",
          costPrice: 5.00,
          sellingPrice: 7.00,
          myPrice: 12.0),
      ProductDetail(
          image: 'assets/images/image3.png',
          name: "Pork",
          costPrice: 4.00,
          sellingPrice: 6.00,
          myPrice: 10.0),
    ],
  };
  final List<PanelDescriptor> _openedPanels = [];

  // Filter the master category list based on the selected filter chip.
  List<CategoryItem> get _filteredCategories {
    if (_selectedFilterIndex == 1) {
      return _allCategories.where((cat) => cat.isActive).toList();
    } else if (_selectedFilterIndex == 2) {
      return _allCategories.where((cat) => !cat.isActive).toList();
    } else {
      return _allCategories;
    }
  }

  CategoryItem? _selectedCategory;

  // This callback updates the product list for a category.
  void _updateProductsForCategory(
      String categoryName, List<ProductDetail> updatedList) {
    setState(() {
      // Update the Map.
      _categoryToProducts[categoryName] = updatedList;
      // Update category product count in _allCategories.
      for (var cat in _allCategories) {
        if (cat.name == categoryName) {
          cat.products = updatedList.length;
        }
      }
    });
  }

  void _handleAddCategoryClicked() {
    setState(() {
      // Remove any existing addCat panel so we can place it at the bottom
      _openedPanels.removeWhere((p) => p.type == PanelType.addCat);
      _openedPanels.add(PanelDescriptor(type: PanelType.addCat));
    });
  }

  void _publishCategory(String categoryName, bool isActive, String image) {
    setState(() {
      final newCat = CategoryItem(
        image: image, // now using the provided image
        name: categoryName,
        products: 0,
        isActive: isActive,
      );
      _allCategories.add(newCat);
      _categoryToProducts[categoryName] = [];
      _openedPanels.removeWhere((p) => p.type == PanelType.addCat);
    });
  }

  void _handleCategorySelected(CategoryItem cat) {
    // If there's already a PanelDescriptor of type products for this cat,
    // remove it so we can reinsert it at the bottom of the list.
    setState(() {
      _openedPanels.removeWhere(
        (p) => p.type == PanelType.products && p.categoryName == cat.name,
      );
      // Add a new panel for this category.
      _openedPanels.add(
        PanelDescriptor(type: PanelType.products, categoryName: cat.name),
      );
    });
  }

  Widget _buildFilterChip(String label, int index) {
    final bool isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
          _selectedCategory = null; // clear selected category on filter change.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: MyNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Navigation logic:
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const DashboardScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 700),
                  ),
                );
                break;
              case 1:
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const Productsscreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 700),
                  ),
                );
                break;
              case 2:
                // Current Categories screen.
                break;
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(45.w, 20.h, 45.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: "Category" title, Filter chips, "Add Category" button
              Row(
                children: [
                  Text(
                    "Category",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 246, 246, 246),
                    ),
                  ),
                  SizedBox(width: 20.h),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 50, 69),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    child: Row(
                      children: [
                        _buildFilterChip(_filters[0], 0),
                        SizedBox(width: 8.w),
                        _buildFilterChip(_filters[1], 1),
                        SizedBox(width: 8.w),
                        _buildFilterChip(_filters[2], 2),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      fixedSize: Size(190.w, 50.h),
                      elevation: 1,
                    ),
                    onPressed: _handleAddCategoryClicked,
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/addCat.svg',
                          width: 18.w,
                          height: 18.h,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Add Category',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              // Table of categories
              Categoriestable(
                categories: _filteredCategories,
                onCategorySelected: _handleCategorySelected,
              ),
              SizedBox(height: 30.h),
              // Build the panels in the order they were opened
              for (final panel in _openedPanels) ...[
                if (panel.type == PanelType.addCat)
                  AddCategoryPanel(
                    onPublish: (catName, isActive, image) {
                      _publishCategory(catName, isActive, image);
                    },
                    onCancel: () {
                      setState(() {
                        _openedPanels
                            .removeWhere((p) => p.type == PanelType.addCat);
                      });
                    },
                  ),
                if (panel.type == PanelType.products)
                  CategoryProductsRow(
                    categoryName: panel.categoryName!,
                    products: List<ProductDetail>.from(
                        _categoryToProducts[panel.categoryName] ?? []),
                    onClose: () {
                      setState(() {
                        _openedPanels.remove(panel);
                      });
                    },
                    onProductDelete: (deletedProduct) {
                      final currentList =
                          _categoryToProducts[panel.categoryName] ??
                              <ProductDetail>[];
                      currentList.remove(deletedProduct);
                      _updateProductsForCategory(
                          panel.categoryName!, currentList);
                    },
                  ),
              ],
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
