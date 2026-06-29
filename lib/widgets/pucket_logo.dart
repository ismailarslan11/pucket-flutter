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

  final double height;
  final bool showTagline;
  /// Küçük ikon (app icon) — duraklatma menüsü vb.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final useIcon = compact || (!showTagline && height <= 72);
    final path = useIcon ? iconPath : assetPath;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(useIcon ? height * 0.22 : 20),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.25),
                blurRadius: useIcon ? 12 : 24,
                offset: Offset(0, useIcon ? 4 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(useIcon ? height * 0.22 : 20),
            child: Image.asset(
              path,
              height: height,
              width: useIcon ? height : null,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _fallback(height),
            ),
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 10),
          const _BrandTagline(),
        ],
      ],
    );
  }

  Widget _fallback(double h) {
    return Container(
      height: h,
      width: h,
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

class _BrandTagline extends StatelessWidget {
  const _BrandTagline();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700),
        children: [
          TextSpan(text: 'PLAY. ', style: TextStyle(color: AppColors.purple)),
          TextSpan(text: 'POCKET. ', style: TextStyle(color: AppColors.pink)),
          TextSpan(text: 'WIN.', style: TextStyle(color: AppColors.cyan)),
        ],
      ),
    );
  }
}
