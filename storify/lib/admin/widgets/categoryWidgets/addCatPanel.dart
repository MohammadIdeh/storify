import 'dart:html' as html; // for Flutter Web image picking
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg package
import 'package:google_fonts/google_fonts.dart';

class AddCategoryPanel extends StatefulWidget {
  final void Function(String categoryName, bool isActive, String image)? onPublish;
  final VoidCallback? onCancel;

  const AddCategoryPanel({Key? key, this.onPublish, this.onCancel}) : super(key: key);

  @override
  State<AddCategoryPanel> createState() => _AddCategoryPanelState();
}

class _AddCategoryPanelState extends State<AddCategoryPanel> {
  String _categoryName = "";
  bool _isActive = true; // or false by default
  // Default placeholder image if nothing is selected.
  String _image = 'assets/images/defaultCategory.png'; 

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final html.File file = files.first;
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            _image = reader.result as String;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: "Upload Image" area on the left, Fields on the right.
          Row(
            children: [
              // Upload image placeholder with tap.
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 28, 36, 46),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SVG icon above the text.
                        SvgPicture.asset(
                          'assets/images/upload.svg',
                          width: 50.w,
                          height: 50.h,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Drag & Drop files here\n(4 mb max)",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Fields: Category name + Availability.
              Expanded(
                flex: 1,
                child: Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 28, 36, 46),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Category Name",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        onChanged: (value) {
                          _categoryName = value;
                        },
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(255, 54, 68, 88),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          hintText: "Enter category name...",
                          hintStyle: GoogleFonts.spaceGrotesk(
                            color: Colors.white54,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "Availability",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Switch(
                            value: _isActive,
                            onChanged: (val) {
                              setState(() {
                                _isActive = val;
                              });
                            },
                            activeColor: const Color.fromARGB(255, 105, 65, 198),
                          ),
                          Text(
                            _isActive ? "Active" : "Inactive",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Buttons Row: Cancel and Publish Category.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                ),
                onPressed: () {
                  if (widget.onPublish != null && _categoryName.trim().isNotEmpty) {
                    widget.onPublish!(_categoryName.trim(), _isActive, _image);
                  }
                },
                child: Text(
                  "Publish Category",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
