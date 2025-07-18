import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/productsWidgets/ProductSalesOverviewWidget.dart';
import 'package:storify/admin/widgets/productsWidgets/product_item_Model.dart';
import 'package:storify/admin/widgets/productsWidgets/productInformationCard.dart';
import 'package:storify/admin/widgets/productsWidgets/sellingHistoryTable.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class Productoverview extends StatefulWidget {
  final ProductItemInformation product;
  const Productoverview({super.key, required this.product});

  @override
  State<Productoverview> createState() => _ProductoverviewState();
}

class _ProductoverviewState extends State<Productoverview> {
  late ProductItemInformation _currentProduct;

  @override
  void initState() {
    super.initState();
    // Initialize with the product passed in
    _currentProduct = widget.product;
  }

  // This callback is called from the ProductInformationCard when saved
  void _handleProductUpdate(ProductItemInformation updatedProduct) {
    setState(() {
      _currentProduct = updatedProduct;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: isRtl ? 45.w : 45.w,
            top: 20.h,
            right: isRtl ? 45.w : 45.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title row
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            width: 1.5,
                            color: const Color.fromARGB(255, 47, 71, 82)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      fixedSize: Size(120.w, 50.h),
                      elevation: 1,
                    ),
                    onPressed: () {
                      // Use named route to go back to products with URL change
                      Navigator.pushNamed(context, '/admin/products');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.flip(
                          flipX: isRtl,
                          child: SvgPicture.asset(
                            'assets/images/back.svg',
                            width: 18.w,
                            height: 18.h,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          l10n.back,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      const Color.fromARGB(255, 105, 123, 123),
                                )
                              : GoogleFonts.spaceGrotesk(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      const Color.fromARGB(255, 105, 123, 123),
                                ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Text(
                    l10n.productOverview,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 246, 246, 246),
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 246, 246, 246),
                          ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),

              // Product info card and sales overview row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3, // More space for ProductInformationCard
                    child: ProductInformationCard(
                      product: _currentProduct,
                      onUpdate: _handleProductUpdate,
                    ),
                  ),
                  SizedBox(width: 20.w), // spacing between the two widgets
                  Expanded(
                    flex: 2, // Less space for Product Sales Overview
                    child: ProductSalesOverviewWidget(
                      productId: _currentProduct.productId,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),

              // Suppliers section - Full width, separate from cards
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 36, 50, 69),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.suppliers,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 105, 65, 198)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.suppliersCount(
                                "${_currentProduct.suppliers.length}"),
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 14.sp,
                                    color: Color.fromARGB(255, 105, 65, 198),
                                    fontWeight: FontWeight.w600,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 14.sp,
                                    color: Color.fromARGB(255, 105, 65, 198),
                                    fontWeight: FontWeight.w600,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 54, 68, 88),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      height: 180.h, // Taller height for the standalone section
                      child: _currentProduct.suppliers.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noSuppliersAssigned,
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
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              itemCount: _currentProduct.suppliers.length,
                              itemBuilder: (context, index) {
                                final supplier =
                                    _currentProduct.suppliers[index];
                                final user = supplier['user'] ?? {};
                                final supplierName =
                                    user['name'] ?? l10n.unknown;
                                final supplierEmail =
                                    user['email'] ?? l10n.noEmail;
                                final supplierPhone =
                                    user['phoneNumber'] ?? l10n.noPhone;
                                final supplierId =
                                    supplier['id'] ?? l10n.unknownId;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 105, 65, 198),
                                    radius: 24,
                                    child: Text(
                                      supplierName.isNotEmpty
                                          ? supplierName[0].toUpperCase()
                                          : '?',
                                      style: isArabic
                                          ? GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            )
                                          : GoogleFonts.spaceGrotesk(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          supplierName,
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16.sp,
                                                )
                                              : GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16.sp,
                                                ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          l10n.supplierId(supplierId),
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  color: Colors.white70,
                                                  fontSize: 12.sp,
                                                )
                                              : GoogleFonts.spaceGrotesk(
                                                  color: Colors.white70,
                                                  fontSize: 12.sp,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    "$supplierEmail • $supplierPhone",
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            color: Colors.white70,
                                            fontSize: 14.sp,
                                          )
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.white70,
                                            fontSize: 14.sp,
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),

              // Selling History section
              Row(
                children: [
                  Text(
                    l10n.sellingHistory,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: ProductSellingHistoryWidget(
                      productId: _currentProduct.productId,
                    ),
                  )
                ],
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
