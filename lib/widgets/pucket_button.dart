import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'yesa_effects.dart';

class PucketButton extends StatelessWidget {
  const PucketButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.primary = false,
    this.color,
    this.shadowColor,
    this.gradient,
    this.subtitle,
    this.width = 270,
    this.enabled = true,
    this.pulse = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;
  final bool primary;
  final Color? color;
  final Color? shadowColor;
  final Gradient? gradient;
  final String? subtitle;
  final double width;
  final bool enabled;
  /// Önemli buton: yumuşak nabız animasyonuyla öne çıkar.
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width - 48;
    final btnWidth = width > maxW ? maxW : width;
    const radius = 20.0;

    if (secondary) {
      return SizedBox(
        width: btnWidth,
        child: ScalePress(
          onTap: enabled ? onPressed : null,
          scale: enabled ? 0.96 : 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.secondaryBtn,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.buzMavi.withValues(alpha: 0.4), width: 1.2),
              boxShadow: AppShadows.depth(AppColors.laciDerin),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: enabled ? AppColors.textMuted : AppColors.textFaint,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      );
    }

    final isHero = primary || gradient == AppGradients.play || gradient == AppGradients.heroPlay;
    final bgGradient = gradient ?? (isHero ? AppGradients.heroPlay : AppGradients.neonPurple);
    final glowColor = shadowColor ?? (isHero ? AppColors.sariAna : AppColors.acikMavi);
    final textColor = isHero ? AppColors.laciDerin : AppColors.beyaz;

    return SizedBox(
      width: btnWidth,
      child: ScalePress(
        onTap: enabled ? onPressed : null,
        scale: enabled ? 0.95 : 1,
        child: PulseScale(
          enabled: pulse && enabled,
          child: GlowPulse(
          color: glowColor,
          min: enabled ? 0.3 : 0,
          max: enabled ? 0.7 : 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: color != null ? null : bgGradient,
              color: color,
              border: Border.all(
                color: AppColors.beyaz.withValues(alpha: isHero ? 0.5 : 0.25),
                width: 1.5,
              ),
              boxShadow: enabled ? AppShadows.depth(glowColor) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Üst parlaklık — 3D derinlik
                Positioned(
                  top: 0,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.45),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: subtitle != null ? 12 : 15,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled ? textColor : textColor.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: subtitle != null ? 13 : 14,
                          shadows: isHero
                              ? [
                                  Shadow(
                                    color: AppColors.beyaz.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor.withValues(alpha: enabled ? 0.7 : 0.35),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
