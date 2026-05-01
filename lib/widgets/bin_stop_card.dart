import 'package:flutter/material.dart';
import '../models/bin_stop.dart';
import '../theme/app_theme.dart';
import 'fill_level_indicator.dart';
import 'status_chip.dart';

/// Compact card shown in any stop list (job detail, history).
class BinStopCard extends StatelessWidget {
  final BinStop stop;
  final VoidCallback? onTap;
  final bool isNext;
  final bool isCompleted;

  const BinStopCard({
    super.key,
    required this.stop,
    this.onTap,
    this.isNext = false,
    this.isCompleted = false,
  });

  Color get _statusColor {
    if (isCompleted) return AppColors.accentGreen;
    if (isNext) return AppColors.accentTeal;
    return AppColors.textMuted;
  }

  IconData get _statusIcon {
    if (isCompleted) return Icons.check_circle_rounded;
    if (isNext) return Icons.navigation_rounded;
    return Icons.radio_button_unchecked_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final totalBins = stop.bins.length;
    final collectedCount =
        stop.bins.where((b) => b.status == BinStatus.collected).length;
    final skippedCount =
        stop.bins.where((b) => b.status == BinStatus.skipped).length;
    final types = stop.bins.map((b) => b.type.name).toSet().join(', ');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNext
                ? AppColors.accentTeal.withValues(alpha: 0.5)
                : isCompleted
                    ? AppColors.accentGreen.withValues(alpha: 0.3)
                    : AppColors.divider,
            width: isNext ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status icon
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(_statusIcon, color: _statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stop.clusterName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (isNext)
                        StatusChip(
                          label: 'Next',
                          icon: Icons.arrow_forward_rounded,
                          color: AppColors.accentTeal,
                        ),
                      if (isCompleted)
                        StatusChip(
                          label: 'Done',
                          icon: Icons.check_rounded,
                          color: AppColors.accentGreen,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalBins bin${totalBins != 1 ? 's' : ''}'
                    '${types.isNotEmpty ? ' · $types' : ''}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  // Progress bar if some bins actioned
                  if (collectedCount + skippedCount > 0) ...[
                    const SizedBox(height: 8),
                    FillLevelIndicator(
                      fillLevel: (collectedCount + skippedCount) / totalBins,
                      color: AppColors.accentGreen,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$collectedCount collected · $skippedCount skipped',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
