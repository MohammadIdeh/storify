import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'dart:convert';

import 'package:storify/admin/widgets/productsWidgets/RequestedProductModel.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class RequestedProductDetail extends StatefulWidget {
  final RequestedProductModel product;

  const RequestedProductDetail({
    super.key,
    required this.product,
  });

  @override
  State<RequestedProductDetail> createState() => _RequestedProductDetailState();
}

class _RequestedProductDetailState extends State<RequestedProductDetail> {
  bool _isLoading = false;
  final TextEditingController _noteController = TextEditingController();
  RequestedProductModel? _updatedProduct;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Process the request (accept or decline)
  Future<void> _processRequest(String action) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    setState(() {
      _isLoading = true;
    });

    // Get the admin note if provided
    final adminNote = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;

    final status = action == 'accept' ? 'Accepted' : 'Declined';

    try {
      // Get auth headers from AuthService
      final headers = await AuthService.getAuthHeaders();
      // Add Content-Type to headers
      headers['Content-Type'] = 'application/json';

      debugPrint(
          '🔄 Processing request for product ${widget.product.id}: $status');
      debugPrint('📤 Request headers: $headers');

      final response = await http.patch(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/request-product/${widget.product.id}/status'),
        headers: headers,
        body: json.encode({
          'status': status,
          'adminNote': adminNote,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['productRequest'] != null) {
          setState(() {
            _updatedProduct =
                RequestedProductModel.fromJson(data['productRequest']);
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${l10n.productRequestHasBeen} ${status == 'Accepted' ? l10n.accepted : l10n.declined}'),
              backgroundColor: status == 'Accepted' ? Colors.green : Colors.red,
            ),
          );

          // Return to previous screen after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pop(_updatedProduct);
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${l10n.failedToProcessRequest}: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Use the updated product if available, otherwise use the original
    final product = _updatedProduct ?? widget.product;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 29, 41, 57),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: const Color.fromARGB(255, 29, 41, 57),
          title: Text(
            l10n.productRequestDetails,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
          ),
          leading: IconButton(
            icon: Icon(isRtl ? Icons.arrow_back : Icons.arrow_forward,
                color: Colors.white),
            onPressed: () => Navigator.of(context).pop(_updatedProduct),
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: const Color.fromARGB(255, 105, 65, 198),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsetsDirectional.all(24.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product header section
                    Directionality(
                      textDirection:
                          isRtl ? TextDirection.rtl : TextDirection.ltr,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: product.image != null
                                ? Image.network(
                                    product.image!,
                                    width: 200.w,
                                    height: 200.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 200.w,
                                        height: 200.h,
                                        color: Colors.grey.shade800,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white70,
                                          size: 64.sp,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 200.w,
                                    height: 200.h,
                                    color: Colors.grey.shade800,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white70,
                                      size: 64.sp,
                                    ),
                                  ),
                          ),
                          SizedBox(width: 24.w),
                          // Product info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
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
                                SizedBox(height: 8.h),
                                _buildInfoRow(
                                    l10n.id, '${product.id}', isArabic),
                                _buildInfoRow(
                                    l10n.barcode, product.barcode, isArabic),
                                _buildInfoRow(l10n.category,
                                    product.category.categoryName, isArabic),
                                _buildInfoRow(
                                    l10n.costPrice,
                                    '\$${product.costPrice.toStringAsFixed(2)}',
                                    isArabic),
                                _buildInfoRow(
                                    l10n.sellPrice,
                                    '\$${product.sellPrice.toStringAsFixed(2)}',
                                    isArabic),
                                SizedBox(height: 16.h),
                                _buildStatusPill(
                                    product.status, l10n, isArabic),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Supplier information section
                    _buildSectionHeader(l10n.supplierInformation, isArabic),
                    Container(
                      padding: EdgeInsetsDirectional.all(16.r),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 36, 50, 69),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                              l10n.name, product.supplier.user.name, isArabic),
                          _buildInfoRow(l10n.email, product.supplier.user.email,
                              isArabic),
                          _buildInfoRow(
                              l10n.id, '${product.supplier.id}', isArabic),
                          _buildInfoRow(l10n.accountBalance,
                              product.supplier.accountBalance, isArabic),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Product details section
                    _buildSectionHeader(l10n.productDetails, isArabic),
                    Container(
                      padding: EdgeInsetsDirectional.all(16.r),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 36, 50, 69),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.description != null &&
                              product.description!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.description,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  product.description!,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          fontSize: 15.sp,
                                          color: Colors.white,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          fontSize: 15.sp,
                                          color: Colors.white,
                                        ),
                                ),
                                SizedBox(height: 16.h),
                              ],
                            ),
                          _buildInfoRow(
                              l10n.requestDate,
                              '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                              isArabic),
                          if (product.warranty != null)
                            _buildInfoRow(
                                l10n.warranty, product.warranty!, isArabic),
                          if (product.prodDate != null)
                            _buildInfoRow(
                                l10n.productionDate,
                                '${product.prodDate!.day}/${product.prodDate!.month}/${product.prodDate!.year}',
                                isArabic),
                          if (product.expDate != null)
                            _buildInfoRow(
                                l10n.expiryDate,
                                '${product.expDate!.day}/${product.expDate!.month}/${product.expDate!.year}',
                                isArabic),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Admin note section if there is one
                    if (product.adminNote != null &&
                        product.adminNote!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(l10n.adminNote, isArabic),
                          Container(
                            padding: EdgeInsetsDirectional.all(16.r),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 36, 50, 69),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              product.adminNote!,
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 15.sp,
                                      color: Colors.white,
                                    )
                                  : GoogleFonts.spaceGrotesk(
                                      fontSize: 15.sp,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),

                    // Action buttons (only show if status is Pending)
                    if (product.status == 'Pending')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(l10n.actions, isArabic),
                          Container(
                            padding: EdgeInsetsDirectional.all(16.r),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 36, 50, 69),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Optional admin note input
                                Text(
                                  l10n.adminNoteOptional,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                ),
                                SizedBox(height: 8.h),
                                TextField(
                                  controller: _noteController,
                                  maxLines: 3,
                                  textDirection: isRtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          color: Colors.white,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                        ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor:
                                        const Color.fromARGB(255, 29, 41, 57),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: l10n.addNoteToSupplier,
                                    hintStyle: isArabic
                                        ? GoogleFonts.cairo(
                                            color: Colors.white38,
                                          )
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.white38,
                                          ),
                                  ),
                                ),
                                SizedBox(height: 24.h),

                                // Accept/Decline buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 20.h,
                                          horizontal: 50.w,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                      ),
                                      onPressed: () =>
                                          _processRequest('decline'),
                                      child: Text(
                                        l10n.decline,
                                        style: isArabic
                                            ? GoogleFonts.cairo(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              )
                                            : GoogleFonts.spaceGrotesk(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 20.h,
                                          horizontal: 50.w,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                      ),
                                      onPressed: () =>
                                          _processRequest('accept'),
                                      child: Text(
                                        l10n.accept,
                                        style: isArabic
                                            ? GoogleFonts.cairo(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              )
                                            : GoogleFonts.spaceGrotesk(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  // Helper to build section headers
  Widget _buildSectionHeader(String title, bool isArabic) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 16.h),
      child: Text(
        title,
        style: isArabic
            ? GoogleFonts.cairo(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )
            : GoogleFonts.spaceGrotesk(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
      ),
    );
  }

  // Helper to build info rows
  Widget _buildInfoRow(String label, String value, bool isArabic) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 15.sp,
                      color: Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 15.sp,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build status pill
  Widget _buildStatusPill(String status, AppLocalizations l10n, bool isArabic) {
    late Color bgColor;
    late String localizedStatus;

    switch (status) {
      case "Pending":
        bgColor = Colors.amber;
        localizedStatus = l10n.pending;
        break;
      case "Accepted":
        bgColor = const Color.fromARGB(178, 0, 224, 116);
        localizedStatus = l10n.accepted;
        break;
      case "Declined":
        bgColor = const Color.fromARGB(255, 229, 62, 62);
        localizedStatus = l10n.declined;
        break;
      default:
        bgColor = Colors.grey;
        localizedStatus = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        localizedStatus,
        style: isArabic
            ? GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: bgColor,
              )
            : GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: bgColor,
              ),
      ),
    );
  }
}
