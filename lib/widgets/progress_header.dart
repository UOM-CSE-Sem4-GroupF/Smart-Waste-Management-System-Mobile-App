import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProgressHeader extends StatelessWidget {
  final int collected;
  final int total;
  final String zoneName;
  final VoidCallback? onBack;

  const ProgressHeader({
    super.key,
    required this.collected,
    required this.total,
    required this.zoneName,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 8),
          // Zone name
          Expanded(
            child: Text(
              zoneName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Progress pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.accentTeal.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text(
                  '$collected / $total',
                  style: const TextStyle(
                    color: AppColors.accentTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('✅', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
