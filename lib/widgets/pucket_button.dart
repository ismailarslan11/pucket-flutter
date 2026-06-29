import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PucketButton extends StatelessWidget {
  const PucketButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.color,
    this.shadowColor,
    this.gradient,
    this.subtitle,
    this.width = 270,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;
  final Color? color;
  final Color? shadowColor;
  final Gradient? gradient;
  final String? subtitle;
  final double width;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width - 48;
    final btnWidth = width > maxW ? maxW : width;

    if (secondary) {
      return SizedBox(
        width: btnWidth,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFAAAAAA),
            side: const BorderSide(color: Color(0xFF444444), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
          ),
        ),
      );
    }

    final bg = color ?? AppColors.green;
    final shadow = shadowColor ?? AppColors.darkGreen;
    final textColor = gradient != null || bg.computeLuminance() < 0.45 ? Colors.white : Colors.black;

    return SizedBox(
      width: btnWidth,
      child: Material(
        color: gradient == null ? bg : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: gradient == null ? bg : null,
              gradient: gradient,
              boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 5), blurRadius: 0)],
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: subtitle != null ? 12 : 14, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      fontSize: subtitle != null ? 15 : 17,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
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
