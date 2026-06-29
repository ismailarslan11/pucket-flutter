import 'package:flutter/material.dart';

/// Marka renkleri — logo paleti (mor, pembe, mavi, sarı).
class AppColors {
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFA855F7);
  static const purpleDark = Color(0xFF5B21B6);
  static const pink = Color(0xFFEC4899);
  static const cyan = Color(0xFF38BDF8);
  static const yellow = Color(0xFFFBBF24);
  static const navy = Color(0xFF1E1B4B);
  static const charcoal = Color(0xFF2D3748);

  /// UI vurgu — eski `green` kullanan ekranlar otomatik marka rengine geçer.
  static const green = purple;
  static const darkGreen = purpleDark;
  static const gold = yellow;

  /// Oyun takımları (kırmızı / mavi diskler)
  static const red = Color(0xFFE83030);
  static const blue = Color(0xFF3080E8);

  static const bg = Color(0xFF0D0D12);
  static const card = Color(0xFF18181F);
  static const border = Color(0xFF2A2A38);
}

class AppGradients {
  static const screenBg = RadialGradient(
    center: Alignment(0, -0.4),
    radius: 1.2,
    colors: [Color(0xFF1A1035), AppColors.bg],
  );

  static const brand = LinearGradient(
    colors: [AppColors.purple, AppColors.purpleLight],
  );

  static const ranked = LinearGradient(
    colors: [AppColors.purpleDark, AppColors.purple],
  );

  static const play = LinearGradient(
    colors: [AppColors.pink, AppColors.purple],
  );
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.purple,
          secondary: AppColors.yellow,
          tertiary: AppColors.pink,
          surface: AppColors.card,
        ),
      );
}
