import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/env.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../job/job_assignment_preview_screen.dart';
import 'preview_shell.dart';

class HomePreviewScreen extends StatelessWidget {
  const HomePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: const HomePreviewBody(),
    );
  }
}

class HomePreviewBody extends ConsumerWidget {
  const HomePreviewBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final bgColor = isDark ? AppColors.bgPrimary : const Color(0xFFF0F4F8);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, ref, isDark),
              // "Waiting for assignment" card — now with embedded bin map
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const JobAssignmentPreviewScreen()),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _buildNoJobCard(context, isDark),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildStatsCard(context, isDark),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildMapPreviewCard(context, ref, isDark),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildHistoryButton(context, ref, isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF0F1117);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Profile avatar → dropdown
                  const ProfileDropdown(),
                  const SizedBox(width: 12),
                  Text(
                    'DRIVER #1024',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: textPrimary,
                        ),
                  ),
                ],
              ),
              // Theme toggle only — WiFi removed
              const ThemeToggleButton(),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Good morning, John',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
          ),
          const Text(
            '👋',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262A34)
                      : const Color(0xFFE8F5F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LORRY-03',
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '·  Zone 3',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── "Waiting for Assignment" card — with embedded bin map ───────────────────
  Widget _buildNoJobCard(BuildContext context, bool isDark) {
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final divider = isDark ? AppColors.divider : const Color(0xFFE2E8F0);
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF0F1117);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF6B7280);

    // Demo bin markers — Colombo area
    const center = LatLng(6.9271, 79.8612);
    final binMarkers = <Marker>[
      _makeBinMarker(const LatLng(6.9271, 79.8612), AppColors.accentTeal),
      _makeBinMarker(const LatLng(6.9310, 79.8650), AppColors.accentGreen),
      _makeBinMarker(const LatLng(6.9230, 79.8580), AppColors.textMuted),
      _makeBinMarker(const LatLng(6.9290, 79.8700), AppColors.textMuted),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section: status info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 20),
                Text(
                  'View available jobs',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to review and accept new assignments',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, color: divider),
          // Bin location map
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.textSecondary
                        : const Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  'BIN LOCATIONS IN YOUR ZONE',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : const Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: SizedBox(
              height: 180,
              child: Stack(
                children: [
                  FlutterMap(
                    options: const MapOptions(
                      initialCenter: center,
                      initialZoom: 14.0,
                      interactionOptions: InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        key: ValueKey(AppEnv.mapTileUrl(context)),
                        urlTemplate: AppEnv.mapTileUrl(context),
                        userAgentPackageName: 'com.groupf.waste_collect_driver',
                        retinaMode: false,
                      ),
                      MarkerLayer(markers: binMarkers),
                    ],
                  ),
                  // "Standby" badge overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.accentYellow.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              size: 6, color: AppColors.accentYellow),
                          SizedBox(width: 5),
                          Text(
                            'STANDBY',
                            style: TextStyle(
                              color: AppColors.accentYellow,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Marker _makeBinMarker(LatLng point, Color color) {
    return Marker(
      point: point,
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats card ──────────────────────────────────────────────────────────────
  Widget _buildStatsCard(BuildContext context, bool isDark) {
    const progress = 0.45;
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final divider = isDark ? AppColors.divider : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S PERFORMANCE",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'JOBS', value: '3', isDark: isDark),
              _StatItem(label: 'BINS', value: '28', isDark: isDark),
              _StatItem(
                  label: 'WEIGHT',
                  value: '1,240',
                  suffix: ' kg',
                  isDark: isDark),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.bgCardLight
                      : const Color(0xFFE8F5F2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(progress * 100).toInt()}% OF DAILY TARGET',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : const Color(0xFF6B7280),
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ── Map preview card (full-width OSM tile map) ─────────────────────────────
  Widget _buildMapPreviewCard(
      BuildContext context, WidgetRef ref, bool isDark) {
    const center = LatLng(6.9271, 79.8612);
    final demoMarkers = <Marker>[
      _makePreviewMarker(const LatLng(6.9271, 79.8612), AppColors.accentTeal),
      _makePreviewMarker(const LatLng(6.9310, 79.8650), AppColors.accentGreen),
      _makePreviewMarker(const LatLng(6.9230, 79.8580), AppColors.textMuted),
      _makePreviewMarker(const LatLng(6.9290, 79.8700), AppColors.textMuted),
    ];
    final overlayBg =
        isDark ? AppColors.bgPrimary : const Color(0xFFF0F4F8);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: center,
                initialZoom: 14.5,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  key: ValueKey(AppEnv.mapTileUrl(context)),
                  urlTemplate: AppEnv.mapTileUrl(context),
                  userAgentPackageName: 'com.groupf.waste_collect_driver',
                  retinaMode: false,
                ),
                MarkerLayer(markers: demoMarkers),
              ],
            ),
            // Top-left badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: overlayBg.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? AppColors.divider
                          : const Color(0xFFE2E8F0),
                      width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined,
                        color: AppColors.accentTeal, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'LIVE MAP',
                      style: TextStyle(
                        color: AppColors.accentTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      overlayBg.withValues(alpha: 0.93),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.accentTeal, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'NO ACTIVE JOB — STANDBY',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F1117),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(previewIndexProvider.notifier).state = 1;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentTeal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_full_rounded,
                                color: Colors.black, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'OPEN MAP',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Marker _makePreviewMarker(LatLng point, Color color) {
    return Marker(
      point: point,
      width: 18,
      height: 18,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ── History button ─────────────────────────────────────────────────────────
  Widget _buildHistoryButton(
      BuildContext context, WidgetRef ref, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ref.read(previewIndexProvider.notifier).state = 2;
        },
        icon: Icon(Icons.history_rounded,
            color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
        label: Text(
          'View job history',
          style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F1117)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.bgCard : Colors.white,
          side: BorderSide(
              color: isDark ? AppColors.divider : const Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── Stat item ─────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    this.suffix,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF0F1117);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            if (suffix != null)
              Text(
                suffix!,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
