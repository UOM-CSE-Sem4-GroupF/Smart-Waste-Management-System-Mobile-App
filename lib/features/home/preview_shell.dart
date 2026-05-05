import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../job/job_complete_preview_screen.dart';
import '../login/login_preview_screen.dart';
import 'home_preview_screen.dart';

final previewIndexProvider = StateProvider<int>((ref) => 0);

class PreviewShell extends ConsumerWidget {
  const PreviewShell({super.key});

  static const List<Widget> _pages = [
    HomePreviewBody(),
    MapPreviewBody(),
    HistoryPreviewBody(),
    JobCompletePreviewScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(previewIndexProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final bgColor = isDark ? AppColors.bgPrimary : const Color(0xFFF0F4F8);
    final navBg = isDark ? AppColors.bgPrimary : Colors.white;
    final dividerColor = isDark ? AppColors.divider : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: _pages[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: dividerColor, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(previewIndexProvider.notifier).state = index;
          },
          backgroundColor: navBg,
          selectedItemColor: AppColors.accentTeal,
          unselectedItemColor:
              isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'HOME'),
            BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'MAP'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'HISTORY'),
            BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline),
                activeIcon: Icon(Icons.check_circle),
                label: 'COMPLETED'),
          ],
        ),
      ),
    );
  }
}

// ── Theme toggle button (shared across pages) ─────────────────────────────────
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    return GestureDetector(
      onTap: () {
        ref.read(themeModeProvider.notifier).state =
            isDark ? ThemeMode.light : ThemeMode.dark;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardLight : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.divider : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: isDark ? AppColors.accentYellow : const Color(0xFF6366F1),
          size: 20,
        ),
      ),
    );
  }
}

// ── Profile dropdown (shared across home pages) ───────────────────────────────
class ProfileDropdown extends ConsumerWidget {
  const ProfileDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: isDark ? AppColors.bgCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: isDark ? AppColors.divider : const Color(0xFFE2E8F0)),
      ),
      elevation: 8,
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'John Driver',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : const Color(0xFF0F1117),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'DRIVER #1024',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Divider(color: isDark ? AppColors.divider : const Color(0xFFE2E8F0)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 18,
                  color: isDark ? AppColors.textSecondary : const Color(0xFF374151)),
              const SizedBox(width: 10),
              Text(
                'Profile Details',
                style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : const Color(0xFF0F1117)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined,
                  size: 18,
                  color: isDark ? AppColors.textSecondary : const Color(0xFF374151)),
              const SizedBox(width: 10),
              Text(
                'Settings',
                style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : const Color(0xFF0F1117)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded,
                  size: 18, color: AppColors.accentRed),
              const SizedBox(width: 10),
              const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const LoginPreviewScreen(),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 350),
            ),
            (route) => false,
          );
        } else if (value == 'profile') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Details — coming soon')),
          );
        } else if (value == 'settings') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings — coming soon')),
          );
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accentTeal, width: 2),
          image: const DecorationImage(
            image: NetworkImage('https://i.pravatar.cc/150?u=1024'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// ── Map Page (standby) ────────────────────────────────────────────────────────
class MapPreviewBody extends ConsumerWidget {
  const MapPreviewBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    const standbyCenter = LatLng(6.9271, 79.8612);
    final demoMarkers = [
      _makeMarker(const LatLng(6.9271, 79.8612), AppColors.accentTeal, Icons.delete_rounded),
      _makeMarker(const LatLng(6.9310, 79.8650), AppColors.accentGreen, Icons.check_rounded),
      _makeMarker(const LatLng(6.9230, 79.8580), AppColors.textMuted, Icons.delete_rounded),
      _makeMarker(const LatLng(6.9290, 79.8700), AppColors.textMuted, Icons.delete_rounded),
    ];

    return Stack(
      children: [
        // Full-screen OSM tile map
        FlutterMap(
          options: const MapOptions(
            initialCenter: standbyCenter,
            initialZoom: 13.5,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.groupf.waste_collect_driver',
            ),
            MarkerLayer(markers: demoMarkers),
          ],
        ),
        // Top status banner
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.bgCard : Colors.white)
                    .withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark ? AppColors.divider : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.bgCardLight
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isDark
                              ? AppColors.divider
                              : const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.map_outlined,
                        color: AppColors.accentTeal, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NO ACTIVE JOB',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimary
                                : const Color(0xFF0F1117),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Standby — waiting for assignment',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondary
                                : const Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.accentYellow.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: AppColors.accentYellow),
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
                ],
              ),
            ),
          ),
        ),
        // Theme toggle in top-right
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: const ThemeToggleButton(),
        ),
      ],
    );
  }

  Marker _makeMarker(LatLng point, Color color, IconData icon) {
    return Marker(
      point: point,
      width: 38,
      height: 38,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ── History Page ──────────────────────────────────────────────────────────────
class HistoryPreviewBody extends ConsumerWidget {
  const HistoryPreviewBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF0F1117);
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final dividerColor =
        isDark ? AppColors.divider : const Color(0xFFE2E8F0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Job History',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: textPrimary, fontWeight: FontWeight.bold),
                ),
                const ThemeToggleButton(),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              color: AppColors.accentBlue, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Job #82$index',
                                  style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold)),
                              Text('Oct 2${5 - index}, 2023 · 12 Bins',
                                  style: TextStyle(
                                      color: isDark
                                          ? AppColors.textSecondary
                                          : const Color(0xFF6B7280),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('1,240 kg',
                            style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
