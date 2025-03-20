import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class MyNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MyNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<MyNavigationBar> createState() => _MyNavigationBarState();
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  final List<String> _navItems = [
    'Dashboard',
    'Products',
    'Orders',
    'Stores',
    'More',
  ];

  final List<String?> _navIcons = [
    'assets/images/home.svg',
    'assets/images/products.svg',
    'assets/images/orders.svg',
    'assets/images/stores.svg',
    null,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10.h),
      width: double.infinity,
      height: 90.h,
      color: const Color.fromARGB(255, 29, 41, 57),
      padding: EdgeInsets.only(left: 45, right: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/logo.svg',
                width: 35.w,
                height: 35.h,
              ),
              SizedBox(width: 12.w),
              Text(
                'Storify',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final text = entry.value;
              final bool isSelected = (index == widget.currentIndex);
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onTap(index),
                  child: Container(
                    margin: EdgeInsets.only(left: 24.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 105, 65, 198) // Purple
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromARGB(0, 0, 0, 0)
                            : const Color.fromARGB(255, 34, 53,
                                62), // rgba(34, 53, 62, 1)Gray border
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Row(
                      children: [
                        if (_navIcons[index] != null &&
                            _navIcons[index]!.isNotEmpty)
                          SvgPicture.asset(
                            _navIcons[index]!,
                            width: 24.w,
                            height: 24.h,
                            // ignore: deprecated_member_use
                            color: isSelected
                                ? Colors.white
                                : const Color.fromARGB(255, 105, 123, 123),
                          ),
                        if (_navIcons[index] != null &&
                            _navIcons[index]!.isNotEmpty)
                          SizedBox(width: 9.w),
                        Text(
                          text,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15.sp,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color.fromARGB(255, 105, 123, 123),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  // Handle search action
                },
                child: Container(
                  width: 50.w,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 50, 69),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(13.0),
                    child: SvgPicture.asset('assets/images/search.svg'),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              InkWell(
                onTap: () {
                  // Handle notification action
                },
                child: Container(
                  width: 50.w,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 50, 69),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(13.0),
                    child: SvgPicture.asset(
                      'assets/images/noti.svg',
                      width: 20.w,
                      height: 20.h,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              InkWell(
                onTap: () {},
                child: Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/me.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Icon(
                size: 35,
                Icons.arrow_drop_down,
                color: Color.fromARGB(255, 105, 123, 123),
              ),
            ],
          )
        ],
      ),
    );
  }
}
