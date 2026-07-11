import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'yesa_effects.dart';

/// Neon menü kutucuğu — animasyonlu, yüksek kontrast.
class YesaMenuTile extends StatelessWidget {
  const YesaMenuTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.subtitle,
    this.featured = false,
    this.accent = false,
    this.iconColor,
    this.staggerIndex = 0,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? subtitle;
  final bool featured;
  final bool accent;
  final Color? iconColor;
  final int staggerIndex;

  @override
  Widget build(BuildContext context) {
    final titleStyle = featured
        ? AppTextStyles.tileFeatured
        : AppTextStyles.tileLabel.copyWith(
            color: accent ? AppColors.beyaz : AppColors.beyaz,
          );
    final subColor = featured
        ? AppColors.morDahaKoyu.withValues(alpha: 0.65)
        : AppColors.textMuted;

    final icColor = iconColor ??
        (featured
            ? AppColors.morDahaKoyu
            : accent
                ? AppColors.beyaz
                : AppColors.sariAna);

    final iconGradient = featured
        ? null
        : accent
            ? AppGradients.tileAccent
            : AppGradients.neonPurple;

    Widget tile = ScalePress(
      onTap: onPressed,
      child: Container(
        decoration: YesaDecor.menuTile(featured: featured, accent: accent),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 92,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cam parlaması — üst yarıda çapraz beyaz süzülme.
              Positioned(
                top: -30,
                left: -20,
                right: -20,
                height: 62,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: -0.12,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.beyaz.withValues(alpha: featured ? 0.22 : 0.10),
                            AppColors.beyaz.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: YesaDecor.iconTile(
                        color: featured ? AppColors.beyaz.withValues(alpha: 0.35) : null,
                        gradient: iconGradient,
                      ),
                      child: Icon(icon, size: 20, color: icColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subColor, fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (featured) {
      tile = GlowPulse(color: AppColors.sariAna, child: tile);
    }

    return StaggerIn(index: staggerIndex, child: tile);
  }
}

/// 3 veya 4 sütunlu kompakt grid.
class YesaMenuGrid extends StatelessWidget {
  const YesaMenuGrid({
    super.key,
    required this.children,
    this.columns = 3,
    this.spacing = 10,
    this.startIndex = 0,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, math.min(i + columns, children.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < children.length ? spacing : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                Expanded(
                  child: j < slice.length ? slice[j] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class YesaSectionLabel extends StatelessWidget {
  const YesaSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: AppGradients.heroPlay,
              borderRadius: BorderRadius.circular(2),
              boxShadow: AppShadows.neon(AppColors.sariAna, blur: 6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: AppColors.lavanta,
              letterSpacing: 1.4,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.anaMor.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Altın neon şerit banner.
class YesaRibbon extends StatelessWidget {
  const YesaRibbon({super.key, required this.text, this.icon = Icons.sports_esports_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlowPulse(
      color: AppColors.sariAna,
      min: 0.25,
      max: 0.6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: YesaDecor.highlightBanner(radius: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.morDahaKoyu),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTextStyles.tileFeatured.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
