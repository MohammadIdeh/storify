import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6941C6);
  static const secondary = Color(0xFF1D2939);
  static const background = Color(0xFF1D2939);
  static const card = Color(0xFF304050);
  static const accent = Color(0xFF7C66B9);
  static const text = Colors.white;
  static const textSecondary = Color(0xAAFFFFFF);
  static const error = Colors.redAccent;
  static const success = Color(0xFF4CAF50);
}

class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.text,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
}
