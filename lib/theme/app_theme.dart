import 'package:flutter/material.dart';

/// Yesa Studio resmi renk paleti.
class AppColors {
  AppColors._();

  // ── Mor tonları ──
  static const anaMor = Color(0xFF7C3AED);
  static const koyuMor = Color(0xFF5B21B6);
  static const morKoyu = Color(0xFF4C1D95);
  static const morDahaKoyu = Color(0xFF2E1065);
  static const acikMor = Color(0xFFA855F7);
  static const lavanta = Color(0xFFC084FC);
  static const vurguMoru = Color(0xFF8B5CF6);
  static const morumsuMavi = Color(0xFF6366F1);
  static const geceMavisi = Color(0xFF4338CA);
  static const koyuIndigo = Color(0xFF312E81);

  // ── Yeşil ──
  static const neonYesil = Color(0xFF22C55E);
  static const acikYesil = Color(0xFF4ADE80);

  // ── Sarı / turuncu ──
  static const sariAna = Color(0xFFFACC15);
  static const turuncuAcik = Color(0xFFFDBA74);
  static const turuncuAna = Color(0xFFFB923C);
  static const turuncuKoyu = Color(0xFFF97316);

  // ── Kırmızı / pembe ──
  static const mercan = Color(0xFFFF6B6B);
  static const kirmizi = Color(0xFFEF4444);
  static const pembe = Color(0xFFEC4899);

  // ── Camgöbeği ──
  static const camgobegi = Color(0xFF38BDF8);
  static const acikCamgobegi = Color(0xFF22D3EE);

  // ── Nötr ──
  static const geceLacivert = Color(0xFF1E1B4B);
  static const koyuGriMorumsu = Color(0xFF2D2A3A);
  static const ortaGri = Color(0xFF3F3D56);
  static const acikGri = Color(0xFF6B7280);
  static const acikGriAcik = Color(0xFF9CA3AF);
  static const pusluBeyaz = Color(0xFFEDE9FE);
  static const beyaz = Color(0xFFFFFFFF);

  // ── Semantik / yüzey ──
  static const bg = morKoyu;
  static const bgDeep = morDahaKoyu;
  static const card = Color(0xCC4C1D95); // morKoyu %80
  static const cardElevated = koyuMor;
  static const cardInset = morDahaKoyu;
  static const border = Color(0x55EDE9FE);
  static const borderSubtle = Color(0x33EDE9FE);
  static const borderGlow = Color(0x88A855F7);
  static const stripeLight = Color(0x407C3AED);
  static const stripeDark = Color(0x282E1065);

  static const textPrimary = beyaz;
  static const textMuted = Color(0xFFD8B4FE);
  static const textDim = Color(0xFFC4B5FD);
  static const textFaint = acikGri;

  static const success = neonYesil;
  static const error = kirmizi;

  // ── Oyun takımları (air hockey) ──
  static const teamRed = turuncuAna;
  static const teamBlue = camgobegi;

  // ── Geriye dönük alias'lar ──
  static const brandPurple = anaMor;
  static const brandPurpleDark = koyuMor;
  static const brandPurpleDeep = morDahaKoyu;
  static const brandPurpleLight = acikMor;
  static const accentYellow = sariAna;
  static const accentYellowDark = Color(0xFFEAB308);
  static const accentCream = pusluBeyaz;
  static const accentPeach = turuncuAcik;
  static const accentMint = acikYesil;
  static const accentOrange = turuncuAna;
  static const brandBlue = camgobegi;
  static const brandOrange = turuncuAna;
  static const fieldBlue = acikCamgobegi;
  static const darkOrange = turuncuKoyu;
  static const purple = acikMor;
  static const purpleLight = lavanta;
  static const purpleDark = koyuMor;
  static const pink = pembe;
  static const cyan = camgobegi;
  static const yellow = sariAna;
  static const green = neonYesil;
  static const darkGreen = koyuMor;
  static const gold = sariAna;
  static const navy = geceLacivert;
  static const charcoal = koyuGriMorumsu;
  static const red = teamRed;
  static const blue = teamBlue;
  static const nightBlue = geceMavisi;
  static const silverWhite = pusluBeyaz;
  static const silver = lavanta;
}

class AppGradients {
  AppGradients._();

  static const screenBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.geceLacivert, AppColors.morDahaKoyu, AppColors.morKoyu],
  );

  static const screenBgWarm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.morKoyu, AppColors.morDahaKoyu],
  );

  static const heroPlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.sariAna, AppColors.turuncuAna, AppColors.turuncuKoyu],
  );

  static const neonPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.acikMor, AppColors.anaMor, AppColors.koyuMor],
  );

  static const neonCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.acikCamgobegi, AppColors.camgobegi, AppColors.morumsuMavi],
  );

  static const glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCC5B21B6), Color(0xAA4C1D95)],
  );

  static const boardBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.morKoyu, AppColors.morDahaKoyu],
  );

  static const brand = LinearGradient(
    colors: [AppColors.acikMor, AppColors.anaMor],
  );

  static const ranked = LinearGradient(
    colors: [AppColors.vurguMoru, AppColors.koyuMor],
  );

  static const play = heroPlay;

  static const career = LinearGradient(
    colors: [AppColors.pembe, AppColors.turuncuAna],
  );

  static const accent = neonPurple;

  static const secondaryBtn = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x664C1D95), Color(0x882E1065)],
  );

  static const progress = LinearGradient(
    colors: [AppColors.acikCamgobegi, AppColors.sariAna, AppColors.turuncuAna],
  );

  static const tileFeatured = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.sariAna, AppColors.turuncuAna],
  );

  static const tileAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.pembe, AppColors.vurguMoru],
  );

  static const tileSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B21B6), Color(0xFF4C1D95)],
  );
}

/// Tipografi — yüksek kontrast, oyun hissi.
class AppTextStyles {
  AppTextStyles._();

  static const display = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 22,
    letterSpacing: 1.2,
    color: AppColors.beyaz,
    height: 1.1,
  );

  static const title = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 14,
    letterSpacing: 0.6,
    color: AppColors.beyaz,
  );

  static const label = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 10,
    letterSpacing: 0.8,
    color: AppColors.textMuted,
  );

  static const tileLabel = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 10,
    letterSpacing: 0.3,
    height: 1.15,
    color: AppColors.beyaz,
  );

  static const tileFeatured = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 10,
    letterSpacing: 0.4,
    height: 1.15,
    color: AppColors.morDahaKoyu,
  );

  static TextStyle glow(Color color) => TextStyle(
        fontWeight: FontWeight.w800,
        color: color,
        shadows: [
          Shadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
          Shadow(color: color.withValues(alpha: 0.35), blurRadius: 16),
        ],
      );
}

/// Neon gölge yardımcıları.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> neon(Color color, {double blur = 16, double spread = 0}) => [
        BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: blur, spreadRadius: spread),
        BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: blur * 2, spreadRadius: spread + 1),
      ];

  static List<BoxShadow> depth(Color color) => [
        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 6)),
        BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
      ];
}

/// Ortak kart / panel dekorasyonu.
class YesaDecor {
  YesaDecor._();

  static BoxDecoration card({Color? borderColor, double radius = 22}) => BoxDecoration(
        gradient: AppGradients.glassCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.borderGlow, width: 1.2),
        boxShadow: AppShadows.neon(AppColors.anaMor, blur: 20),
      );

  static BoxDecoration highlightBanner({double radius = 18}) => BoxDecoration(
        gradient: AppGradients.heroPlay,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.45), width: 1.5),
        boxShadow: AppShadows.neon(AppColors.sariAna, blur: 14),
      );

  static BoxDecoration iconTile({Color? color, Gradient? gradient}) => BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? AppColors.anaMor.withValues(alpha: 0.25)) : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.2)),
        boxShadow: AppShadows.neon(AppColors.acikMor, blur: 8),
      );

  static BoxDecoration menuTile({bool featured = false, bool accent = false}) {
    Gradient gradient;
    Color border;
    List<BoxShadow> shadows;

    if (featured) {
      gradient = AppGradients.tileFeatured;
      border = AppColors.beyaz.withValues(alpha: 0.55);
      shadows = AppShadows.neon(AppColors.sariAna, blur: 14, spread: 0);
    } else if (accent) {
      gradient = AppGradients.tileAccent;
      border = AppColors.pembe.withValues(alpha: 0.5);
      shadows = AppShadows.neon(AppColors.pembe, blur: 12);
    } else {
      gradient = AppGradients.tileSoft;
      border = AppColors.lavanta.withValues(alpha: 0.35);
      shadows = AppShadows.depth(AppColors.morDahaKoyu);
    }

    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border, width: featured ? 2 : 1.2),
      boxShadow: shadows,
    );
  }

  static BoxDecoration softTile({bool featured = false}) => menuTile(featured: featured);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.sariAna,
          onPrimary: AppColors.morDahaKoyu,
          secondary: AppColors.acikMor,
          onSecondary: AppColors.pusluBeyaz,
          tertiary: AppColors.turuncuAna,
          surface: AppColors.morKoyu,
          onSurface: AppColors.pusluBeyaz,
          outline: AppColors.border,
          error: AppColors.kirmizi,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textMuted),
          titleLarge: TextStyle(color: AppColors.pusluBeyaz, fontWeight: FontWeight.w800),
          labelLarge: TextStyle(color: AppColors.pusluBeyaz, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: AppColors.textMuted),
        dividerColor: AppColors.borderSubtle,
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.sariAna),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.koyuMor,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
