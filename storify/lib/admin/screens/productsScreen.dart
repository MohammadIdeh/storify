import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/navigationBar.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/widgets/exportPopUp.dart';
import 'package:storify/admin/widgets/longPressDraggable.dart';
import 'package:storify/admin/widgets/productsCards.dart';
import 'package:storify/admin/widgets/productsListable.dart';

class Productsscreen extends StatefulWidget {
  const Productsscreen({super.key});

  @override
  State<Productsscreen> createState() => _ProductsscreenState();
}

class _ProductsscreenState extends State<Productsscreen> {
  int _currentIndex = 1;
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: UnActive
  final List<String> _filters = ["All", "Active", "UnActive"];
  String _searchQuery = "";

  // Create a GlobalKey to access the ProductslistTable state.
  final GlobalKey<ProductslistTableState> _tableKey =
      GlobalKey<ProductslistTableState>();

  // Four ProductsCards in a list.
  final List<Widget> _productCards = [
    ProductsCards(
      title: 'Total Products',
      value: '25,430',
      subtext: '+1.5% Since last week',
      key: UniqueKey(),
    ),
    ProductsCards(
      title: 'New Arrivals',
      value: '5,120',
      subtext: '+2.3% This month',
      key: UniqueKey(),
    ),
    ProductsCards(
      title: 'Out of Stock',
      value: '2,300',
      subtext: '-1.2% Compared to last week',
      key: UniqueKey(),
    ),
    ProductsCards(
      title: 'Total Categories',
      value: '45',
      subtext: 'Stable',
      key: UniqueKey(),
    ),
  ];

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const DashboardScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 1:
        break;
      case 2:
        // Orders
        break;
      case 3:
        // Stores
        break;
      case 4:
        // More
        break;
    }
  }

  /// Builds one toggle chip.
  Widget _buildFilterChip(String label, int index) {
    final bool isSelected = (_selectedFilterIndex == index);
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
              final temp = _productCards[oldIndex];
              _productCards[oldIndex] = _productCards[index];
              _productCards[index] = temp;
            });
          },
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
          onTap: _onNavItemTap,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Products title and Filter button.
              Row(
                children: [
                  Text(
                    "Products",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 246, 246, 246),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 36, 50, 69),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      fixedSize: Size(138.w, 50.h),
                      elevation: 1,
                    ),
                    onPressed: () {},
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/filter.svg',
                          width: 18.w,
                          height: 18.h,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Filter',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 105, 123, 123),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),

              /// --- Draggable ProductsCards (in a single-row Wrap) ---
              LayoutBuilder(
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
                    children: List.generate(_productCards.length, (index) {
                      return _buildDraggableProductCardItem(index, cardWidth);
                    }),
                  );
                },
              ),
              SizedBox(height: 40.h),

              /// --- Row Under the Cards (Product List + Filters + Search + Buttons) ---
              Row(
                children: [
                  // "Product List" text.
                  Text(
                    "Product List",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20.sp,
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
                  // Search box.
                  Container(
                    width: 300.w,
                    height: 55.h,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 50, 69),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 120.w,
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                              ),
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
                          color: Colors.white70,
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
                        builder: (context) =>
                            ExportPopUp(products: productsToExport),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          'Bulk Export',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 105, 123, 123),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              // Pass the search query and filter to the table, and assign the GlobalKey.
              ProductslistTable(
                key: _tableKey,
                selectedFilterIndex: _selectedFilterIndex,
                searchQuery: _searchQuery,
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
