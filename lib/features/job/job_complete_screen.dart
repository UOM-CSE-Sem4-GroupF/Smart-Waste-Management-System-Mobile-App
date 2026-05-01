import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/job_provider.dart';
import '../../providers/cargo_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/job.dart';

class JobCompleteScreen extends ConsumerStatefulWidget {
  const JobCompleteScreen({super.key});

  @override
  ConsumerState<JobCompleteScreen> createState() => _JobCompleteScreenState();
}

class _JobCompleteScreenState extends ConsumerState<JobCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationCtrl;

  @override
  void initState() {
    super.initState();
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Vibration
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _celebrationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobProvider);
    final cargo = ref.watch(cargoProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: jobAsync.when(
            data: (job) => _buildContent(context, job, cargo),
            loading: () => _buildContent(context, null, cargo),
            error: (_, __) => _buildContent(context, null, cargo),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Job? job, CargoState cargo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Celebration icon
          _buildCelebrationIcon(),
          const SizedBox(height: 24),
          // Title
          Text(
            'Job Complete!',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            'Great work today!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accentTeal,
                  fontSize: 16,
                ),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 32),
          // Summary card
          _buildSummaryCard(context, job, cargo),
          const SizedBox(height: 16),
          // Blockchain card
          if (job?.blockchainTxId != null)
            _buildBlockchainCard(context, job!.blockchainTxId!),
          const SizedBox(height: 32),
          // Actions
          _buildActions(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCelebrationIcon() {
    return AnimatedBuilder(
      animation: _celebrationCtrl,
      builder: (_, __) {
        final t = _celebrationCtrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 120 * t,
              height: 120 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen
                    .withValues(alpha: 0.08 * t),
              ),
            ),
            // Middle ring
            Container(
              width: 90 * t,
              height: 90 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen
                    .withValues(alpha: 0.15 * t),
              ),
            ),
            // Inner circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        AppColors.accentGreen.withValues(alpha: 0.4 * t),
                    blurRadius: 24 * t,
                    spreadRadius: 4 * t,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, Job? job, CargoState cargo) {
    final collected = job?.binsCollected ?? 0;
    final skipped = job?.binsSkipped ?? 0;
    final weight = cargo.currentKg;
    final duration = job?.duration;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Summary',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 20),
          // Stats grid
          Row(
            children: [
              _SummaryTile(
                icon: Icons.delete_rounded,
                label: 'Collected',
                value: '$collected',
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 10),
              _SummaryTile(
                icon: Icons.skip_next_rounded,
                label: 'Skipped',
                value: '$skipped',
                color: AppColors.accentOrange,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryTile(
                icon: Icons.scale_rounded,
                label: 'Weight',
                value: '${weight.toInt()} kg',
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 10),
              _SummaryTile(
                icon: Icons.access_time_rounded,
                label: 'Duration',
                value: duration != null
                    ? '${duration.inMinutes} min'
                    : '—',
                color: AppColors.accentTeal,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1);
  }

  Widget _buildBlockchainCard(BuildContext context, String txId) {
    final short =
        '${txId.substring(0, 6)}...${txId.substring(txId.length - 4)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded,
              color: AppColors.accentTeal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Blockchain TX',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  short,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: txId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('TX ID copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('COPY'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentTeal,
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentTeal, Color(0xFF00A888)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentTeal.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('Back to home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/history'),
          icon: const Icon(Icons.history_rounded, size: 18),
          label: const Text('View job history'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.divider),
          ),
        ).animate().fadeIn(delay: 1400.ms),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
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
