import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CargoWeightBar extends StatelessWidget {
  final double currentKg;
  final double limitKg;

  const CargoWeightBar({
    super.key,
    required this.currentKg,
    required this.limitKg,
  });

  double get _pct => limitKg > 0 ? (currentKg / limitKg).clamp(0.0, 1.0) : 0;

  Color get _barColor {
    if (_pct >= 0.9) return AppColors.accentRed;
    if (_pct >= 0.7) return AppColors.accentOrange;
    return AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.scale_rounded,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              const Text(
                'CARGO',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${currentKg.toInt()} / ${limitKg.toInt()} kg',
                style: TextStyle(
                  color: _barColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${(_pct * 100).toInt()}%)',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _pct),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.bgCardLight,
                valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
