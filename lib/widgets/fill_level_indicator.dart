import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FillLevelIndicator extends StatelessWidget {
  final double fillLevel; // 0.0 to 1.0
  final Color color;

  const FillLevelIndicator({
    super.key,
    required this.fillLevel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (fillLevel * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fillLevel.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    backgroundColor: AppColors.bgCardLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fillLevel > 0.85
                          ? AppColors.accentRed
                          : fillLevel > 0.6
                              ? AppColors.accentOrange
                              : color,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct%',
              style: TextStyle(
                color: fillLevel > 0.85
                    ? AppColors.accentRed
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
