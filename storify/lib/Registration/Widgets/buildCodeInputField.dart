// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildCodeInputField({
  required TextEditingController controller,
  required FocusNode focusNode,
  required VoidCallback onChanged,
}) {
  return Container(
    width: 60.w, // Scaled width
    height: 60.h, // Scaled height
    decoration: BoxDecoration(
      border: Border.all(
        color: focusNode.hasFocus
            ? const Color.fromARGB(255, 105, 65, 198)
            : Colors.grey,
      ),
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: TextField(
      cursorColor: Color.fromARGB(255, 165, 163, 163),
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: GoogleFonts.inter(color: Colors.white),
      maxLength: 1,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        border: InputBorder.none,
        fillColor: Colors.transparent,
        filled: true,
        counterText: "",
      ),
      onChanged: (value) {
        if (value.length == 1) {
          onChanged();
        }
      },
    ),
  );
}
