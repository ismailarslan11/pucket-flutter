import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PucketLogo extends StatelessWidget {
  const PucketLogo({
    super.key,
    this.height = 140,
    this.showTagline = false,
    this.compact = false,
  });

  static const assetPath = 'assets/images/pucket_logo.png';
  static const iconPath = 'assets/images/app_icon.png';
  static const _logoAspect = 1024 / 558;

  final double height;
  /// Eski marka alt satırı; yeni logo kendi yazısını içerir.
  final bool showTagline;
  /// Küçük ikon (app icon) — duraklatma menüsü vb.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final useIcon = compact || height <= 56;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(useIcon ? height * 0.22 : 16),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandBlue.withValues(alpha: 0.22),
                blurRadius: useIcon ? 12 : 28,
                offset: Offset(0, useIcon ? 4 : 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(useIcon ? height * 0.22 : 16),
            child: Image.asset(
              useIcon ? iconPath : assetPath,
              height: height,
              width: useIcon ? height : height * _logoAspect,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _fallback(height, useIcon),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback(double h, bool square) {
    return Container(
      height: h,
      width: square ? h : h * _logoAspect,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'P',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
