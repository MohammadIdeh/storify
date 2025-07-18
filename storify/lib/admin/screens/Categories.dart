// categories_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/admin/screens/track.dart';
import 'package:storify/admin/widgets/categoryWidgets/Categoriestable.dart';
import 'package:storify/admin/widgets/categoryWidgets/CategoryProductsRow.dart';
import 'package:storify/admin/widgets/categoryWidgets/addCatPanel.dart';
import 'package:storify/admin/widgets/categoryWidgets/model.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

enum PanelType { addCat, products }

/// Holds data about a currently opened panel.
class PanelDescriptor {
  final PanelType type;
  final String? categoryName; // used if type == products
  final int? categoryID; // Added to store the category ID
  final String? description; // Add this line for description

  PanelDescriptor({
    required this.type,
    this.categoryName,
    this.categoryID,
    this.description, // Add this parameter
  });
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Navigation bar state.
  int _currentIndex = 2;
  String? profilePictureUrl;

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  // Filter state for chips.
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: UnActive

  // API data state
  bool _isLoading = false;
  String? _error;
  bool _hasInitialized = false; // Track if we've made the initial fetch

  // List of categories from API
  List<CategoryItem> _allCategories = [];

  // Map to store products for each category by ID
  Map<int, List<ProductDetail>> _categoryProductsMap = {};

  // Track which categories are currently loading products
  Map<int, bool> _loadingProductsForCategory = {};

  // Track any errors loading products
  Map<int, String?> _productLoadErrors = {};

  final List<PanelDescriptor> _openedPanels = [];

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _fetchCategories();
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://finalproject-a5ls.onrender.com/category/getall'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['message'] == "Categories retrieved successfully") {
          final categoriesJson = data['categories'] as List;

          setState(() {
            _allCategories = categoriesJson
                .map((json) => CategoryItem.fromJson(json))
                .toList();
            _isLoading = false;
          });

          // Add this - fetch product counts for all categories
          for (var category in _allCategories) {
            _fetchProductsForCategory(category.categoryID);
          }
        } else {
          setState(() {
            _error = 'Failed to load categories: ${data['message']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load categories: HTTP ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching categories: $e';
        _isLoading = false;
      });
    }
  }

  // New method to fetch products for a specific category
  Future<void> _fetchProductsForCategory(int categoryID) async {
    // Mark this category as loading products
    setState(() {
      _loadingProductsForCategory[categoryID] = true;
      _productLoadErrors[categoryID] = null; // Clear any previous errors
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/category/$categoryID/products'),
      );

      debugPrint('API Response [GET products]: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data.containsKey('products')) {
          final productsJson = data['products'] as List;
          debugPrint(
              'Found ${productsJson.length} products for category $categoryID');

          final products = productsJson.map((json) {
            // Add debugging to see each product's ID
            debugPrint('Product JSON: $json');
            final product = ProductDetail.fromJson(json);
            debugPrint('Parsed product ID: ${product.productID}');
            return product;
          }).toList();

          setState(() {
            _categoryProductsMap[categoryID] = products;
            _loadingProductsForCategory[categoryID] = false;

            // Update product count in category list
            for (var cat in _allCategories) {
              if (cat.categoryID == categoryID) {
                cat.products = products.length;
              }
            }
          });
        } else {
          debugPrint('Invalid response format: $data');
          setState(() {
            _categoryProductsMap[categoryID] = [];
            _loadingProductsForCategory[categoryID] = false;
            _productLoadErrors[categoryID] = 'Invalid response format';
          });
        }
      } else {
        debugPrint('Failed to load products: HTTP ${response.statusCode}');
        setState(() {
          _categoryProductsMap[categoryID] = [];
          _loadingProductsForCategory[categoryID] = false;
          _productLoadErrors[categoryID] =
              'Failed to load products: HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() {
        _categoryProductsMap[categoryID] = [];
        _loadingProductsForCategory[categoryID] = false;
        _productLoadErrors[categoryID] = 'Error fetching products: $e';
      });
    }
  }

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
      int categoryID, List<ProductDetail> updatedList) {
    setState(() {
      // Update the Map.
      _categoryProductsMap[categoryID] = updatedList;

      // Update category product count in _allCategories.
      for (var cat in _allCategories) {
        if (cat.categoryID == categoryID) {
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

  void _publishCategory(
      String categoryName, bool isActive, String image, String description) {
    // In a real app, this would call an API to create the category
    // For now, we'll just add it locally and refresh the list
    setState(() {
      _openedPanels.removeWhere((p) => p.type == PanelType.addCat);
    });

    // Refresh the category list after publishing
    _fetchCategories();
  }

  // Add this callback to handle category updates from table
  void _updateCategoryInList(int categoryID, String newStatus) {
    setState(() {
      for (var cat in _allCategories) {
        if (cat.categoryID == categoryID) {
          cat.status = newStatus;
          break;
        }
      }
    });
  }

  // In categories_screen.dart, update _handleCategorySelected method:
  void _handleCategorySelected(CategoryItem cat) {
    setState(() {
      _openedPanels.removeWhere(
        (p) => p.type == PanelType.products && p.categoryID == cat.categoryID,
      );

      // Add a new panel for this category, including the description
      _openedPanels.add(
        PanelDescriptor(
          type: PanelType.products,
          categoryName: cat.categoryName,
          categoryID: cat.categoryID,
          description: cat.description, // Pass the description
        ),
      );

      // Fetch products for this category if not already loaded
      if (!_categoryProductsMap.containsKey(cat.categoryID)) {
        _fetchProductsForCategory(cat.categoryID);
      }
    });
  }

  Widget _buildFilterChip(String label, int index) {
    final isArabic = LocalizationHelper.isArabic(context);
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

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Get filter labels based on language
    final List<String> _filters = [l10n.all, l10n.active, l10n.notActive];

    // Set localized error messages if needed
    String? localizedError;
    if (_error != null) {
      if (_error!.contains('Failed to load categories')) {
        localizedError =
            l10n.failedToLoadCategories + ': ' + _error!.split(': ').last;
      } else if (_error!.contains('Error fetching categories')) {
        localizedError =
            l10n.errorFetchingCategories + ': ' + _error!.split(': ').last;
      } else {
        localizedError = _error;
      }
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 29, 41, 57),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: MyNavigationBar(
            currentIndex: _currentIndex,
            profilePictureUrl:
                profilePictureUrl, // Pass the profile picture URL here
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              // Navigation logic:
              switch (index) {
                case 0:
                  Navigator.pushNamed(context, '/admin/dashboard');
                  break;
                case 1:
                  Navigator.pushNamed(context, '/admin/products');
                  break;
                case 2:
                  // Current Categories screen - no navigation needed
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
                      l10n.category,
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
                    SizedBox(width: 20.w),
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
                        backgroundColor:
                            const Color.fromARGB(255, 105, 65, 198),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        fixedSize: Size(190.w, 50.h),
                        elevation: 1,
                      ),
                      onPressed: _handleAddCategoryClicked,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isRtl) ...[
                            SvgPicture.asset(
                              'assets/images/addCat.svg',
                              width: 18.w,
                              height: 18.h,
                            ),
                            SizedBox(width: 12.w),
                          ],
                          Text(
                            l10n.addCategory,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                          ),
                          if (isRtl) ...[
                            SizedBox(width: 12.w),
                            SvgPicture.asset(
                              'assets/images/addCat.svg',
                              width: 18.w,
                              height: 18.h,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),

                // Show loading, error, or data
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      color: const Color.fromARGB(255, 105, 65, 198),
                    ),
                  )
                else if (localizedError != null)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          localizedError,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  fontSize: 16.sp,
                                  color: Colors.red,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  fontSize: 16.sp,
                                  color: Colors.red,
                                ),
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: _fetchCategories,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 105, 65, 198),
                          ),
                          child: Text(
                            l10n.retry,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Table of categories
                  Categoriestable(
                    categories: _filteredCategories,
                    onCategorySelected: _handleCategorySelected,
                    onCategoryUpdated:
                        _updateCategoryInList, // Add this callback
                  ),

                SizedBox(height: 30.h),
                // Build the panels in the order they were opened
                for (final panel in _openedPanels) ...[
                  if (panel.type == PanelType.addCat)
                    AddCategoryPanel(
                      onPublish: (catName, isActive, image, description) {
                        _publishCategory(catName, isActive, image, description);
                      },
                      onCancel: () {
                        setState(() {
                          _openedPanels
                              .removeWhere((p) => p.type == PanelType.addCat);
                        });
                      },
                    ),
                  if (panel.type == PanelType.products &&
                      panel.categoryID != null)
                    _buildCategoryProductsPanel(panel),
                ],
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryProductsPanel(PanelDescriptor panel) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final categoryID = panel.categoryID!;
    final categoryName = panel.categoryName ?? l10n.category;
    final description = panel.description; // Get the description

    // Check if products are still loading
    if (_loadingProductsForCategory[categoryID] == true) {
      return Container(
        margin: EdgeInsets.only(top: 20.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    fixedSize: Size(100.w, 50.h),
                  ),
                  onPressed: () {
                    setState(() {
                      _openedPanels.remove(panel);
                    });
                  },
                  child: Text(
                    l10n.close,
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
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: const Color.fromARGB(255, 105, 65, 198),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.loadingProducts,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16.sp,
                          )
                        : GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      );
    }

    // Check if there was an error loading products
    if (_productLoadErrors[categoryID] != null) {
      // Get localized error message
      String localizedProductError = _productLoadErrors[categoryID]!;
      if (localizedProductError.contains('Invalid response format')) {
        localizedProductError = l10n.invalidResponseFormat;
      } else if (localizedProductError.contains('Failed to load products')) {
        localizedProductError = l10n.invalidResponseFormat +
            ': ' +
            localizedProductError.split(': ').last;
      } else if (localizedProductError.contains('Error fetching products')) {
        localizedProductError = l10n.errorFetchingProducts +
            ': ' +
            localizedProductError.split(': ').last;
      }

      return Container(
        margin: EdgeInsets.only(top: 20.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    fixedSize: Size(100.w, 50.h),
                  ),
                  onPressed: () {
                    setState(() {
                      _openedPanels.remove(panel);
                    });
                  },
                  child: Text(
                    l10n.close,
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
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      localizedProductError,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              color: Colors.red,
                              fontSize: 14.sp,
                            )
                          : GoogleFonts.spaceGrotesk(
                              color: Colors.red,
                              fontSize: 14.sp,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                _fetchProductsForCategory(categoryID);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                l10n.tryAgain,
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
            ),
            SizedBox(height: 32.h),
          ],
        ),
      );
    }

    // Normal case: display the products
    final products = _categoryProductsMap[categoryID] ?? [];

    // Get current category image
    String? currentImage;
    for (var cat in _allCategories) {
      if (cat.categoryID == categoryID) {
        currentImage = cat.image;
        break;
      }
    }

    return CategoryProductsRow(
      categoryName: categoryName,
      categoryID: categoryID, // Pass the categoryID to the component
      description: description, // Pass the description
      currentImage: currentImage, // Pass the current image
      products: products,
      onClose: () {
        setState(() {
          _openedPanels.remove(panel);
        });
      },
      onProductDelete: (deletedProduct) {
        final currentList =
            _categoryProductsMap[categoryID] ?? <ProductDetail>[];
        currentList.remove(deletedProduct);
        _updateProductsForCategory(categoryID, currentList);
      },
      onCategoryUpdate: (updatedCategory) {
        // Handle category update callback
        setState(() {
          for (var cat in _allCategories) {
            if (cat.categoryID == categoryID) {
              cat.categoryName = updatedCategory.categoryName;
              cat.description = updatedCategory.description;
              cat.status = updatedCategory.status;
              cat.image = updatedCategory.image;
              break;
            }
          }
        });

        // Update the panel with new data
        final panelIndex = _openedPanels.indexWhere(
            (p) => p.type == PanelType.products && p.categoryID == categoryID);
        if (panelIndex != -1) {
          _openedPanels[panelIndex] = PanelDescriptor(
            type: PanelType.products,
            categoryName: updatedCategory.categoryName,
            categoryID: categoryID,
            description: updatedCategory.description,
          );
        }
      },
    );
  }
}
