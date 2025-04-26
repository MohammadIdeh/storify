import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/supplier/screens/ordersScreensSupplier.dart';
import 'package:storify/supplier/screens/productScreenSupplier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use the AuthService to check login status
  final isLoggedIn = await AuthService.isLoggedIn();
  final currentRole = await AuthService.getCurrentRole();

  runApp(MyApp(isLoggedIn: isLoggedIn, currentRole: currentRole));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? currentRole;

  const MyApp({super.key, required this.isLoggedIn, this.currentRole});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _getHomeScreen(),
      ),
    );
  }

  Widget _getHomeScreen() {
    if (!isLoggedIn) {
      return const LoginScreen();
    }

    // Navigate based on role
    switch (currentRole) {
      case 'Admin':
        return const DashboardScreen();
      case 'Supplier':
        return const SupplierProducts();
      // Add cases for other roles
      case 'Customer':
      // return CustomerScreen();
      case 'Employee':
      // return EmployeeScreen();
      case 'DeliveryMan':
      // return DeliveryManScreen();
      default:
        // If role is unknown or not set properly, return to login
        return const LoginScreen();
    }
  }
}
//admin
// hamode.sh889@gmail.com
// o83KUqRz-UIroMoI
// id: 84

//supplier
// hamode.sh334@gmail.com
// yism5huFJGy6SfI-
