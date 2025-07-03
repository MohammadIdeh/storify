// lib/GeneralWidgets/snackBar.dart
// Fixed version with proper positioning and auto-dismiss
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

void showCustomSnackBar(BuildContext context, String message, String iconPath) {
  // Remove any existing snack bars first
  ScaffoldMessenger.of(context).removeCurrentSnackBar();

  final snackBar = SnackBar(
    content: Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 20.w,
          height: 20.h,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
    backgroundColor: iconPath.contains('success')
        ? const Color(0xFF4CAF50)
        : iconPath.contains('error')
            ? const Color(0xFFE53E3E)
            : const Color(0xFF7B5CFA),
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
      bottom: 20.h,
      left: 20.w,
      right: 20.w,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.r),
    ),
    elevation: 6,
    // Ensure proper positioning
    dismissDirection: DismissDirection.horizontal,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);

  // Auto-dismiss after duration to prevent stacking
  Future.delayed(const Duration(seconds: 3), () {
    try {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    } catch (e) {
      // Ignore if context is no longer valid
    }
  });
}

// Alternative method using overlay for better control
void showOverlaySnackBar(
    BuildContext context, String message, String iconPath) {
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 20.h,
      left: 20.w,
      right: 20.w,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: iconPath.contains('success')
                ? const Color(0xFF4CAF50)
                : iconPath.contains('error')
                    ? const Color(0xFFE53E3E)
                    : const Color(0xFF7B5CFA),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                iconPath,
                width: 20.w,
                height: 20.h,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);

  // Auto-remove after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    try {
      overlayEntry.remove();
    } catch (e) {
      // Ignore if already removed
    }
  });
}
