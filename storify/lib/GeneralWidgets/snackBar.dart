import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSnackBar extends StatefulWidget {
  final String text;
  final String svgPath;
  final Duration duration;

  const CustomSnackBar({
    Key? key,
    required this.text,
    required this.svgPath,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  _CustomSnackBarState createState() => _CustomSnackBarState();
}

class _CustomSnackBarState extends State<CustomSnackBar> {
  double _leftPosition = -300.w;
  final double _bottomPosition = 50.h;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      setState(() {
        _leftPosition = 20.w;
      });

      Future.delayed(widget.duration, () {
        setState(() {
          _leftPosition = -300.w;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      bottom: _bottomPosition,
      left: _leftPosition,
      child: Material(
        color: Colors.transparent,
        child: IntrinsicWidth(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 41, 52, 68),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  widget.svgPath,
                  width: 24.w,
                  height: 24.h,
                ),
                SizedBox(width: 10.w),
                Text(
                  widget.text,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showCustomSnackBar(BuildContext context, String text, String svgPath) {
  Overlay.of(context).insert(
    OverlayEntry(
      builder: (context) {
        return CustomSnackBar(
          text: text,
          svgPath: svgPath,
        );
      },
    ),
  );
}
