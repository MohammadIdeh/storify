import 'dart:async';
import 'package:deliveryman/screens/historyScreen.dart';
import 'package:deliveryman/screens/orderScreen.dart';
import 'package:deliveryman/widgets/map.dart';
import 'package:deliveryman/widgets/navbar.dart';
import 'package:deliveryman/widgets/enhanced_profile_dialog.dart'; // ADD THIS
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../services/profile_service.dart'; // ADD THIS

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _hasInitialized = false;

  // Use PageView for better performance
  late PageController _pageController;

  // Cache for reducing rebuilds
  List<Widget>? _cachedScreens;

  final List<String> _screenTitles = ['Map', 'Orders', 'History'];

  // 🔥 ADD: Timer for periodic refresh to catch cancelled orders
  Timer? _periodicRefreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize services after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeServices();
        _fetchData();
        _startPeriodicRefresh(); // 🔥 ADD THIS
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize once
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchData();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _periodicRefreshTimer?.cancel(); // 🔥 ADD THIS
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🔥 ENHANCED: When app resumes, force refresh to catch any external changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print(
              '📱 App resumed - refreshing data to catch external changes...');
          _performCompleteRefresh();
          _startPeriodicRefresh(); // Restart periodic refresh
        }
      });
    } else if (state == AppLifecycleState.paused) {
      // 🔥 ADD: Stop periodic refresh when app is paused
      _stopPeriodicRefresh();
    }
  }

  // 🔥 ADD: Periodic refresh to catch cancelled orders from admin
  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        print('🔄 Periodic refresh - checking for order updates...');
        _fetchData();
      }
    });
    print('⏰ Started periodic refresh every 30 seconds');
  }

  void _stopPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
    print('⏰ Stopped periodic refresh');
  }

  // 🔥 ADD: Force cleanup routes
  void _forceCleanupRoutes() {
    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      orderService.forceCleanupRoutes();
      print('🧹 Forced cleanup of stale routes');
    } catch (e) {
      print('❌ Error during force cleanup: $e');
    }
  }

  void _initializeServices() {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final profileService =
          Provider.of<ProfileService>(context, listen: false); // ADD THIS

      // Set token for services
      if (authService.token != null) {
        orderService.updateToken(authService.token);
        locationService.updateToken(authService.token);
        profileService.updateToken(authService.token); // ADD THIS

        // Initialize location in background
        locationService.getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  // 🔥 ENHANCED: Better data fetching with route cleanup
  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);

      // Fetch data based on current tab to avoid unnecessary calls
      switch (_currentIndex) {
        case 0: // Map tab
        case 1: // Orders tab
          await orderService.fetchAssignedOrders();
          // 🔥 ADD: Force cleanup after fetching to remove cancelled orders
          orderService.forceCleanupRoutes();
          break;
        case 2: // History tab
          await orderService.fetchCompletedOrders();
          break;
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return; // Avoid unnecessary rebuilds

    setState(() {
      _currentIndex = index;
    });

    // Animate to page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Fetch specific data for the new tab
    _fetchTabSpecificData(index);
  }

  // 🔥 ENHANCED: Better tab switching with cleanup
  void _fetchTabSpecificData(int index) {
    final orderService = Provider.of<OrderService>(context, listen: false);

    switch (index) {
      case 0: // Map
      case 1: // Orders tab
        orderService.fetchAssignedOrders().then((_) {
          // Clean up routes after fetching
          orderService.forceCleanupRoutes();
        });
        break;
      case 2: // History tab
        orderService.fetchCompletedOrders();
        break;
    }
  }

  List<Widget> _buildScreens() {
    // Cache screens to avoid rebuilding them
    if (_cachedScreens != null) return _cachedScreens!;

    _cachedScreens = [
      MapScreen(onRefresh: _performCompleteRefresh), // 🔥 USE ENHANCED REFRESH
      OrdersScreen(
        isLoading: _isLoading,
        onRefresh: _performCompleteRefresh, // 🔥 USE ENHANCED REFRESH
      ),
      EnhancedHistoryScreen(
        isLoading: _isLoading,
        onRefresh: _performCompleteRefresh, // 🔥 USE ENHANCED REFRESH
      ),
    ];

    return _cachedScreens!;
  }

  // 🔥 ADD: Enhanced refresh method for pull-to-refresh
  Future<void> _performCompleteRefresh() async {
    if (!mounted) return;

    print('🔄 Performing complete refresh...');

    final orderService = Provider.of<OrderService>(context, listen: false);

    // First, clean up any stale routes
    orderService.forceCleanupRoutes();

    // Then fetch fresh data
    await _fetchData();

    print('✅ Complete refresh finished');
  }

  // UPDATED: Use the new enhanced profile dialog
  void _showProfilePopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const EnhancedProfileDialog(),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF304050),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.logout,
              color: Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from your delivery account?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: const Color(0xAAFFFFFF),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: const Color(0xAAFFFFFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final profileService = Provider.of<ProfileService>(context,
                  listen: false); // ADD THIS

              // Clear profile data on logout
              profileService.clearProfile(); // ADD THIS
              authService.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Logout',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: const Color(0xFF1D2939),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF304050),
        title: Row(
          children: [
            // Use a simple container instead of SVG for better performance
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF6941C6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.delivery_dining,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery App',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _screenTitles[_currentIndex],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xAAFFFFFF),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Profile button - UPDATED to use ProfileService
          Consumer<ProfileService>(
            builder: (context, profileService, child) {
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6941C6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: profileService.profile?.user.profilePicture != null &&
                          profileService
                              .profile!.user.profilePicture!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            profileService.profile!.user.profilePicture!,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.person,
                              color: Color(0xFF6941C6),
                              size: 20,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Color(0xFF6941C6),
                          size: 20,
                        ),
                ),
                onPressed: _showProfilePopup,
                tooltip: 'Profile',
              );
            },
          ),

          // 🔥 ENHANCED: Better refresh button with cleanup
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6941C6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF6941C6),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh,
                      color: Color(0xFF6941C6),
                      size: 20,
                    ),
            ),
            onPressed: _isLoading
                ? null
                : _performCompleteRefresh, // 🔥 USE NEW METHOD
            tooltip: 'Refresh & Clean Routes',
          ),

          // Logout button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            onPressed: _showLogoutDialog,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Use PageView for better performance than IndexedStack
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe
            children: _buildScreens(),
          ),

          // Bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}
