import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart'; // for SVG assets
import 'package:google_fonts/google_fonts.dart';

class AddCategoryPanel extends StatefulWidget {
  final void Function(
          String categoryName, bool isActive, String image, String description)?
      onPublish;
  final VoidCallback? onCancel;

  const AddCategoryPanel({Key? key, this.onPublish, this.onCancel})
      : super(key: key);

  @override
  State<AddCategoryPanel> createState() => _AddCategoryPanelState();
}

class _AddCategoryPanelState extends State<AddCategoryPanel> {
  String _categoryName = "";
  bool _isActive = true;
  String _description = "";

  // Default placeholder image. When _image equals this, no custom image has been chosen.
  final String _defaultImage = 'assets/images/defaultCategory.png';
  String _image = 'assets/images/defaultCategory.png';

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Fixed container for upload image.
        Container(
          margin: EdgeInsets.symmetric(vertical: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 36, 50, 69),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            width: 700,
            height: 500.h,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 28, 36, 46),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: InkWell(
              onTap: _pickImage,
              child: _image == _defaultImage
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/gallery.svg',
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
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.network(
                        _image,
                        width: 700,
                        height: 500.h,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        SizedBox(width: 100.w),
        // Right side: Expanded container that takes remaining width.
        Expanded(
          child: Container(
            height: 535.h,
            margin: EdgeInsets.symmetric(vertical: 16.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 36, 50, 69),
              borderRadius: BorderRadius.circular(16.r),
            ),
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
                  "Description",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  onChanged: (value) {
                    _description = value;
                  },
                  maxLines: 3,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromARGB(255, 54, 68, 88),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    hintText: "Enter Description",
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
                SizedBox(height: 70.h),
                // Bottom Row: Cancel and Publish Category.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 20.h),
                        side: const BorderSide(
                            color: Color.fromARGB(255, 105, 123, 123),
                            width: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: widget.onCancel,
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 105, 65, 198),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 25.h),
                      ),
                      onPressed: () {
                        final name = _categoryName.trim();
                        if (widget.onPublish != null && name.isNotEmpty) {
                          widget.onPublish!(
                              name, _isActive, _image, _description);
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
          ),
        ),
      ],
    );
  }
}
