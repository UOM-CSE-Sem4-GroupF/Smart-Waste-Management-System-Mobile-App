import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../home/preview_shell.dart';

class JobCompletePreviewScreen extends ConsumerWidget {
  const JobCompletePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final bgColor = isDark ? const Color(0xFF0F1117) : const Color(0xFFF0F4F8);
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F1117);
    final textSecondary =
        isDark ? const Color(0xFF6E7482) : const Color(0xFF6B7280);
    final iconBg = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFEFF6FF);
    final txBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DRIVER #1024',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        actions: [
          // Profile dropdown
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ProfileDropdown(),
          ),
          // Theme toggle
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ThemeToggleButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // ── Success Icon ────────────────────────────────────────────
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accentBlue.withValues(alpha: 0.5),
                        width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accentBlue,
                    size: 60,
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              ),
              const SizedBox(height: 32),
              Text(
                'Job Complete!',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                'Route finalized and verified successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 16),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 48),

              // ── Stats Grid ───────────────────────────────────────────────
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard('BINS COLLECTED', '11', Icons.recycling,
                      Colors.blue, cardBg, cardBorder, textPrimary, textSecondary),
                  _buildStatCard('BINS SKIPPED', '1', Icons.error_outline,
                      Colors.redAccent, cardBg, cardBorder, textPrimary, textSecondary),
                  _buildStatCard('TOTAL WEIGHT', '631 kg', Icons.scale_outlined,
                      isDark ? Colors.white70 : const Color(0xFF374151),
                      cardBg, cardBorder, textPrimary, textSecondary),
                  _buildStatCard('DURATION', '44 min', Icons.timer_outlined,
                      isDark ? Colors.white70 : const Color(0xFF374151),
                      cardBg, cardBorder, textPrimary, textSecondary),
                ],
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ── Blockchain TX ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: txBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.hub_outlined,
                          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BLOCKCHAIN TX',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'a3f7...cc12',
                            style: TextStyle(
                              color: AppColors.accentBlue.withValues(alpha: 0.85),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: txBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.copy,
                          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          size: 20),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 48),

              // ── Buttons ──────────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(previewIndexProvider.notifier).state = 1;
                },
                icon: Icon(Icons.map_outlined,
                    color: isDark ? Colors.white : const Color(0xFF0F1117)),
                label: Text(
                  'VIEW ON MAP',
                  style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F1117)),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: BorderSide(
                      color: isDark
                          ? Colors.white24
                          : const Color(0xFFD1D5DB)),
                  foregroundColor:
                      isDark ? Colors.white : const Color(0xFF0F1117),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ).animate().fadeIn(delay: 1000.ms),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(previewIndexProvider.notifier).state = 0;
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('BACK TO HOME',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ).animate().fadeIn(delay: 1100.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
