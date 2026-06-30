import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PingIndicator extends StatelessWidget {
  const PingIndicator({super.key, required this.pingMs});

  final int? pingMs;

  Color get _color {
    if (pingMs == null) return AppColors.textDim;
    if (pingMs! < 80) return AppColors.green;
    if (pingMs! < 150) return AppColors.gold;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (pingMs == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${pingMs}ms',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _color),
      ),
    );
  }
}
