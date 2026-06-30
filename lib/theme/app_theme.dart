import 'package:flutter/material.dart';

/// PUCKET logo renk paleti + UI semantik renkleri.
class AppColors {
  // ── Resmi logo paleti ──
  static const brandBlue = Color(0xFF0088CC);
  static const brandOrange = Color(0xFFFF6600);
  static const nightBlue = Color(0xFF004488);
  static const darkOrange = Color(0xFFCC4400);
  static const silverWhite = Color(0xFFE0F7FA);
  static const silver = Color(0xFFC0C0C0);
  static const fieldBlue = Color(0xFF44AAEE);
  static const accentYellow = Color(0xFFFFCC00);

  // ── Geriye dönük alias'lar (mevcut kod kırılmasın) ──
  static const purple = brandBlue;
  static const purpleLight = fieldBlue;
  static const purpleDark = nightBlue;
  static const pink = brandOrange;
  static const cyan = fieldBlue;
  static const yellow = accentYellow;
  static const green = brandBlue;
  static const darkGreen = nightBlue;
  static const gold = accentYellow;
  static const navy = nightBlue;
  static const charcoal = Color(0xFF1A3355);

  /// Oyun takımları — logo turuncu / mavi
  static const red = brandOrange;
  static const blue = brandBlue;

  // ── Yüzeyler ──
  static const bg = Color(0xFF001A33);
  static const bgDeep = Color(0xFF000F22);
  static const card = Color(0xFF002845);
  static const cardElevated = Color(0xFF003355);
  static const border = Color(0xFF005588);
  static const borderSubtle = Color(0xFF003D66);

  // ── Metin ──
  static const textPrimary = silverWhite;
  static const textMuted = Color(0xFF99B8CC);
  static const textDim = Color(0xFF6688AA);
  static const textFaint = Color(0xFF446688);
}

class AppGradients {
  static const screenBg = RadialGradient(
    center: Alignment(0, -0.35),
    radius: 1.25,
    colors: [AppColors.nightBlue, AppColors.bg],
  );

  static const screenBgWarm = RadialGradient(
    center: Alignment(0, -0.35),
    radius: 1.25,
    colors: [Color(0xFF663300), AppColors.bg],
  );

  static const boardBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF001F40), AppColors.bgDeep],
  );

  static const brand = LinearGradient(
    colors: [AppColors.brandBlue, AppColors.fieldBlue],
  );

  static const ranked = LinearGradient(
    colors: [AppColors.nightBlue, AppColors.brandBlue],
  );

  static const play = LinearGradient(
    colors: [AppColors.brandOrange, AppColors.darkOrange],
  );

  static const career = LinearGradient(
    colors: [AppColors.darkOrange, AppColors.nightBlue],
  );

  static const accent = LinearGradient(
    colors: [AppColors.brandBlue, AppColors.nightBlue],
  );

  static const secondaryBtn = LinearGradient(
    colors: [AppColors.cardElevated, AppColors.card],
  );
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.brandBlue,
          onPrimary: AppColors.silverWhite,
          secondary: AppColors.brandOrange,
          onSecondary: AppColors.silverWhite,
          tertiary: AppColors.accentYellow,
          surface: AppColors.card,
          onSurface: AppColors.silverWhite,
          outline: AppColors.border,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textMuted),
          titleLarge: TextStyle(color: AppColors.silverWhite, fontWeight: FontWeight.w900),
          labelLarge: TextStyle(color: AppColors.silverWhite, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.textMuted),
        dividerColor: AppColors.borderSubtle,
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.brandBlue),
      );
}
