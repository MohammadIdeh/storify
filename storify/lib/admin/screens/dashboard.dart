import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/navigationBar.dart';
import 'package:storify/admin/widgets/cards.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Example handler for tapping on nav items
  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Navigate to a new screen or set a body widget, etc.
    switch (index) {
      case 0:
        // Dashboard
        // Navigator.pushNamed(context, '/dashboard');
        break;
      case 1:
        // Products
        // Navigator.pushNamed(context, '/products');
        break;
      case 2:
        // Orders
        // Navigator.pushNamed(context, '/orders');
        break;
      case 3:
        // Stores
        // Navigator.pushNamed(context, '/stores');
        break;
      case 4:
        // More
        // Navigator.pushNamed(context, '/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57), // N,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: MyNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavItemTap,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 45.0, top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Dashboard",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 246, 246, 246),
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 40.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 36, 50, 69),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          fixedSize: const Size(138, 50),
                          elevation: 1,
                        ),
                        onPressed: () {},
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/filter.svg',
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 12),
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
                    ),
                  ],
                ),
                SizedBox(height: 40.h),
                Wrap(alignment: WrapAlignment.center, children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Total available width
                      final availableWidth = constraints.maxWidth - 41;
                      // Number of cards per row
                      final numberOfCards = 4;
                      // Horizontal spacing between cards (using SizedBox width)
                      final spacing = 40.0;

                      // Calculate the dynamic width for each card.
                      // (Subtract spacing between cards from the total width)
                      final cardWidth =
                          (availableWidth - ((numberOfCards - 1) * spacing)) /
                              numberOfCards;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: 20,
                        children: [
                          Container(
                            width: cardWidth,
                            child: StatsCard(
                              percentage: "20 %",
                              svgIconPath: "assets/images/totalProducts.svg",
                              title: "Total Products",
                              value: "25,430",
                            ),
                          ),
                          Container(
                            width: cardWidth,
                            child: StatsCard(
                              percentage: "20 %",
                              svgIconPath: "assets/images/totalProducts.svg",
                              title: "Total Products",
                              value: "25,430",
                            ),
                          ),
                          Container(
                            width: cardWidth,
                            child: StatsCard(
                              percentage: "20 %",
                              svgIconPath: "assets/images/totalProducts.svg",
                              title: "Total Products",
                              value: "25,430",
                            ),
                          ),
                          Container(
                            width: cardWidth,
                            child: StatsCard(
                              percentage: "20 %",
                              svgIconPath: "assets/images/totalProducts.svg",
                              title: "Total Products",
                              value: "25,430",
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}
