import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'dart:convert';

import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

/// Model for a product selling history item from API
class ProductSellingHistoryItem {
  final String orderId;
  final String orderPrice;
  final String orderDate;
  final String customer;
  final String status;
  final int quantity;
  final double subtotal;

  ProductSellingHistoryItem({
    required this.orderId,
    required this.orderPrice,
    required this.orderDate,
    required this.customer,
    required this.status,
    required this.quantity,
    required this.subtotal,
  });

  factory ProductSellingHistoryItem.fromJson(Map<String, dynamic> json) {
    return ProductSellingHistoryItem(
      orderId: json['orderId'] ?? '',
      orderPrice: json['orderPrice'] ?? '',
      orderDate: json['orderDate'] ?? '',
      customer: json['customer'] ?? '',
      status: json['status'] ?? '',
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

/// Model for pagination info from API
class PaginationInfo {
  final int currentPage;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginationInfo({
    required this.currentPage,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      limit: json['limit'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}

/// Model for the complete API response
class ProductSellingHistoryResponse {
  final String message;
  final Map<String, dynamic> product;
  final List<ProductSellingHistoryItem> history;
  final PaginationInfo pagination;

  ProductSellingHistoryResponse({
    required this.message,
    required this.product,
    required this.history,
    required this.pagination,
  });

  factory ProductSellingHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ProductSellingHistoryResponse(
      message: json['message'] ?? '',
      product: json['product'] ?? {},
      history: (json['history'] as List? ?? [])
          .map((item) => ProductSellingHistoryItem.fromJson(item))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class ProductSellingHistoryWidget extends StatefulWidget {
  final int productId;

  const ProductSellingHistoryWidget({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  _ProductSellingHistoryWidgetState createState() =>
      _ProductSellingHistoryWidgetState();
}

class _ProductSellingHistoryWidgetState
    extends State<ProductSellingHistoryWidget> {
  // API data
  ProductSellingHistoryResponse? _historyData;
  bool _isLoading = true;
  String? _error;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage =
      6; // Display 6 items per page to match your original design

  // Sorting
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchSellingHistory();
  }

  Future<void> _fetchSellingHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint(
          '🔄 Fetching selling history for product ${widget.productId}, page $_currentPage');

      // Build URL with pagination
      final String url =
          'https://finalproject-a5ls.onrender.com/dashboard/product-selling-history/${widget.productId}?page=$_currentPage&limit=$_itemsPerPage';

      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Selling history data received');
        debugPrint('📊 Total items: ${data['pagination']['totalItems']}');

        setState(() {
          _historyData = ProductSellingHistoryResponse.fromJson(data);
          _isLoading = false;
        });
      } else {
        debugPrint('❌ Error fetching selling history: ${response.statusCode}');
        setState(() {
          _error = 'Failed to load selling history: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Exception fetching selling history: $e');
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  /// Helper: builds a color-coded pill for status.
  Widget _buildStatusPill(String status, AppLocalizations l10n, bool isArabic) {
    late Color borderColor;
    late Color bgColor;
    late String localizedStatus;

    switch (status) {
      case "Completed":
        borderColor = const Color.fromARGB(255, 48, 182, 140);
        bgColor = borderColor.withOpacity(0.15);
        localizedStatus = l10n.completed;
        break;
      case "On the way":
        borderColor = const Color.fromARGB(255, 228, 0, 127);
        bgColor = borderColor.withOpacity(0.15);
        localizedStatus = l10n.onTheWay;
        break;
      case "Cancelled":
        borderColor = const Color.fromARGB(255, 229, 62, 62);
        bgColor = borderColor.withOpacity(0.15);
        localizedStatus = l10n.cancelled;
        break;
      case "Refunded":
        borderColor = const Color.fromARGB(255, 141, 110, 199);
        bgColor = borderColor.withOpacity(0.15);
        localizedStatus = l10n.refunded;
        break;
      case "Pending":
        borderColor = const Color.fromARGB(255, 255, 193, 7);
        bgColor = borderColor.withOpacity(0.15);
        localizedStatus = l10n.pending;
        break;
      default:
        borderColor = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.15);
        localizedStatus = status;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        localizedStatus,
        style: isArabic
            ? GoogleFonts.cairo(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: borderColor,
              )
            : GoogleFonts.spaceGrotesk(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
      ),
    );
  }

  /// Builds a header label for sorting.
  Widget _buildSortableColumnLabel(
      String label, int colIndex, bool isArabic, bool isRtl) {
    bool isSorted = _sortColumnIndex == colIndex;
    Widget arrow = SizedBox.shrink();
    if (isSorted) {
      arrow = Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 18.sp,
        color: Colors.white,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: isArabic
              ? GoogleFonts.cairo(fontSize: 18.sp, color: Colors.white)
              : GoogleFonts.spaceGrotesk(fontSize: 18.sp, color: Colors.white),
        ),
        SizedBox(width: 4.w),
        arrow,
      ],
    );
  }

  void _onSort(int colIndex) {
    setState(() {
      if (_sortColumnIndex == colIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = colIndex;
        _sortAscending = true;
      }
      // Note: For server-side sorting, you would need to modify the API call
      // For now, we'll keep client-side sorting on the current page data
    });
  }

  /// Navigate to a specific page
  void _goToPage(int page) {
    if (page != _currentPage &&
        page >= 1 &&
        _historyData != null &&
        page <= _historyData!.pagination.totalPages) {
      setState(() {
        _currentPage = page;
      });
      _fetchSellingHistory();
    }
  }

  /// Builds a pagination button.
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
        onPressed: () => _goToPage(pageIndex),
        child: Text(
          "$pageIndex",
          style: isArabic
              ? GoogleFonts.cairo(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                )
              : GoogleFonts.spaceGrotesk(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
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

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 300.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(29.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color.fromARGB(255, 105, 65, 198),
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.loadingSellingHistory,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14.sp,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        height: 300.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(29.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.errorLoadingSellingHistory,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
              ),
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchSellingHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  l10n.retry,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_historyData == null || _historyData!.history.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(29.r),
        ),
        child: Center(
          child: Text(
            l10n.noSellingHistoryAvailable,
            style: isArabic
                ? GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 16.sp,
                  )
                : GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 16.sp,
                  ),
          ),
        ),
      );
    }

    final pagination = _historyData!.pagination;
    final history = _historyData!.history;

    // Apply client-side sorting if needed
    List<ProductSellingHistoryItem> sortedHistory = List.from(history);
    if (_sortColumnIndex != null) {
      if (_sortColumnIndex == 1) {
        // Sort by order price (remove $ and convert to double)
        sortedHistory.sort((a, b) {
          final priceA = double.tryParse(
                  a.orderPrice.replaceAll('\$', '').replaceAll(',', '')) ??
              0;
          final priceB = double.tryParse(
                  b.orderPrice.replaceAll('\$', '').replaceAll(',', '')) ??
              0;
          return priceA.compareTo(priceB);
        });
      } else if (_sortColumnIndex == 4) {
        // Sort by quantity
        sortedHistory.sort((a, b) => a.quantity.compareTo(b.quantity));
      } else if (_sortColumnIndex == 5) {
        // Sort by subtotal
        sortedHistory.sort((a, b) => a.subtotal.compareTo(b.subtotal));
      }
      if (!_sortAscending) {
        sortedHistory = sortedHistory.reversed.toList();
      }
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29.r),
        ),
        child: Column(
          children: [
            // Wrap DataTable in horizontal SingleChildScrollView.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all<Color>(
                      const Color.fromARGB(255, 36, 50, 69)),
                  border: TableBorder(
                    top: BorderSide(
                        color: const Color.fromARGB(255, 34, 53, 62), width: 1),
                    bottom: BorderSide(
                        color: const Color.fromARGB(255, 34, 53, 62), width: 1),
                    left: BorderSide(
                        color: const Color.fromARGB(255, 34, 53, 62), width: 1),
                    right: BorderSide(
                        color: const Color.fromARGB(255, 34, 53, 62), width: 1),
                    horizontalInside: BorderSide(
                        color: const Color.fromARGB(255, 36, 50, 69), width: 2),
                    verticalInside: BorderSide(
                        color: const Color.fromARGB(255, 36, 50, 69), width: 2),
                  ),
                  columnSpacing: 20.w,
                  dividerThickness: 0,
                  headingTextStyle: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                  dataTextStyle: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15.sp,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15.sp,
                        ),
                  columns: [
                    DataColumn(
                        label: Text(l10n.orderId,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 16.sp, color: Colors.white)
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 16.sp, color: Colors.white))),
                    DataColumn(
                      label: _buildSortableColumnLabel(
                          l10n.orderPrice, 1, isArabic, isRtl),
                      onSort: (columnIndex, _) {
                        _onSort(1);
                      },
                    ),
                    DataColumn(
                        label: Text(l10n.orderDate,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 16.sp, color: Colors.white)
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 16.sp, color: Colors.white))),
                    DataColumn(
                        label: Text(l10n.customer,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 16.sp, color: Colors.white)
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 16.sp, color: Colors.white))),
                    DataColumn(
                      label: _buildSortableColumnLabel(
                          l10n.quantity, 4, isArabic, isRtl),
                      onSort: (columnIndex, _) {
                        _onSort(4);
                      },
                    ),
                    DataColumn(
                      label: _buildSortableColumnLabel(
                          l10n.subtotal, 5, isArabic, isRtl),
                      onSort: (columnIndex, _) {
                        _onSort(5);
                      },
                    ),
                    DataColumn(
                        label: Text(l10n.status,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 16.sp, color: Colors.white)
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 16.sp, color: Colors.white))),
                  ],
                  rows: sortedHistory.map((order) {
                    return DataRow(
                      cells: [
                        DataCell(Text(order.orderId)),
                        DataCell(Text(order.orderPrice)),
                        DataCell(Text(order.orderDate)),
                        DataCell(Text(order.customer)),
                        DataCell(Text("${order.quantity}")),
                        DataCell(
                            Text("\$${order.subtotal.toStringAsFixed(2)}")),
                        DataCell(
                            _buildStatusPill(order.status, l10n, isArabic)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Pagination row with total items info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Total items info
                Text(
                  "${l10n.total} ${pagination.totalItems} ${l10n.items}",
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

                // Pagination controls
                Row(
                  children: [
                    // Left/Right arrow (respecting RTL)
                    IconButton(
                      icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back,
                          size: 20.sp, color: Colors.white70),
                      onPressed: pagination.hasPreviousPage
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                    ),

                    // Page number buttons (show max 5 pages)
                    ...List.generate(
                      pagination.totalPages > 5 ? 5 : pagination.totalPages,
                      (index) {
                        int pageNumber;
                        if (pagination.totalPages <= 5) {
                          pageNumber = index + 1;
                        } else {
                          // Smart pagination: show current page and surrounding pages
                          if (_currentPage <= 3) {
                            pageNumber = index + 1;
                          } else if (_currentPage >=
                              pagination.totalPages - 2) {
                            pageNumber = pagination.totalPages - 4 + index;
                          } else {
                            pageNumber = _currentPage - 2 + index;
                          }
                        }
                        return _buildPageButton(pageNumber, isArabic);
                      },
                    ),

                    // Right/Left arrow (respecting RTL)
                    IconButton(
                      icon: Icon(isRtl ? Icons.arrow_back : Icons.arrow_forward,
                          size: 20.sp, color: Colors.white70),
                      onPressed: pagination.hasNextPage
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
