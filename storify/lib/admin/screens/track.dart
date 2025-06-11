import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'dart:convert';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/admin/widgets/trackingWidgets/cards.dart';
import 'package:storify/admin/widgets/trackingWidgets/advanced_tracking_map.dart';

class Track extends StatefulWidget {
  const Track({super.key});

  @override
  State<Track> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<Track> {
  int _currentIndex = 5;
  String? profilePictureUrl;
  List<Map<String, String>> _trackData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _fetchTrackingData();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  Future<void> _fetchTrackingData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get admin auth headers with token
      final headers = await AuthService.getAuthHeaders(role: 'Admin');

      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/dashboard/tracking-cards'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _trackData = [
            {
              'title': 'Total Shipment',
              'value': data['totalShipment'].toString(),
            },
            {
              'title': 'Completed',
              'value': data['completed'].toString(),
            },
            {
              'title': 'Pending',
              'value': data['pending'].toString(),
            },
          ];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Authentication failed. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load tracking data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching tracking data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTrackingData() async {
    await _fetchTrackingData();
  }

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

  Widget _buildTrackingCards() {
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 99, 102, 241),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color.fromARGB(255, 46, 57, 84),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40.sp,
              ),
              SizedBox(height: 10.h),
              Text(
                'Failed to load tracking data',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 10.h),
              ElevatedButton(
                onPressed: _refreshTrackingData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 99, 102, 241),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final numberOfCards = _trackData.length;
        const spacing = 40.0;
        final cardWidth =
            (availableWidth - ((numberOfCards - 1) * spacing)) / numberOfCards;

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
          profilePictureUrl: profilePictureUrl,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTrackingData,
        color: const Color.fromARGB(255, 99, 102, 241),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      // Add refresh button
                      IconButton(
                        onPressed: _refreshTrackingData,
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.white70,
                          size: 24.sp,
                        ),
                      ),
                    ],
                  ),

                  /// --- Tracking Cards ---
                  const SizedBox(height: 20),
                  _buildTrackingCards(),

                  /// --- REMOVED: Live Orders Cards Section ---
                  // _buildLiveOrdersCardsSection() has been removed

                  /// --- Advanced Map Section ---
                  const SizedBox(height: 40),
                  const AdvancedTrackingMap(),
                  SizedBox(
                    height: 100,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
