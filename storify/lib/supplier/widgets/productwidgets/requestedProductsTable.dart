import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

// Model for requested products
class RequestedProductModel {
  final int id;
  final String name;
  final String? image;
  final String categoryName;
  final String status;
  final double costPrice;
  final DateTime createdAt;
  final String? adminNote;

  RequestedProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.categoryName,
    required this.status,
    required this.costPrice,
    required this.createdAt,
    this.adminNote,
  });

  // Factory constructor to create a RequestedProductModel from JSON
  factory RequestedProductModel.fromJson(Map<String, dynamic> json) {
    return RequestedProductModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      categoryName: json['categoryName'],
      status: json['status'],
      costPrice: double.parse(json['costPrice']),
      createdAt: DateTime.parse(json['createdAt']),
      adminNote: json['adminNote'],
    );
  }
}

class RequestedProductsTable extends StatefulWidget {
  final int selectedFilterIndex; // 0: Pending, 1: Accepted, 2: Declined
  final String searchQuery;

  const RequestedProductsTable({
    super.key,
    required this.selectedFilterIndex,
    required this.searchQuery,
  });

  @override
  RequestedProductsTableState createState() => RequestedProductsTableState();
}

class RequestedProductsTableState extends State<RequestedProductsTable> {
  List<RequestedProductModel> _allProducts = [];
  bool _isLoading = true;
  int? _supplierId;

  int _currentPage = 1;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final int _itemsPerPage = 5; // Changed to 5 as requested

  List<String> _statusOptions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    _statusOptions = [l10n.pending, l10n.accepted, l10n.declined];

    if (_supplierId == null) {
      _loadSupplierId().then((_) => _fetchRequestedProducts());
    }
  }

  void refreshProducts() {
    debugPrint(
        'Refreshing requested products table, clearing existing data...');

    // Clear existing products first
    setState(() {
      _allProducts = [];
      _isLoading = true;
    });

    // Force a clean fetch with a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchRequestedProducts().then((_) {
        debugPrint(
            'Products refresh completed. Found ${_allProducts.length} requested products');
      });
    });
  }

  // Load supplierId from SharedPreferences
  Future<void> _loadSupplierId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _supplierId = prefs.getInt('supplierId');
    });
    debugPrint(
        '📦 Loaded supplierId for requested products table: $_supplierId');

    // Print the token to check if it contains the correct supplier ID
    final token = await AuthService.getToken();
    debugPrint(
        '🔑 Using auth token: ${token?.substring(0, 20)}... (${token?.length} chars)');
  }

  // Fetch requested products from the API
  Future<void> _fetchRequestedProducts() async {
    if (_supplierId == null) {
      debugPrint('⚠️ No supplierId found, cannot fetch requested products');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      debugPrint(
          '📤 Fetching requested products for supplier ID: $_supplierId');

      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/request-product/supplier/$_supplierId'),
        headers: headers,
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(
            '📦 Data received: ${data['productRequests']?.length ?? 0} requested products');

        if (data['productRequests'] != null &&
            data['productRequests'] is List) {
          List<RequestedProductModel> products = [];

          for (var product in data['productRequests']) {
            products.add(RequestedProductModel.fromJson(product));
          }

          setState(() {
            _allProducts = products;
            _isLoading = false;
          });
          debugPrint(
              '✅ Table updated with ${products.length} requested products');
        } else {
          debugPrint('⚠️ Invalid response format: ${response.body}');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        debugPrint(
            '⚠️ Error fetching requested products: ${response.statusCode}, Body: ${response.body}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Exception fetching requested products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get localized status
  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pending;
      case 'accepted':
        return l10n.accepted;
      case 'declined':
        return l10n.declined;
      default:
        return status;
    }
  }

  /// Returns filtered, searched, and sorted products.
  List<RequestedProductModel> get filteredProducts {
    List<RequestedProductModel> temp = List.from(_allProducts);

    // Filter by status based on selected filter index
    if (widget.selectedFilterIndex > 0 &&
        widget.selectedFilterIndex <= _statusOptions.length) {
      String statusFilter = _statusOptions[widget.selectedFilterIndex - 1];
      temp = temp
          .where((p) =>
              _getLocalizedStatus(
                  p.status,
                  Localizations.of<AppLocalizations>(
                      context, AppLocalizations)!) ==
              statusFilter)
          .toList();
    }

    // Search by name or product ID
    if (widget.searchQuery.isNotEmpty) {
      temp = temp
          .where((p) =>
              p.name.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
              p.id.toString().contains(widget.searchQuery))
          .toList();
    }

    // Apply sorting if set
    if (_sortColumnIndex != null) {
      if (_sortColumnIndex == 1) {
        temp.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      if (!_sortAscending) {
        temp = temp.reversed.toList();
      }
    }

    return temp;
  }

  /// Helper: builds a header label with a sort arrow.
  Widget _buildSortableColumnLabel(String label, int colIndex, bool isRtl) {
    bool isSorted = _sortColumnIndex == colIndex;
    Widget arrow = SizedBox.shrink();
    if (isSorted) {
      arrow = Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 14.sp,
        color: Colors.white,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Text(label),
        SizedBox(width: 4.w),
        arrow,
      ],
    );
  }

  /// Called when a sortable header is tapped.
  void _onSort(int colIndex) {
    setState(() {
      if (_sortColumnIndex == colIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = colIndex;
        _sortAscending = true;
      }
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color.fromARGB(255, 105, 65, 198),
        ),
      );
    }

    final totalItems = filteredProducts.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > totalItems
        ? totalItems
        : startIndex + _itemsPerPage;
    final visibleProducts = filteredProducts.isEmpty
        ? []
        : filteredProducts.sublist(startIndex, endIndex);

    // Heading row color
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    // Divider and border color/thickness
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.r),
                topRight: Radius.circular(30.r),
              ),
            ),
            width: constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wrap DataTable in horizontal SingleChildScrollView.
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
                          MaterialStateProperty.all<Color>(headingColor),
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
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            )
                          : GoogleFonts.spaceGrotesk(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                      dataTextStyle: isArabic
                          ? GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13.sp,
                            )
                          : GoogleFonts.spaceGrotesk(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13.sp,
                            ),
                      columns: [
                        // ID Column
                        DataColumn(label: Text(l10n.id)),
                        // Date Column (sortable)
                        DataColumn(
                          label: _buildSortableColumnLabel(
                              l10n.dateRequested, 1, isRtl),
                          onSort: (columnIndex, _) {
                            _onSort(1);
                          },
                        ),
                        // Image & Name Column
                        DataColumn(label: Text(l10n.imageAndName)),
                        // Cost Price Column
                        DataColumn(label: Text(l10n.costPrice)),
                        // Category Column
                        DataColumn(label: Text(l10n.category)),
                        // Status Column
                        DataColumn(label: Text(l10n.status)),
                      ],
                      rows: visibleProducts.map((product) {
                        return DataRow(
                          cells: [
                            // ID cell
                            DataCell(Text("${product.id}")),
                            // Date cell
                            DataCell(Text(
                              "${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}",
                            )),
                            // Image & Name cell
                            DataCell(
                              Row(
                                textDirection: isRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: product.image != null
                                        ? Image.network(
                                            product.image!,
                                            width: 50.w,
                                            height: 50.h,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 50.w,
                                                height: 50.h,
                                                color: Colors.grey.shade800,
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.white70,
                                                  size: 24.sp,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: 50.w,
                                            height: 50.h,
                                            color: Colors.grey.shade800,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.white70,
                                              size: 24.sp,
                                            ),
                                          ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textDirection: isRtl
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Cost Price cell
                            DataCell(Text(
                                "\$${product.costPrice.toStringAsFixed(2)}")),
                            // Category cell
                            DataCell(Text(product.categoryName)),
                            // Status cell with potential admin note tooltip
                            DataCell(
                              _buildStatusPill(product.status, l10n, isArabic,
                                  adminNote: product.adminNote),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Pagination row
                if (filteredProducts.isNotEmpty)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                    child: Row(
                      textDirection:
                          isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        Spacer(),
                        Text(
                          "${l10n.total} $totalItems ${l10n.items}",
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                        ),
                        SizedBox(width: 10.w),
                        // Previous page button
                        IconButton(
                          icon: Icon(
                              Icons
                                  .arrow_back, // Always arrow_back for previous
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
                        Row(
                          children: List.generate(totalPages, (index) {
                            return _buildPageButton(index + 1, isArabic);
                          }),
                        ),
                        // Next page button
                        IconButton(
                          icon: Icon(
                              Icons
                                  .arrow_forward, // Always arrow_forward for next
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
          ),
        );
      },
    );
  }

  /// Status pill with different colors based on status and tooltip for admin note.
  Widget _buildStatusPill(String status, AppLocalizations l10n, bool isArabic,
      {String? adminNote}) {
    late Color bgColor;
    String localizedStatus = _getLocalizedStatus(status, l10n);

    switch (status.toLowerCase()) {
      case "pending":
        bgColor = Colors.amber; // amber/yellow for pending
        break;
      case "accepted":
        bgColor = const Color.fromARGB(178, 0, 224, 116); // green for accepted
        break;
      case "declined":
        bgColor = const Color.fromARGB(255, 229, 62, 62); // red for declined
        break;
      default:
        bgColor = Colors.grey; // default
    }

    final statusPill = Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        localizedStatus,
        style: isArabic
            ? GoogleFonts.cairo(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: bgColor,
              )
            : GoogleFonts.spaceGrotesk(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: bgColor,
              ),
      ),
    );

    // If there's an admin note, wrap the status pill with a tooltip
    if (adminNote != null && adminNote.isNotEmpty) {
      return Tooltip(
        message: "${l10n.adminNote}: $adminNote",
        preferBelow: true,
        showDuration: const Duration(seconds: 3),
        decoration: BoxDecoration(
          color: const Color.fromARGB(230, 36, 50, 69),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: const Color.fromARGB(255, 105, 65, 198),
            width: 1.5,
          ),
        ),
        textStyle: isArabic
            ? GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14.sp,
              )
            : GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14.sp,
              ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: statusPill,
      );
    }

    // If no admin note, just return the status pill
    return statusPill;
  }

  /// Pagination button builder.
  Widget _buildPageButton(int pageIndex, bool isArabic) {
    final bool isSelected = (pageIndex == _currentPage);

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
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        ),
        onPressed: () {
          setState(() {
            _currentPage = pageIndex;
          });
        },
        child: Text(
          "$pageIndex",
          style: isArabic
              ? GoogleFonts.cairo(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                )
              : GoogleFonts.spaceGrotesk(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ),
    );
  }
}
