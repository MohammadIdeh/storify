import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/navigationBar.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/widgets/product_item_Model.dart';
import 'package:storify/admin/widgets/productInformationCard.dart';
import 'package:storify/admin/widgets/salesOverview.dart';
import 'package:storify/admin/widgets/sellingHistoryTable.dart';

class Productoverview extends StatefulWidget {
  final ProductItemInformation product;
  const Productoverview({super.key, required this.product});

  @override
  State<Productoverview> createState() => _ProductoverviewState();
}

class _ProductoverviewState extends State<Productoverview> {
  int _currentIndex = 1;
  late ProductItemInformation _currentProduct;

  @override
  void initState() {
    super.initState();
    // Initialize with the product passed in.
    _currentProduct = widget.product;
  }

  // This callback is called from the ProductInformationCard when saved.
  void _handleProductUpdate(ProductItemInformation updatedProduct) {
    setState(() {
      _currentProduct = updatedProduct;
    });
    // Optionally, propagate this update to your data source.
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Navigation actions...
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
                      Navigator.pop(context, _currentProduct);
                    },
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/back.svg',
                          width: 18.w,
                          height: 18.h,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Back',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 105, 123, 123),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Text(
                    "Products Overview",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 246, 246, 246),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              Row(
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
                    flex: 2, // Less space for Salesoverview
                    child: Salesoverview(),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    'Selling History',
                    style: GoogleFonts.spaceGrotesk(
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
                    child: SellingHistoryWidget(),
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
