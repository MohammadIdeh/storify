import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? hintText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.suffixIcon,
    this.hintText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          cursorColor: AppColors.primary,
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
            ),
            suffixIcon: suffixIcon,
            errorStyle: const TextStyle(
              color: AppColors.error,
            ),
          ),
          onFieldSubmitted: onSubmitted,
        ),
      ],
    );
  }
}
