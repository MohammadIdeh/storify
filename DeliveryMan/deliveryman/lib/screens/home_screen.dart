import 'package:deliveryman/screens/historyScreen.dart';
import 'package:deliveryman/screens/orderScreen.dart';
import 'package:deliveryman/widgets/map.dart';
import 'package:deliveryman/widgets/navbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchData();
        }
      });
    }
  }

  void _initializeServices() {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      final locationService =
          Provider.of<LocationService>(context, listen: false);

      // Set token for services
      if (authService.token != null) {
        orderService.updateToken(authService.token);
        locationService.updateToken(authService.token);

        // Initialize location in background
        locationService.getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

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

  void _fetchTabSpecificData(int index) {
    final orderService = Provider.of<OrderService>(context, listen: false);

    switch (index) {
      case 0: // Map
      case 1: // Orders tab
        orderService.fetchAssignedOrders();
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
      MapScreen(onRefresh: _fetchData),
      OrdersScreen(
        isLoading: _isLoading,
        onRefresh: _fetchData,
      ),
      EnhancedHistoryScreen(
        isLoading: _isLoading,
        onRefresh: _fetchData,
      ),
    ];

    return _cachedScreens!;
  }

  void _showProfilePopup() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF304050),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6941C6).withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6941C6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF6941C6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Profile Information',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Profile Picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6941C6),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: user.profilePicture != null &&
                          user.profilePicture!.isNotEmpty
                      ? Image.network(
                          user.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: const Color(0xFF6941C6).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF6941C6),
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF6941C6).withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF6941C6),
                            size: 40,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // User Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D2939),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6941C6).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    _buildProfileInfoRow(
                      Icons.person_outline,
                      'Name',
                      user.name,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildProfileInfoRow(
                      Icons.email_outlined,
                      'Email',
                      user.email,
                    ),
                    const SizedBox(height: 16),

                    // Role
                    _buildProfileInfoRow(
                      Icons.work_outline,
                      'Role',
                      user.roleName,
                    ),
                    const SizedBox(height: 16),

                    // User ID
                    _buildProfileInfoRow(
                      Icons.badge_outlined,
                      'Employee ID',
                      user.userId.toString(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active - On Duty',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6941C6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: const Color(0xAAFFFFFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
          // Profile button
          Consumer<AuthService>(
            builder: (context, authService, child) {
              final user = authService.currentUser;
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6941C6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: user?.profilePicture != null &&
                          user!.profilePicture!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            user.profilePicture!,
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

          // Refresh button
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
            onPressed: _isLoading ? null : _fetchData,
            tooltip: 'Refresh',
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
