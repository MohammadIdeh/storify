import 'package:deliveryman/screens/historyScreen.dart';
import 'package:deliveryman/screens/orderScreen.dart';
import 'package:deliveryman/widgets/map.dart';
import 'package:deliveryman/widgets/navbar.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _hasInitialized = false;

  final List<String> _screenTitles = ['Map', 'Orders', 'History'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize services and fetch data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _fetchData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only fetch data if we haven't initialized yet
    // This prevents the infinite loop during build
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Use addPostFrameCallback to avoid setState during build
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchData();
        }
      });
    }
  }

  void _initializeServices() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    final locationService =
        Provider.of<LocationService>(context, listen: false);

    // Set token for services
    orderService.updateToken(authService.token);
    locationService.updateToken(authService.token);

    // Initialize location
    locationService.getCurrentLocation();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final orderService = Provider.of<OrderService>(context, listen: false);

    try {
      await orderService.fetchAssignedOrders();

      // Fetch completed orders if we're on the history tab
      if (_currentIndex == 2) {
        await orderService.fetchCompletedOrders();
      }
    } catch (e) {
      print('Error fetching data: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Fetch specific data when switching tabs
    final orderService = Provider.of<OrderService>(context, listen: false);

    if (index == 1) {
      // Orders tab
      orderService.fetchAssignedOrders();
    } else if (index == 2) {
      // History tab
      orderService.fetchCompletedOrders();
    }
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
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1D2939),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF304050),
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: 30,
              height: 30,
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6941C6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF6941C6),
                size: 20,
              ),
            ),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
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
          IndexedStack(
            index: _currentIndex,
            children: [
              MapScreen(onRefresh: _fetchData),
              OrdersScreen(
                isLoading: _isLoading,
                onRefresh: _fetchData,
              ),
              HistoryScreen(
                isLoading: _isLoading,
                onRefresh: _fetchData,
              ),
            ],
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
