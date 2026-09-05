import 'package:flutter/material.dart';

/// Yesa Studio resmi renk paleti.
class AppColors {
  AppColors._();

  // ── Mor tonları ──
  static const anaMavi = Color(0xFF1860A8);
  static const koyuMavi = Color(0xFF0F4478);
  static const laciOrta = Color(0xFF0A2440);
  static const laciDerin = Color(0xFF061426);
  static const acikMavi = Color(0xFF1878C0);
  static const buzMavi = Color(0xFF7FC4F0);
  static const vurguMavi = Color(0xFF004890);
  static const gokMavi = Color(0xFF2A7FD0);
  static const geceMavi = Color(0xFF0B2E52);
  static const laciKoyu = Color(0xFF08203A);

  // ── Yeşil ──
  static const neonYesil = Color(0xFF22C55E);
  static const acikYesil = Color(0xFF4ADE80);

  // ── Sarı / turuncu ──
  static const sariAna = Color(0xFFFF8A3D);
  static const turuncuAcik = Color(0xFFFFB176);
  static const turuncuAna = Color(0xFFF06000);
  static const turuncuKoyu = Color(0xFFD84800);

  // ── Kırmızı / parlakMavi ──
  static const mercan = Color(0xFFFF6B4A);
  static const kirmizi = Color(0xFFEF4444);
  static const parlakMavi = Color(0xFF1878C0);

  // ── Camgöbeği ──
  static const gokAcik = Color(0xFF2A8FD8);
  static const gokDaha = Color(0xFF5CB3E8);

  // ── Nötr ──
  static const geceLacivert = Color(0xFF04101E);
  static const koyuGriMavimsi = Color(0xFF16293D);
  static const ortaGri = Color(0xFF2C4258);
  static const acikGri = Color(0xFF6B7280);
  static const acikGriAcik = Color(0xFF9CA3AF);
  static const pusluBeyaz = Color(0xFFE8F2FB);
  static const beyaz = Color(0xFFFFFFFF);

  // ── Semantik / yüzey ──
  static const bg = laciOrta;
  static const bgDeep = laciDerin;
  static const card = Color(0xCC0A2440); // laciOrta %80
  static const cardElevated = koyuMavi;
  static const cardInset = laciDerin;
  static const border = Color(0x55E8F2FB);
  static const borderSubtle = Color(0x33E8F2FB);
  static const borderGlow = Color(0x881878C0);
  static const stripeLight = Color(0x401860A8);
  static const stripeDark = Color(0x28061426);

  static const textPrimary = beyaz;
  static const textMuted = Color(0xFFC6DCEF);
  static const textDim = Color(0xFFA8C6E0);
  static const textFaint = acikGri;

  static const success = neonYesil;
  static const error = kirmizi;

  // ── Oyun takımları — SABİT: tahtadaki pul kimliği temadan bağımsız. ──
  static const teamRed = Color(0xFFFB923C);
  static const teamBlue = Color(0xFF38BDF8);

  // ── Geriye dönük alias'lar ──
  static const brandPurple = anaMavi;
  static const brandPurpleDark = koyuMavi;
  static const brandPurpleDeep = laciDerin;
  static const brandPurpleLight = acikMavi;
  static const accentYellow = sariAna;
  static const accentYellowDark = Color(0xFFCB9103);
  static const accentCream = pusluBeyaz;
  static const accentPeach = turuncuAcik;
  static const accentMint = acikYesil;
  static const accentOrange = turuncuAna;
  static const brandBlue = gokAcik;
  static const brandOrange = turuncuAna;
  static const fieldBlue = gokDaha;
  static const darkOrange = turuncuKoyu;
  static const purple = acikMavi;
  static const purpleLight = buzMavi;
  static const purpleDark = koyuMavi;
  static const pink = parlakMavi;
  static const cyan = gokAcik;
  static const yellow = sariAna;
  static const green = neonYesil;
  static const darkGreen = koyuMavi;
  static const gold = sariAna;
  static const navy = geceLacivert;
  static const charcoal = koyuGriMavimsi;
  static const red = teamRed;
  static const blue = teamBlue;
  static const nightBlue = geceMavi;
  static const silverWhite = pusluBeyaz;
  static const silver = buzMavi;
}

class AppGradients {
  AppGradients._();

  static const screenBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.geceLacivert, AppColors.laciDerin, AppColors.laciOrta],
  );

  static const screenBgWarm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.laciOrta, AppColors.laciDerin],
  );

  static const heroPlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.sariAna, AppColors.turuncuAna, AppColors.turuncuKoyu],
  );

  static const neonPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.acikMavi, AppColors.anaMavi, AppColors.koyuMavi],
  );

  static const neonCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gokDaha, AppColors.gokAcik, AppColors.gokMavi],
  );

  static const glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCC0F4478), Color(0xAA0A2440)],
  );

  static const boardBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.laciOrta, AppColors.laciDerin],
  );

  static const brand = LinearGradient(
    colors: [AppColors.acikMavi, AppColors.anaMavi],
  );

  static const ranked = LinearGradient(
    colors: [AppColors.vurguMavi, AppColors.koyuMavi],
  );

  static const play = heroPlay;

  static const career = LinearGradient(
    colors: [AppColors.parlakMavi, AppColors.turuncuAna],
  );

  static const accent = neonPurple;

  static const secondaryBtn = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x660A2440), Color(0x88061426)],
  );

  static const progress = LinearGradient(
    colors: [AppColors.gokDaha, AppColors.sariAna, AppColors.turuncuAna],
  );

  static const tileFeatured = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.sariAna, AppColors.turuncuAna],
  );

  static const tileAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.parlakMavi, AppColors.vurguMavi],
  );

  static const tileSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F4478), Color(0xFF0A2440)],
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
    color: AppColors.laciDerin,
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
/// Oyun arayüzü hissi için "basılabilir tuş" görünümü.
///
/// Menüdeki kartlar ince kenarlıklı, düz dolgulu, 16px köşeli kutulardı —
/// modern uygulama dili, ayarlar ekranı estetiği. Oyun arayüzleri fiziksel
/// durur: gövde kalındır, altında sert bir kenar vardır (düğmenin yüksekliği),
/// renk doygundur, üstten aşağı ışık geçişi hacim verir.
///
/// Sert kenar `blurRadius: 0` ile yapılır — bulanık gölge "yüzen kart",
/// bulanıksız gölge "kalın düğme" okuması verir. Fark tek satır ama izlenim
/// tamamen değişir.
/// Espor/arcade dili: eğik geometri ve konturlu tipografi.
///
/// Yatay dikdörtgen, arayüzün nötr birimidir — her uygulamada vardır, bu
/// yüzden hiçbir şey söylemez. Eğim bir yön ve hız duygusu taşır; oyunda
/// bunun karşılığı vardır (pul kayar, maç akar). Kutuyu eğip içeriği ters
/// eğerek yazıyı dik tutuyoruz, yoksa okunurluk düşer.
class Slant {
  Slant._();

  /// Kutuların eğim miktarı. Fazlası okunurluğu bozuyor, azı fark edilmiyor.
  static const double k = -0.17;

  static Matrix4 get skew => Matrix4.skewX(k);
  static Matrix4 get unskew => Matrix4.skewX(-k);
}

/// Kalın siyah konturlu başlık yazısı — spor ve arcade afişlerinin dili.
/// Düz beyaz yazı parlak zeminde eriyordu; kontur her zeminde tutuyor.
class OutlineText extends StatelessWidget {
  const OutlineText(
    this.text, {
    super.key,
    this.size = 30,
    this.stroke = 6,
    this.color = const Color(0xFFFFFFFF),
    this.strokeColor = const Color(0xFF06121F),
    this.letterSpacing = 1.5,
  });

  final String text;
  final double size;
  final double stroke;
  final Color color;
  final Color strokeColor;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: size,
      letterSpacing: letterSpacing,
      height: 1.0,
    );
    return Stack(
      children: [
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
        Text(text, style: base.copyWith(color: color)),
      ],
    );
  }
}

/// Uzay/HUD yüzeyi: köşe ayraçlı, ince ışıklı kenarlı panel.
///
/// Oyun arayüzünde "uzay" dilinin işareti kalın plastik düğme değil, gemi
/// konsolundaki gibi ince çizgili, köşeleri işaretli panellerdir. Dolgu koyu
/// ve yarı saydam kalır; ışık kenardan gelir.
/// 8-bit piksel arayüz yüzeyleri.
///
/// Piksel estetiğini veren üç kural var ve üçü de "yapmama" kuralı:
///   1. Yuvarlak köşe yok — her şey dik açı
///   2. Gradyan yok — düz renk alanları
///   3. Bulanık gölge yok — sert kaydırma, blur 0
///
/// Modern arayüz üçünü de bolca kullanır; kaldırmak tek başına görüntüyü
/// döneme taşıyor.
class PixelSurface {
  PixelSurface._();

  /// Kalın konturlu blok düğme. Alttaki sert gölge tuşun yüksekliği.
  static BoxDecoration button(Color fill, {Color? edge, double depth = 4}) {
    return BoxDecoration(
      color: fill,
      border: Border.all(color: edge ?? PixelPalette.outline, width: 3),
      boxShadow: [
        BoxShadow(color: edge ?? PixelPalette.outline, offset: Offset(0, depth)),
      ],
    );
  }

  /// İçerik paneli: koyu gövde, kalın kontur, gölge yok.
  static BoxDecoration panel({Color? fill, Color? edge}) {
    return BoxDecoration(
      color: fill ?? PixelPalette.panel,
      border: Border.all(color: edge ?? PixelPalette.outline, width: 3),
    );
  }
}

/// Referans görsellerden çıkarılan 8-bit palet. Sınırlı sayıda renk dönemin
/// işareti — çok renk kullanmak piksel hissini bozar.
class PixelPalette {
  PixelPalette._();

  static const sky = Color(0xFF5B4FE8);
  static const skyDeep = Color(0xFF4335C4);
  static const night = Color(0xFF2A1B5E);
  static const outline = Color(0xFF1A1040);
  static const panel = Color(0xFF3B2E9E);

  static const coral = Color(0xFFFF6B8A);
  static const coralDeep = Color(0xFFD93F63);
  static const mint = Color(0xFF3FBF6F);
  static const mintLight = Color(0xFF7BE0A0);
  static const gold = Color(0xFFFFC93C);
  static const lavender = Color(0xFF9B8AE8);
  static const cloud = Color(0xFFFF9EB5);
  static const white = Color(0xFFFFFFFF);
}

class HudSurface {
  HudSurface._();

  /// İkincil panel: dolgu bilinçli olarak çok düşük. Yarı saydam renk koyu
  /// zeminle karışınca kahverengiye dönüyordu; HUD'da ışık kenardan gelmeli,
  /// gövde koyu kalmalı.
  static BoxDecoration panel(Color edge, {double radius = 6, double fill = 0.10}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          edge.withValues(alpha: fill),
          const Color(0xFF040D18).withValues(alpha: 0.92),
        ],
      ),
      border: Border.all(color: edge.withValues(alpha: 0.9), width: 1.6),
      boxShadow: [
        BoxShadow(color: edge.withValues(alpha: 0.26), blurRadius: 12),
      ],
    );
  }

  /// Birincil eylem: karıştırma yok, doygun renk. Saydamlıkla elde edilen
  /// turuncu koyu zeminde çamurlaşıyordu.
  static BoxDecoration primary(Color base, {double radius = 6}) {
    final top = Color.lerp(base, const Color(0xFFFFFFFF), 0.16)!;
    final bottom = Color.lerp(base, const Color(0xFF000000), 0.22)!;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, base, bottom],
      ),
      border: Border.all(
          color: Color.lerp(base, const Color(0xFFFFFFFF), 0.55)!, width: 2),
      boxShadow: [
        BoxShadow(color: base.withValues(alpha: 0.45), blurRadius: 18),
      ],
    );
  }
}

/// Panelin dört köşesine nişan ayracı çizer — HUD dilinin en tanınır işareti.
class CornerBrackets extends StatelessWidget {
  const CornerBrackets({
    super.key,
    required this.child,
    this.color = const Color(0xFFFF8A3D),
    this.len = 12,
  });

  final Widget child;
  final Color color;
  final double len;

  @override
  Widget build(BuildContext context) {
    // passthrough: Stack çocuğun ölçüsünü aynen alır. Varsayılan davranışta
    // gevşek kısıtlarda büyüyüp ayraçları panelin dışına taşıyordu.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BracketPainter(color: color, len: len),
            ),
          ),
        ),
      ],
    );
  }
}

class _BracketPainter extends CustomPainter {
  _BracketPainter({required this.color, required this.len});

  final Color color;
  final double len;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.square
      ..color = color;
    const m = 3.0;
    final w = size.width, h = size.height;
    // sol üst
    canvas.drawLine(Offset(m, m + len), Offset(m, m), p);
    canvas.drawLine(Offset(m, m), Offset(m + len, m), p);
    // sağ üst
    canvas.drawLine(Offset(w - m - len, m), Offset(w - m, m), p);
    canvas.drawLine(Offset(w - m, m), Offset(w - m, m + len), p);
    // sol alt
    canvas.drawLine(Offset(m, h - m - len), Offset(m, h - m), p);
    canvas.drawLine(Offset(m, h - m), Offset(m + len, h - m), p);
    // sağ alt
    canvas.drawLine(Offset(w - m - len, h - m), Offset(w - m, h - m), p);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m, h - m - len), p);
  }

  @override
  bool shouldRepaint(covariant _BracketPainter old) =>
      old.color != color || old.len != len;
}

class GameSurface {
  GameSurface._();

  /// Basılabilir tuş: üstte açık, altta koyu, altında sert kenar.
  static BoxDecoration key(Color base, {double radius = 20, bool glow = true}) {
    final edge = Color.lerp(base, const Color(0xFF000000), 0.5)!;
    final top = Color.lerp(base, const Color(0xFFFFFFFF), 0.22)!;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, base],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        // Düğmenin kalınlığı — bulanıklık yok, sert kenar.
        BoxShadow(color: edge, offset: const Offset(0, 5)),
        // Zeminden ayıran yumuşak gölge.
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.38),
          offset: const Offset(0, 9),
          blurRadius: 14,
        ),
        if (glow)
          BoxShadow(color: base.withValues(alpha: 0.35), blurRadius: 18),
      ],
    );
  }

  /// Oyulmuş panel: içeriğin üstüne oturduğu koyu yüzey (görev listesi gibi).
  static BoxDecoration well({double radius = 20}) => BoxDecoration(
        color: const Color(0xFF1B0E28),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF000000).withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
            offset: const Offset(0, 1),
          ),
        ],
      );
}

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
        boxShadow: AppShadows.neon(AppColors.anaMavi, blur: 20),
      );

  static BoxDecoration highlightBanner({double radius = 18}) => BoxDecoration(
        gradient: AppGradients.heroPlay,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.45), width: 1.5),
        boxShadow: AppShadows.neon(AppColors.sariAna, blur: 14),
      );

  static BoxDecoration iconTile({Color? color, Gradient? gradient}) => BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? AppColors.anaMavi.withValues(alpha: 0.25)) : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.2)),
        boxShadow: AppShadows.neon(AppColors.acikMavi, blur: 8),
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
      border = AppColors.parlakMavi.withValues(alpha: 0.5);
      shadows = AppShadows.neon(AppColors.parlakMavi, blur: 12);
    } else {
      gradient = AppGradients.tileSoft;
      border = AppColors.buzMavi.withValues(alpha: 0.35);
      shadows = AppShadows.depth(AppColors.laciDerin);
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
          onPrimary: AppColors.laciDerin,
          secondary: AppColors.acikMavi,
          onSecondary: AppColors.pusluBeyaz,
          tertiary: AppColors.turuncuAna,
          surface: AppColors.laciOrta,
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
          backgroundColor: AppColors.koyuMavi,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
