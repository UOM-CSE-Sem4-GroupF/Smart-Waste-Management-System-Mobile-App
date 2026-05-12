import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/job.dart';
import '../../theme/app_theme.dart';

final _historyProvider = FutureProvider<List<Job>>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      ApiEndpoints.collectionJobs,
      queryParameters: {
        'assigned_driver_id': 'me',
        'state': 'COMPLETED',
        'limit': '50',
      },
    );
    final list = response.data['data'] as List? ?? [];
    return list.map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
  } catch (_) {
    return _mockHistory();
  }
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Job History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: historyAsync.when(
        data: (jobs) => _buildList(context, jobs),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentTeal),
        ),
        error: (e, _) => Center(
          child: Text('Could not load history',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Job> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_turned_in_outlined,
                size: 64, color: AppColors.accentTeal.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No completed jobs yet',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ],
        ),
      );
    }

    // Group by day
    final grouped = <String, List<Job>>{};
    for (final job in jobs) {
      final key = DateFormat('EEEE, d MMMM').format(job.assignedAt);
      grouped.putIfAbsent(key, () => []).add(job);
    }

    // Monthly stats
    final monthJobs = jobs.length;
    final monthBins = jobs.fold<int>(0, (a, j) => a + j.binsCollected);
    final monthWeight = jobs.fold<double>(0, (a, j) => a + j.actualWeightKg);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'This Week', 'This Month'].map((label) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: label == 'All',
                  onSelected: (_) {},
                  selectedColor:
                      AppColors.accentTeal.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.accentTeal,
                  backgroundColor: isDark ? AppColors.bgCardLight : Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Grouped job cards
        ...grouped.entries.toList().asMap().entries.map((mapEntry) {
          final idx = mapEntry.key;
          final entry = mapEntry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...entry.value.asMap().entries.map((e) {
                return _JobHistoryCard(job: e.value)
                    .animate()
                    .fadeIn(delay: ((idx * 3 + e.key) * 60).ms)
                    .slideX(begin: -0.05);
              }),
            ],
          );
        }),

        const SizedBox(height: 16),
        // Monthly summary
        _buildMonthlySummary(context, monthJobs, monthBins, monthWeight),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMonthlySummary(
      BuildContext context, int jobs, int bins, double weight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentTeal.withValues(alpha: 0.12),
            AppColors.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.accentTeal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This month',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              _MonthlyStat(label: 'Jobs', value: '$jobs'),
              const SizedBox(width: 8),
              _MonthlyStat(label: 'Bins', value: '$bins'),
              const SizedBox(width: 8),
              _MonthlyStat(
                  label: 'Weight',
                  value: '${(weight / 1000).toStringAsFixed(1)} t'),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobHistoryCard extends StatelessWidget {
  final Job job;
  const _JobHistoryCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/history/${job.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.divider : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentTeal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.zoneName,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleSmall?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _SmallStat(
                          icon: Icons.restore_from_trash_rounded,
                          text: '${job.binsCollected} bins'),
                      const SizedBox(width: 10),
                      if (job.duration != null)
                        _SmallStat(
                            icon: Icons.timer_outlined,
                            text: '${job.duration!.inMinutes} min'),
                      const SizedBox(width: 10),
                      _SmallStat(
                          icon: Icons.fitness_center_rounded,
                          text: '${job.actualWeightKg.toInt()} kg'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(job.assignedAt),
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SmallStat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(text,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _MonthlyStat extends StatelessWidget {
  final String label;
  final String value;
  const _MonthlyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  color: AppColors.accentTeal,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// Mock data for testing without a backend
List<Job> _mockHistory() => [];
