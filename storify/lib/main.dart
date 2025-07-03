// lib/main.dart
// COMPLETE ROUTING IMPLEMENTATION WITH YOUR EXISTING AUTH SERVICE
// ✅ Works with your token-based authentication system
// ✅ Supports role switching capabilities
// ✅ Added real-time authentication checks for all route changes
// ✅ Added proper redirect logic for unauthorized access
// ✅ Simple and clean implementation without unnecessary complexity
import 'dart:ui' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Screens/changePassword.dart';
import 'package:storify/Registration/Screens/changedThanks.dart';
import 'package:storify/Registration/Screens/emailCode.dart';
import 'package:storify/Registration/Screens/forgotPassword.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/productOverview.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/admin/screens/track.dart';
import 'package:storify/admin/screens/vieworder.dart';
import 'package:storify/customer/screens/orderScreenCustomer.dart';
import 'package:storify/customer/screens/historyScreenCustomer.dart';
import 'package:storify/supplier/screens/ordersScreensSupplier.dart';
import 'package:storify/supplier/screens/productScreenSupplier.dart';
import 'package:storify/employee/screens/orders_screen.dart';
import 'package:storify/employee/screens/order_history_screen.dart';
import 'package:storify/employee/screens/viewOrderScreenEmp.dart';
import 'package:storify/utilis/firebase_options.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart';

// This must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  try {
    debugPrint('🚀 Starting Storify app...');

    // ✅ ROUTING: Remove # from URLs for cleaner web experience
    usePathUrlStrategy();
    debugPrint('✅ URL strategy configured for clean web URLs');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Give SharedPreferences time to load properly on web
    await Future.delayed(const Duration(milliseconds: 100));

    runApp(MyApp());
    debugPrint('✅ App started successfully');

    _initializeNotificationsLater();
  } catch (e) {
    debugPrint('❌ Error in main: $e');
    runApp(MyApp());
  }
}

void _initializeNotificationsLater() {
  Future.delayed(Duration(seconds: 2), () async {
    try {
      debugPrint('🔔 Starting background notification initialization...');

      await NotificationService.initialize();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Foreground message received: ${message.messageId}");
      });

      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          debugPrint("App opened from terminated state by notification");
          Future.delayed(Duration(seconds: 1), () {
            handleNotificationNavigation(message.data);
          });
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("App opened from background state by notification");
        handleNotificationNavigation(message.data);
      });

      NotificationService().processBackgroundNotifications();
      NotificationService().loadNotificationsFromFirestore();

      debugPrint('✅ Notifications initialized in background');
    } catch (e) {
      debugPrint('❌ Error initializing notifications (non-critical): $e');
    }
  });
}

void handleNotificationNavigation(Map<String, dynamic> data) {
  final notificationType = data['type'] as String?;
  final orderId = data['orderId'] as String?;
  debugPrint("Should navigate to: type=$notificationType, orderId=$orderId");
}

// ✅ SIMPLE ROUTE GUARD - Works with your existing AuthService
class RouteGuard extends StatefulWidget {
  final Widget child;
  final String requiredRole;
  final String routeName;

  const RouteGuard({
    Key? key,
    required this.child,
    required this.requiredRole,
    required this.routeName,
  }) : super(key: key);

  @override
  State<RouteGuard> createState() => _RouteGuardState();
}

class _RouteGuardState extends State<RouteGuard> {
  bool _isLoading = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _validateAccess();
  }

  Future<void> _validateAccess() async {
    try {
      debugPrint('🔐 Validating access for route: ${widget.routeName}');

      // ✅ CHECK 1: Is user logged in with required role?
      final hasRequiredRole =
          await AuthService.isLoggedInAsRole(widget.requiredRole);

      if (!hasRequiredRole) {
        debugPrint('🚫 User not logged in as ${widget.requiredRole}');
        setState(() {
          _isLoading = false;
          _isAuthorized = false;
        });
        _handleUnauthorizedAccess();
        return;
      }

      // ✅ CHECK 2: Is the current active role correct?
      final currentRole = await AuthService.getCurrentRole();

      if (currentRole != widget.requiredRole) {
        debugPrint(
            '🔄 Current role ($currentRole) != required role (${widget.requiredRole})');

        // Try to switch to the required role
        final switched = await AuthService.switchToRole(widget.requiredRole);

        if (!switched) {
          debugPrint('🚫 Failed to switch to required role');
          setState(() {
            _isLoading = false;
            _isAuthorized = false;
          });
          _handleUnauthorizedAccess();
          return;
        }

        debugPrint('✅ Successfully switched to ${widget.requiredRole}');
      }

      // ✅ CHECK 3: Verify token is still valid
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('🚫 No valid token found');
        setState(() {
          _isLoading = false;
          _isAuthorized = false;
        });
        _handleUnauthorizedAccess();
        return;
      }

      // ✅ ALL CHECKS PASSED
      debugPrint('✅ Access granted to ${widget.routeName}');
      setState(() {
        _isLoading = false;
        _isAuthorized = true;
      });
    } catch (e) {
      debugPrint('❌ Error validating access: $e');
      setState(() {
        _isLoading = false;
        _isAuthorized = false;
      });
      _handleUnauthorizedAccess();
    }
  }

  void _handleUnauthorizedAccess() {
    if (!mounted) return;

    // Show unauthorized message and redirect to login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
          arguments: {
            'message':
                'Please log in as ${widget.requiredRole} to access this page',
            'redirectUrl': widget.routeName,
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying access...'),
            ],
          ),
        ),
      );
    }

    if (!_isAuthorized) {
      // Show loading while redirect happens
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('Redirecting to login...'),
            ],
          ),
        ),
      );
    }

    // ✅ ACCESS GRANTED - Show the protected content
    return widget.child;
  }
}

// ✅ ENHANCED LOGIN SCREEN - Shows unauthorized access messages
class EnhancedLoginScreen extends StatelessWidget {
  const EnhancedLoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final message = args?['message'] as String?;
    final redirectUrl = args?['redirectUrl'] as String?;

    return Scaffold(
      body: Column(
        children: [
          if (message != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[800]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LoginScreen(), // Your existing login screen
          ),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 Building MyApp widget');

    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Storify',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

        // ✅ ROUTING: COMPLETE named routes with PROTECTION
        routes: {
          // ═══════════════════════════════════════════════════════════════
          // PUBLIC ROUTES (No authentication required)
          // ═══════════════════════════════════════════════════════════════
          '/login': (context) => const EnhancedLoginScreen(),
          '/forgot-password': (context) => const Forgotpassword(),
          '/email-code': (context) => const Emailcode(),
          '/change-password': (context) => _buildChangePasswordRoute(context),
          '/changed-thanks': (context) => const Changedthanks(),

          // ═══════════════════════════════════════════════════════════════
          // PROTECTED ADMIN ROUTES
          // ═══════════════════════════════════════════════════════════════
          '/admin': (context) => RouteGuard(
                child: const DashboardScreen(),
                requiredRole: 'Admin',
                routeName: '/admin',
              ),
          '/admin/dashboard': (context) => RouteGuard(
                child: const DashboardScreen(),
                requiredRole: 'Admin',
                routeName: '/admin/dashboard',
              ),
          '/admin/categories': (context) => RouteGuard(
                child: const CategoriesScreen(),
                requiredRole: 'Admin',
                routeName: '/admin/categories',
              ),
          '/admin/products': (context) => RouteGuard(
                child: const Productsscreen(),
                requiredRole: 'Admin',
                routeName: '/admin/products',
              ),
          '/admin/orders': (context) => RouteGuard(
                child: const Orders(),
                requiredRole: 'Admin',
                routeName: '/admin/orders',
              ),
          '/admin/roles': (context) => RouteGuard(
                child: const Rolemanegment(),
                requiredRole: 'Admin',
                routeName: '/admin/roles',
              ),
          '/admin/tracking': (context) => RouteGuard(
                child: const Track(),
                requiredRole: 'Admin',
                routeName: '/admin/tracking',
              ),

          // ═══════════════════════════════════════════════════════════════
          // PROTECTED CUSTOMER ROUTES
          // ═══════════════════════════════════════════════════════════════
          '/customer': (context) => RouteGuard(
                child: const CustomerOrders(),
                requiredRole: 'Customer',
                routeName: '/customer',
              ),
          '/customer/orders': (context) => RouteGuard(
                child: const CustomerOrders(),
                requiredRole: 'Customer',
                routeName: '/customer/orders',
              ),
          '/customer/history': (context) => RouteGuard(
                child: const HistoryScreenCustomer(),
                requiredRole: 'Customer',
                routeName: '/customer/history',
              ),

          // ═══════════════════════════════════════════════════════════════
          // PROTECTED SUPPLIER ROUTES
          // ═══════════════════════════════════════════════════════════════
          '/supplier': (context) => RouteGuard(
                child: const SupplierOrders(),
                requiredRole: 'Supplier',
                routeName: '/supplier',
              ),
          '/supplier/orders': (context) => RouteGuard(
                child: const SupplierOrders(),
                requiredRole: 'Supplier',
                routeName: '/supplier/orders',
              ),
          '/supplier/products': (context) => RouteGuard(
                child: const SupplierProducts(),
                requiredRole: 'Supplier',
                routeName: '/supplier/products',
              ),

          // ═══════════════════════════════════════════════════════════════
          // PROTECTED WAREHOUSE EMPLOYEE ROUTES
          // ═══════════════════════════════════════════════════════════════
          '/warehouse': (context) => RouteGuard(
                child: const Orders_employee(),
                requiredRole: 'WareHouseEmployee',
                routeName: '/warehouse',
              ),
          '/warehouse/orders': (context) => RouteGuard(
                child: const Orders_employee(),
                requiredRole: 'WareHouseEmployee',
                routeName: '/warehouse/orders',
              ),
          '/warehouse/history': (context) => RouteGuard(
                requiredRole: 'WareHouseEmployee',
                routeName: '/warehouse/history',
                child: const OrderHistoryScreen(),
              ),
        },

        // ✅ ROUTING: Smart initial route determination
        initialRoute:
            '/login', // Always start with login, then redirect properly

        // ✅ ROUTING: Enhanced route generation with protection
        onGenerateRoute: (RouteSettings settings) {
          debugPrint('🔄 Generating route: ${settings.name}');

          // ═══════════════════════════════════════════════════════════════
          // PARAMETERIZED ROUTES WITH PROTECTION
          // ═══════════════════════════════════════════════════════════════

          if (settings.name?.startsWith('/admin/product/') == true) {
            return MaterialPageRoute(
              builder: (_) => RouteGuard(
                child: const Productsscreen(),
                requiredRole: 'Admin',
                routeName: settings.name!,
              ),
              settings: settings,
            );
          }

          if (settings.name?.startsWith('/admin/order/') == true) {
            return MaterialPageRoute(
              builder: (_) => RouteGuard(
                child: const Orders(),
                requiredRole: 'Admin',
                routeName: settings.name!,
              ),
              settings: settings,
            );
          }

          if (settings.name?.startsWith('/warehouse/order/') == true) {
            return MaterialPageRoute(
              builder: (_) => RouteGuard(
                child: const Orders_employee(),
                requiredRole: 'WareHouseEmployee',
                routeName: settings.name!,
              ),
              settings: settings,
            );
          }

          // ✅ HANDLE ROOT ROUTE WITH SMART REDIRECT
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (_) => SmartRootRedirect(),
              settings: settings,
            );
          }

          return null;
        },

        // ✅ ROUTING: Better error handling
        onUnknownRoute: (RouteSettings settings) {
          debugPrint('❌ Unknown route: ${settings.name}');
          return MaterialPageRoute(
            builder: (_) => const EnhancedLoginScreen(),
            settings: const RouteSettings(name: '/login'),
          );
        },
      ),
    );
  }

  Widget _buildChangePasswordRoute(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;

    if (args != null && args.containsKey('email') && args.containsKey('code')) {
      return Changepassword(
        email: args['email']!,
        code: args['code']!,
      );
    }

    return const Emailcode();
  }
}

// ✅ SMART ROOT REDIRECT - Works with your AuthService
class SmartRootRedirect extends StatefulWidget {
  @override
  State<SmartRootRedirect> createState() => _SmartRootRedirectState();
}

class _SmartRootRedirectState extends State<SmartRootRedirect> {
  @override
  void initState() {
    super.initState();
    _performSmartRedirect();
  }

  Future<void> _performSmartRedirect() async {
    try {
      // ✅ GET CURRENT ROLE AND CHECK IF LOGGED IN
      final currentRole = await AuthService.getCurrentRole();

      if (currentRole == null) {
        debugPrint('🔍 No current role, checking for any logged in roles...');

        // Check if user is logged in with any role
        final loggedInRoles = await AuthService.getLoggedInRoles();

        if (loggedInRoles.isEmpty) {
          debugPrint('🚫 No logged in roles found, redirecting to login');
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }

        // Switch to the first available role
        final firstRole = loggedInRoles.first;
        await AuthService.switchToRole(firstRole);
        debugPrint('🔄 Switched to available role: $firstRole');
        _redirectToRoleDashboard(firstRole);
        return;
      }

      // ✅ VALIDATE CURRENT ROLE HAS VALID TOKEN
      final hasValidToken = await AuthService.isLoggedInAsRole(currentRole);

      if (!hasValidToken) {
        debugPrint('🚫 Current role has no valid token, redirecting to login');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // ✅ VALID SESSION - Redirect to appropriate dashboard
      debugPrint('✅ Valid session for role: $currentRole');
      _redirectToRoleDashboard(currentRole);
    } catch (e) {
      debugPrint('❌ Error in smart redirect: $e');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _redirectToRoleDashboard(String role) {
    String targetRoute;
    switch (role) {
      case 'Admin':
        targetRoute = '/admin';
        break;
      case 'Customer':
        targetRoute = '/customer';
        break;
      case 'Supplier':
        targetRoute = '/supplier';
        break;
      case 'WareHouseEmployee':
        targetRoute = '/warehouse';
        break;
      default:
        targetRoute = '/login';
    }

    Navigator.pushReplacementNamed(context, targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your dashboard...'),
          ],
        ),
      ),
    );
  }
}

// ✅ OPTIONAL: Role Switcher Widget for users with multiple roles
class RoleSwitcher extends StatefulWidget {
  @override
  State<RoleSwitcher> createState() => _RoleSwitcherState();
}

class _RoleSwitcherState extends State<RoleSwitcher> {
  String? currentRole;
  List<String> availableRoles = [];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final current = await AuthService.getCurrentRole();
    final available = await AuthService.getLoggedInRoles();

    setState(() {
      currentRole = current;
      availableRoles = available;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (availableRoles.length <= 1) {
      return SizedBox.shrink(); // Don't show if only one role
    }

    return PopupMenuButton<String>(
      icon: Icon(Icons.account_circle),
      tooltip: 'Switch Role',
      onSelected: (String role) async {
        if (role != currentRole) {
          final success = await AuthService.switchToRole(role);
          if (success) {
            // Redirect to new role's dashboard
            switch (role) {
              case 'Admin':
                Navigator.pushNamedAndRemoveUntil(
                    context, '/admin', (route) => false);
                break;
              case 'Customer':
                Navigator.pushNamedAndRemoveUntil(
                    context, '/customer', (route) => false);
                break;
              case 'Supplier':
                Navigator.pushNamedAndRemoveUntil(
                    context, '/supplier', (route) => false);
                break;
              case 'WareHouseEmployee':
                Navigator.pushNamedAndRemoveUntil(
                    context, '/warehouse', (route) => false);
                break;
            }
          }
        }
      },
      itemBuilder: (BuildContext context) {
        return availableRoles.map((String role) {
          return PopupMenuItem<String>(
            value: role,
            child: Row(
              children: [
                if (role == currentRole) Icon(Icons.check, size: 16),
                if (role == currentRole) SizedBox(width: 8),
                Text(role),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

// Test credentials (remove in production)
// admin - hamode.sh889@gmail.com - 123123 - id: 84
// supplier ahmad - hamode.sh334@gmail.com - yism5huFJGy6SfI- - id: 4
// customer - momoideh.123@yahoo.com - dHaeo_HFzzUEcYFH
// warehouse worker - mohammad.shaheen0808@gmail.com - 0S_1NPyVo-CQ5-EO
