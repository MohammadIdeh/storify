// categoriestable.dart
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/categoryWidgets/model.dart'; // Add this import for CategoryItem class

class Categoriestable extends StatefulWidget {
  final List<CategoryItem> categories; // Provided list from parent.
  final ValueChanged<CategoryItem> onCategorySelected;
  const Categoriestable({
    Key? key,
    required this.categories,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<Categoriestable> createState() => _CategoriestableState();
}

class _CategoriestableState extends State<Categoriestable> {
  // Pagination settings.
  final int _itemsPerPage = 5;
  int _currentPage = 1;
  Future<void> _updateCategoryStatus(int categoryID, bool isActive) async {
    // Store current categories state to allow modification
    List<CategoryItem> currentCategories = List.from(widget.categories);

    // Find the category to update
    int categoryIndex = -1;
    for (int i = 0; i < currentCategories.length; i++) {
      if (currentCategories[i].categoryID == categoryID) {
        categoryIndex = i;
        break;
      }
    }

    if (categoryIndex == -1) return; // Category not found

    // Store original status for potential revert
    final String originalStatus = currentCategories[categoryIndex].status;

    // Update local state immediately
    setState(() {
      // Create a copy of the category with updated status
      currentCategories[categoryIndex].status =
          isActive ? 'Active' : 'NotActive';
    });

    try {
      // Get token
      final token = await AuthService.getToken();
      if (token == null) {
        print('No token available for category status update');

        // Revert on error
        setState(() {
          currentCategories[categoryIndex].status = originalStatus;
        });
        return;
      }

      // Perform API request to update status
      final response = await http.put(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/category/$categoryID'),
        headers: {'Content-Type': 'application/json', 'token': token},
        body: json.encode({'status': isActive ? 'Active' : 'NotActive'}),
      );

      if (response.statusCode != 200) {
        print('Failed to update category status: ${response.statusCode}');
        print('Response: ${response.body}');

        // If the API call fails, revert to original status
        setState(() {
          currentCategories[categoryIndex].status = originalStatus;
        });
      }
    } catch (e) {
      print('Error updating category status: $e');

      // Revert on error
      setState(() {
        currentCategories[categoryIndex].status = originalStatus;
      });
    }
  }

  List<CategoryItem> get _visibleCategories {
    final totalItems = widget.categories.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > totalItems
        ? totalItems
        : startIndex + _itemsPerPage;

    if (startIndex >= totalItems) {
      return [];
    }

    return widget.categories.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.categories.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) => Colors.transparent,
                    ),
                    showCheckboxColumn: false,
                    headingRowColor:
                        WidgetStateProperty.all<Color>(headingColor),
                    border: TableBorder(
                      top: dividerSide,
                      bottom: dividerSide,
                      left: dividerSide,
                      right: dividerSide,
                      horizontalInside: dividerSide2,
                      verticalInside: dividerSide2,
                    ),
                    columnSpacing: 20.w,
                    dividerThickness: 0,
                    headingTextStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 19.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 17.sp,
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          "Image & Name",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Products",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Status",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    rows: _visibleCategories.map((cat) {
                      return DataRow(
                        onSelectChanged: (selected) {
                          if (selected == true) {
                            widget.onCategorySelected(cat);
                          }
                        },
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Image.network(
                                    cat.image,
                                    width: 40.w,
                                    height: 40.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 40.w,
                                        height: 40.h,
                                        color: Colors.grey,
                                        child: Icon(Icons.image_not_supported,
                                            size: 20.sp),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    cat.categoryName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              "${cat.products}",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          DataCell(
                            // Wrap in a Container to increase tap area
                            Container(
                              width: 60, // Give it some width
                              alignment: Alignment.center,
                              child: GestureDetector(
                                // Add explicit GestureDetector to handle taps
                                onTap: () {
                                  // Toggle status directly on tap
                                  final newValue = !cat.isActive;
                                  _updateCategoryStatus(
                                      cat.categoryID, newValue);
                                },
                                child: Transform.scale(
                                  scale: 0.7,
                                  child: CupertinoSwitch(
                                    value: cat.isActive,
                                    activeColor:
                                        const Color.fromARGB(255, 105, 65, 198),
                                    // Keep this for when the switch itself is interacted with
                                    onChanged: (value) {
                                      _updateCategoryStatus(
                                          cat.categoryID, value);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          size: 20.sp, color: Colors.white70),
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                          : null,
                    ),
                    ...List.generate(totalPages, (index) {
                      final pageIndex = index + 1;
                      final bool isSelected = pageIndex == _currentPage;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected
                                ? const Color.fromARGB(255, 105, 65, 198)
                                : Colors.transparent,
                            side: BorderSide(
                              color: const Color.fromARGB(255, 34, 53, 62),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 12.h),
                          ),
                          onPressed: () {
                            setState(() {
                              _currentPage = pageIndex;
                            });
                          },
                          child: Text(
                            "$pageIndex",
                            style: GoogleFonts.spaceGrotesk(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                    IconButton(
                      icon: Icon(Icons.arrow_forward,
                          size: 20.sp, color: Colors.white70),
                      onPressed: _currentPage < totalPages
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
