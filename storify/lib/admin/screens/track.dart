import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/admin/widgets/trackingWidgets/cards.dart';
import 'package:storify/admin/widgets/trackingWidgets/filterpanel.dart';
import 'package:storify/admin/widgets/trackingWidgets/map.dart';

class Track extends StatefulWidget {
  const Track({super.key});

  @override
  State<Track> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<Track> {
  int _currentIndex = 5;
  String? profilePictureUrl;

  final List<Map<String, String>> _trackData = [
    {
      'title': 'Total Shipment',
      'value': '456',
    },
    {
      'title': 'Completed',
      'value': '320',
    },
    {
      'title': 'Pending',
      'value': '136',
    },
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
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Productsscreen(),
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
      case 2:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CategoriesScreen(),
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
      case 3:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Orders(),
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
      case 4:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Rolemanegment(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 5:
        break;
    }
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
          profilePictureUrl: profilePictureUrl,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// --- Dashboard Title ---
                Row(
                  children: [
                    Text(
                      "Tracking",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 35.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 246, 246, 246),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),

                /// --- Tracking Cards ---
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final numberOfCards = _trackData.length;
                    const spacing = 40.0;
                    final cardWidth =
                        (availableWidth - ((numberOfCards - 1) * spacing)) /
                            numberOfCards;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 20,
                      children: List.generate(_trackData.length, (index) {
                        final data = _trackData[index];
                        return SizedBox(
                          width: cardWidth,
                          child: TrackCards(
                            title: data['title'] ?? '',
                            value: data['value'] ?? '',
                          ),
                        );
                      }),
                    );
                  },
                ),

                /// --- Map Section ---
                const SizedBox(height: 40),
                // inside your Track.build(), replace the Padding + Row with:
                LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    const spacing = 40.0; // space between map & panel
                    final panelWidth = totalWidth * 0.30; // 30% for the filters
                    final mapWidth = totalWidth - panelWidth - spacing;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1) Map at computed width
                        SizedBox(
                          width: mapWidth,
                          child: const TrackMapSection(),
                        ),

                        SizedBox(width: spacing.w),

                        // 2) Filters panel at computed width
                        SizedBox(
                          width: panelWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: const FiltersPanel(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
