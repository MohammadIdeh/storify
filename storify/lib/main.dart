import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/track.dart';
// import other screens as required

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check for token before running the app
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080), // Set to laptop screen size
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // Removes the debug banner
        home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }
}
// hamode.sh889@gmail.com
// o83KUqRz-UIroMoI
// id: 84
