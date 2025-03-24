import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class Profilepopup extends StatefulWidget {
  const Profilepopup({super.key});

  @override
  State<Profilepopup> createState() => _ProfilepopupState();
}

class _ProfilepopupState extends State<Profilepopup> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      height: 290.h,
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3C4E),
        borderRadius: BorderRadius.circular(16.0.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Image
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/me.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Abu Ideh',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Admin',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 30.h),
          Padding(
            padding: EdgeInsets.only(left: 40.0.w),
            child: InkWell(
              onTap: () {
                print("settings");
              },
              child: Row(
                children: [
                  SizedBox(width: 8.w),
                  SvgPicture.asset(
                    'assets/images/settings2.svg',
                    width: 24.w,
                    height: 24.h,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Settings',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.only(left: 40.0.w),
            child: InkWell(
              onTap: () {
                print("logogogo");
              },
              child: Row(
                children: [
                  SizedBox(width: 8.w),
                  SvgPicture.asset(
                    'assets/images/logout.svg',
                    width: 24.w,
                    height: 24.h,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Log Out',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
