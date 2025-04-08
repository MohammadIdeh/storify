import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/productOverview.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/widgets/product_item_Model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(1920, 1080), // Set to laptop screen size
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
          debugShowCheckedModeBanner: false, // Removes the debug banner
          home: DashboardScreen()),
    );
  }
}
