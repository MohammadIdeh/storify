// categoriestable.dart
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/categoryWidgets/model.dart'; // Add this import for CategoryItem class
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class Categoriestable extends StatefulWidget {
  final List<CategoryItem> categories; // Provided list from parent.
  final ValueChanged<CategoryItem> onCategorySelected;
  final Function(int categoryID, String newStatus)?
      onCategoryUpdated; // Add this callback

  const Categoriestable({
    Key? key,
    required this.categories,
    required this.onCategorySelected,
    this.onCategoryUpdated, // Add this parameter
  }) : super(key: key);

  @override
  State<Categoriestable> createState() => _CategoriestableState();
}

class _CategoriestableState extends State<Categoriestable> {
  // Pagination settings.
  final int _itemsPerPage = 5;
  int _currentPage = 1;

  // Keep track of categories being updated
  Set<int> _updatingCategories = {};

  Future<void> _updateCategoryStatus(int categoryID, bool isActive) async {
    // Add this category to updating set
    setState(() {
      _updatingCategories.add(categoryID);
    });

    try {
      // Get token
      final token = await AuthService.getToken();
      if (token == null) {
        debugPrint('No token available for category status update');
        if (mounted) {
          final l10n =
              Localizations.of<AppLocalizations>(context, AppLocalizations)!;
          _showError(l10n.authenticationRequired);
        }
        return;
      }

      // Prepare the new status
      final newStatus = isActive ? 'Active' : 'NotActive';

      // Perform API request to update status
      final response = await http.put(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/category/$categoryID'),
        headers: {
          'Content-Type': 'application/json',
          'token': token // Use 'token' header as per API requirement
        },
        body: json.encode({'status': newStatus}),
      );

      debugPrint('API Response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Success - update the parent state through callback
        if (widget.onCategoryUpdated != null) {
          widget.onCategoryUpdated!(categoryID, newStatus);
        }
        debugPrint('Category status updated successfully');
      } else {
        debugPrint('Failed to update category status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');

        // Try to parse error message
        try {
          final responseData = json.decode(response.body);
          if (mounted) {
            final l10n =
                Localizations.of<AppLocalizations>(context, AppLocalizations)!;
            _showError(
                responseData['message'] ?? l10n.failedToUpdateCategoryStatus);
          }
        } catch (e) {
          if (mounted) {
            final l10n =
                Localizations.of<AppLocalizations>(context, AppLocalizations)!;
            _showError(
                '${l10n.failedToUpdateCategoryStatus}: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating category status: $e');
      if (mounted) {
        final l10n =
            Localizations.of<AppLocalizations>(context, AppLocalizations)!;
        _showError('${l10n.networkError}: $e');
      }
    } finally {
      // Remove from updating set
      if (mounted) {
        setState(() {
          _updatingCategories.remove(categoryID);
        });
      }
    }
  }

  void _showError(String message) {
    final isArabic = LocalizationHelper.isArabic(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: isArabic
                ? GoogleFonts.cairo(color: Colors.white)
                : GoogleFonts.spaceGrotesk(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    final totalItems = widget.categories.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: LayoutBuilder(
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
                      headingTextStyle: isArabic
                          ? GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 19.sp,
                              fontWeight: FontWeight.bold,
                            )
                          : GoogleFonts.spaceGrotesk(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 19.sp,
                              fontWeight: FontWeight.bold,
                            ),
                      dataTextStyle: isArabic
                          ? GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 17.sp,
                            )
                          : GoogleFonts.spaceGrotesk(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 17.sp,
                            ),
                      columns: [
                        DataColumn(
                          label: Text(
                            l10n.imageAndName,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            l10n.products,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            l10n.status,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ],
                      rows: _visibleCategories.map((cat) {
                        final isUpdating =
                            _updatingCategories.contains(cat.categoryID);

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
                                  if (!isRtl) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: Image.network(
                                        cat.image,
                                        width: 40.w,
                                        height: 40.h,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 40.w,
                                            height: 40.h,
                                            color: Colors.grey,
                                            child: Icon(
                                                Icons.image_not_supported,
                                                size: 20.sp),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                  ],
                                  Expanded(
                                    child: Text(
                                      cat.categoryName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: isArabic
                                          ? GoogleFonts.cairo(
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.w200,
                                              color: Colors.white,
                                            )
                                          : GoogleFonts.spaceGrotesk(
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.w200,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                  if (isRtl) ...[
                                    SizedBox(width: 10.w),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: Image.network(
                                        cat.image,
                                        width: 40.w,
                                        height: 40.h,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 40.w,
                                            height: 40.h,
                                            color: Colors.grey,
                                            child: Icon(
                                                Icons.image_not_supported,
                                                size: 20.sp),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                "${cat.products}",
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.w200,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.w200,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                            DataCell(
                              Container(
                                width: 80,
                                alignment: Alignment.center,
                                child: isUpdating
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: const Color.fromARGB(
                                              255, 105, 65, 198),
                                        ),
                                      )
                                    : GestureDetector(
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
                                            activeColor: const Color.fromARGB(
                                                255, 105, 65, 198),
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
                  padding:
                      EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: isRtl
                        ? [
                            // RTL: Start with Next button, then pages, then Previous
                            IconButton(
                              icon: Icon(
                                  Icons.chevron_left, // Next in RTL (goes left)
                                  size: 20.sp,
                                  color: Colors.white70),
                              onPressed: _currentPage < totalPages
                                  ? () {
                                      setState(() {
                                        _currentPage++;
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
                                        ? const Color.fromARGB(
                                            255, 105, 65, 198)
                                        : Colors.transparent,
                                    side: BorderSide(
                                      color:
                                          const Color.fromARGB(255, 34, 53, 62),
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
                                    style: GoogleFonts.cairo(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            IconButton(
                              icon: Icon(
                                  Icons
                                      .chevron_right, // Previous in RTL (goes right)
                                  size: 20.sp,
                                  color: Colors.white70),
                              onPressed: _currentPage > 1
                                  ? () {
                                      setState(() {
                                        _currentPage--;
                                      });
                                    }
                                  : null,
                            ),
                          ]
                        : [
                            // LTR: Previous, then pages, then Next (original order)
                            IconButton(
                              icon: Icon(
                                  Icons
                                      .chevron_left, // Previous in LTR (goes left)
                                  size: 20.sp,
                                  color: Colors.white70),
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
                                        ? const Color.fromARGB(
                                            255, 105, 65, 198)
                                        : Colors.transparent,
                                    side: BorderSide(
                                      color:
                                          const Color.fromARGB(255, 34, 53, 62),
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
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            IconButton(
                              icon: Icon(
                                  Icons
                                      .chevron_right, // Next in LTR (goes right)
                                  size: 20.sp,
                                  color: Colors.white70),
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
      ),
    );
  }
}
