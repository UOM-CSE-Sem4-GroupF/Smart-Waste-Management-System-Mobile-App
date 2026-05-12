import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/env.dart';
import '../../models/bin_stop.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh job state on enter
    Future.microtask(() => ref.invalidate(jobProvider));
  }

  Future<void> _onRefresh() async {
    ref.invalidate(jobProvider);
    await ref.read(jobProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(currentDriverProvider);
    final jobAsync = ref.watch(jobProvider);
    final statsAsync = ref.watch(driverStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accentTeal,
          backgroundColor: isDark ? AppColors.bgCardLight : Colors.white,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: _buildHeader(
                  driver != null ? driver.name : 'John',
                  driver != null ? driver.id.toString() : '1024',
                  driver != null ? driver.vehicleName : 'LORRY-03',
                  driver != null ? driver.zoneName : 'Zone 3',
                ),
              ),
              // Map Preview (Moved Up)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _buildMapPreviewCard(context),
                ),
              ),
              // Current Jobs Section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT JOBS',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              // Content: Job List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: jobAsync.when(
                  data: (job) => _buildCurrentJobsList(context, job),
                  loading: () => SliverToBoxAdapter(child: _buildLoadingCard()),
                  error: (_, __) => _buildCurrentJobsList(context, null),
                ),
              ),
              // Bottom actions
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHistoryButton(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(String name, String driverId, String vehicle, String zone) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: avatar + driver ID
              Row(
                children: [
                  _buildProfileDropdown(context, driverId),
                  const SizedBox(width: 12),
                  Text(
                    '#$driverId',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                  ),
                ],
              ),
              // Right: theme toggle + notification icon
              Row(
                children: [
                  _buildNotificationIcon(),
                  const SizedBox(width: 8),
                  _buildThemeToggle(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            '$greeting, $name',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  vehicle.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '·  $zone',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildNoJobCard(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    return Column(
      children: [
        // Status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'View available jobs',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        const SizedBox(height: 20),
        // Today's performance
        statsAsync.when(
          data: (stats) => _buildStatsCard(context, stats),
          loading: () => _buildLoadingCard(),
          error: (_, __) => _buildStatsCard(context, {}),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, Map<String, dynamic> stats) {
    final jobs = stats['jobs_today'] ?? 3;
    final bins = stats['bins_today'] ?? 28;
    final weight = stats['weight_today_kg'] ?? 1240;
    const progress = 0.45; // Fixed for design match

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S PERFORMANCE",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'JOBS', value: '$jobs'),
              _StatItem(label: 'BINS', value: '$bins'),
              _StatItem(label: 'WEIGHT', value: '$weight', suffix: ' kg'),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
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
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildMapPreviewCard(BuildContext context) {
    final jobAsync = ref.watch(jobProvider);
    final job = jobAsync.valueOrNull;

    // Demo markers for when no job is active (Colombo, Sri Lanka)
    const fallbackCenter = LatLng(6.9271, 79.8612);
    final demoMarkers = <Marker>[
      _makePreviewMarker(const LatLng(6.9271, 79.8612), AppColors.accentTeal),
      _makePreviewMarker(const LatLng(6.9310, 79.8650), AppColors.accentGreen),
      _makePreviewMarker(const LatLng(6.9230, 79.8580), AppColors.textMuted),
      _makePreviewMarker(const LatLng(6.9290, 79.8700), AppColors.textMuted),
    ];

    final center = job != null && job.stops.isNotEmpty
        ? LatLng(job.stops.first.lat, job.stops.first.lng)
        : fallbackCenter;

    final markers = job != null
        ? job.stops.map((s) {
            Color color;
            switch (s.status) {
              case StopStatus.completed:
                color = AppColors.accentGreen;
                break;
              case StopStatus.current:
                color = AppColors.accentTeal;
                break;
              case StopStatus.pending:
                color = AppColors.textMuted;
                break;
            }
            return _makePreviewMarker(LatLng(s.lat, s.lng), color);
          }).toList()
        : demoMarkers;

    final zoneLabel = job != null
        ? job.zoneName.toUpperCase()
        : 'NO ACTIVE JOB — STANDBY';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            // ── Live map ──────────────────────────────────────────────────
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  key: ValueKey(AppEnv.mapTileUrl(context)),
                  urlTemplate: AppEnv.mapTileUrl(context),
                  userAgentPackageName:
                      'com.groupf.waste_collect_driver',
                  retinaMode: false,
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            // ── Top badge ─────────────────────────────────────────────────
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.divider, width: 0.5),
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
            // ── Bottom overlay ────────────────────────────────────────────
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
                      Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: 0.92),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.accentTeal, size: 14),
                          const SizedBox(height: 2),
                          Text(
                            zoneLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.9,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.push('/job/active/map'),
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

  /// Tiny circular dot marker used in the home-screen preview card.
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

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: AppColors.bgPrimary,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'MAP'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'HISTORY'),
        ],
        onTap: (index) {
          if (index == 1) context.push('/job/active/map');
          if (index == 2) context.push('/history');
        },
      ),
    );
  }


  Widget _buildActiveJobCard(BuildContext context, job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentTeal.withValues(alpha: 0.15),
            AppColors.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 8, color: AppColors.accentOrange),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE JOB',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.accentOrange,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'You have an active job',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '${job.zoneName} · ${job.binsRemaining} bins remaining',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/job/active/map'),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Continue job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.accentTeal),
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/history'),
        icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
        label: const Text('View job history', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgCard,
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDropdown(BuildContext context, String driverId) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.divider),
      ),
      elevation: 8,
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'John Driver',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'DRIVER #$driverId',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Divider(color: AppColors.divider),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 18, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Text('Profile Details',
                  style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded,
                  size: 18, color: AppColors.accentRed),
              SizedBox(width: 10),
              Text('Logout',
                  style: TextStyle(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          await ref.read(keycloakServiceProvider.notifier).logout();
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          context.go('/login');
        } else if (value == 'profile') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Details — coming soon')),
          );
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accentTeal, width: 2),
          color: AppColors.accentTeal.withValues(alpha: 0.1),
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.accentTeal,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications — coming soon')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.divider : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          Icons.notifications_outlined,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Consumer(
      builder: (context, ref, _) {
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
              color: isDark ? AppColors.bgCardLight : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.divider : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark
                  ? AppColors.accentYellow
                  : const Color(0xFF6366F1),
              size: 20,
            ),
          ),
        );
      },
    );
  }

  // ── Current Jobs List ──────────────────────────────────────────────────────

  Widget _buildCurrentJobsList(BuildContext context, Job? job) {
    final List<BinStop> stops = job?.stops ?? _getDummyStops();

    if (stops.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Center(
            child: Text(
              'No jobs available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _JobListItem(
              stop: stops[index],
              isDummy: job == null,
            ),
          );
        },
        childCount: stops.length,
      ),
    );
  }

  List<BinStop> _getDummyStops() {
    return [
      BinStop(
        clusterId: 'dummy-1',
        clusterName: 'WTC - Colombo 01',
        lat: 6.9328,
        lng: 79.8438,
        stopIndex: 0,
        status: StopStatus.pending,
        bins: [
          Bin(id: 'bin-d1a', type: BinType.general, fillLevel: 0.85, estimatedWeightKg: 12.0),
          Bin(id: 'bin-d1b', type: BinType.plastic, fillLevel: 0.60, estimatedWeightKg: 5.0),
          Bin(id: 'bin-d1c', type: BinType.paper,   fillLevel: 0.70, estimatedWeightKg: 7.0),
        ],
      ),
      BinStop(
        clusterId: 'dummy-2',
        clusterName: 'Gangaramaya Temple',
        lat: 6.9168,
        lng: 79.8580,
        stopIndex: 1,
        status: StopStatus.current,
        bins: [
          Bin(id: 'bin-d2a', type: BinType.food,    fillLevel: 0.90, estimatedWeightKg: 18.0),
          Bin(id: 'bin-d2b', type: BinType.general, fillLevel: 0.50, estimatedWeightKg: 8.0),
        ],
      ),
      BinStop(
        clusterId: 'dummy-3',
        clusterName: 'Galle Face Green',
        lat: 6.9272,
        lng: 79.8433,
        stopIndex: 2,
        status: StopStatus.completed,
        bins: [
          Bin(id: 'bin-d3a', type: BinType.glass,   fillLevel: 0.75, estimatedWeightKg: 20.0),
          Bin(id: 'bin-d3b', type: BinType.metal,   fillLevel: 0.40, estimatedWeightKg: 15.0),
          Bin(id: 'bin-d3c', type: BinType.plastic, fillLevel: 0.55, estimatedWeightKg: 6.0),
          Bin(id: 'bin-d3d', type: BinType.paper,   fillLevel: 0.65, estimatedWeightKg: 9.0),
        ],
      ),
    ];
  }
}

class _JobListItem extends ConsumerStatefulWidget {
  final BinStop stop;
  final bool isDummy;

  const _JobListItem({required this.stop, this.isDummy = false});

  @override
  ConsumerState<_JobListItem> createState() => _JobListItemState();
}

class _JobListItemState extends ConsumerState<_JobListItem> {
  late StopStatus _localStatus;

  @override
  void initState() {
    super.initState();
    _localStatus = widget.stop.status;
  }

  StopStatus get _displayStatus =>
      widget.isDummy ? _localStatus : widget.stop.status;

  void _onStatusTap() {
    context.push(
      Uri(
        path: '/job/active/map',
        queryParameters: {
          'lat': widget.stop.lat.toString(),
          'lng': widget.stop.lng.toString(),
        },
      ).toString(),
    );

    final next = _getNextStatus(_displayStatus);
    if (widget.isDummy) {
      setState(() => _localStatus = next);
    } else {
      ref.read(jobProvider.notifier).updateStopStatus(widget.stop.clusterId, next);
    }
  }

  StopStatus _getNextStatus(StopStatus status) {
    switch (status) {
      case StopStatus.pending:
        return StopStatus.current;
      case StopStatus.current:
        return StopStatus.completed;
      case StopStatus.completed:
        return StopStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _displayStatus;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stop.clusterName,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleSmall?.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Stop #${widget.stop.stopIndex + 1}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusButton(status),
        ],
      ),
    );
  }

  Widget _buildStatusButton(StopStatus status) {
    String label;
    Color color;

    switch (status) {
      case StopStatus.pending:
        label = 'START';
        color = AppColors.accentYellow;
        break;
      case StopStatus.current:
        label = 'IN PROGRESS';
        color = AppColors.accentGreen;
        break;
      case StopStatus.completed:
        label = 'COMPLETED';
        color = AppColors.accentRed;
        break;
    }

    return GestureDetector(
      onTap: _onStatusTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64 * _anim.value,
            height: 64 * _anim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.1 * _anim.value),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.2),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;

  const _StatItem({
    required this.label,
    required this.value,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (suffix != null)
              Text(
                suffix!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
        ),
      ],
    );
  }
}
