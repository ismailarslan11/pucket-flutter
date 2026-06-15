import 'package:flutter/material.dart';

class AppColors {
  static const green = Color(0xFF7EC820);
  static const darkGreen = Color(0xFF5A9A10);
  static const red = Color(0xFFE83030);
  static const blue = Color(0xFF3080E8);
  static const gold = Color(0xFFF0C040);
  static const bg = Color(0xFF111111);
  static const card = Color(0xFF1E1E1E);
  static const border = Color(0xFF333333);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.green,
          secondary: AppColors.gold,
          surface: AppColors.card,
        ),
      );
}
