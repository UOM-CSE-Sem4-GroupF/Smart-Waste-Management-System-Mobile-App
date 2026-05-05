import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../models/bin_stop.dart';
import '../../models/job.dart';
import '../../providers/cargo_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cargo_weight_bar.dart';
import '../../widgets/progress_header.dart';

class JobMapScreen extends ConsumerStatefulWidget {
  const JobMapScreen({super.key});

  @override
  ConsumerState<JobMapScreen> createState() => _JobMapScreenState();
}

class _JobMapScreenState extends ConsumerState<JobMapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  LatLng? _currentPosition;
  bool _proximitySheetShown = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  void _startTracking() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentPosition!, _mapController.camera.zoom);
      _checkProximity(pos);
    });
  }

  void _checkProximity(Position pos) {
    final jobAsync = ref.read(jobProvider);
    final job = jobAsync.valueOrNull;
    if (job == null || _proximitySheetShown) return;

    final nextStop = job.stops.firstWhere(
      (s) => s.status == StopStatus.current || s.status == StopStatus.pending,
      orElse: () => job.stops.last,
    );

    final distance = Geolocator.distanceBetween(
      pos.latitude, pos.longitude,
      nextStop.lat, nextStop.lng,
    );

    if (distance <= 50) {
      _proximitySheetShown = true;
      _showArrivalSheet(nextStop);
    }
  }

  void _showArrivalSheet(BinStop stop) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ArrivalSheet(stop: stop),
    ).then((_) => _proximitySheetShown = false);
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobProvider);
    final cargo = ref.watch(cargoProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return _buildStandbyMap(context);
          }
          return Stack(
            children: [
              // Full screen map
              _buildMap(job),
              // Top overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopOverlay(context, job, cargo),
              ),
              // Bottom card
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildNextStopCard(context, job),
              ),
              // Cargo warning banner
              if (cargo.isNearingLimit)
                Positioned(
                  top: 160,
                  left: 16,
                  right: 16,
                  child: _buildCargoBanner(cargo),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentTeal),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStandbyMap(BuildContext context) {
    const standbyCenter = LatLng(6.9271, 79.8612);
    final demoMarkers = [
      _makeStandbyMarker(
          const LatLng(6.9271, 79.8612), AppColors.accentTeal, Icons.delete_rounded),
      _makeStandbyMarker(
          const LatLng(6.9310, 79.8650), AppColors.accentGreen, Icons.check_rounded),
      _makeStandbyMarker(
          const LatLng(6.9230, 79.8580), AppColors.textMuted, Icons.delete_rounded),
      _makeStandbyMarker(
          const LatLng(6.9290, 79.8700), AppColors.textMuted, Icons.delete_rounded),
    ];

    return Stack(
      children: [
        // Full-screen standby map
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
        // Top banner
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bgCardLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textSecondary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NO ACTIVE JOB',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Standby — waiting for assignment',
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
                        Icon(Icons.circle,
                            size: 7, color: AppColors.accentYellow),
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
      ],
    );
  }

  Marker _makeStandbyMarker(LatLng point, Color color, IconData icon) {
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

  Widget _buildMap(Job job) {
    final waypoints = job.waypoints
        .map((w) => LatLng(w.lat, w.lng))
        .toList();

    final center = _currentPosition ??
        (job.stops.isNotEmpty
            ? LatLng(job.stops.first.lat, job.stops.first.lng)
            : const LatLng(6.9271, 79.8612));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.groupf.waste_collect_driver',
        ),
        // Route polyline
        if (waypoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: waypoints,
                strokeWidth: 4.0,
                color: AppColors.accentTeal.withValues(alpha: 0.8),
              ),
            ],
          ),
        // Stop markers
        MarkerLayer(
          markers: [
            ...job.stops.map((stop) => _buildStopMarker(stop)),
            if (_currentPosition != null) _buildVehicleMarker(),
          ],
        ),
      ],
    );
  }

  Marker _buildStopMarker(BinStop stop) {
    Color color;
    Widget icon;

    switch (stop.status) {
      case StopStatus.completed:
        color = AppColors.accentGreen;
        icon = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
        break;
      case StopStatus.current:
        color = AppColors.accentTeal;
        icon = const Icon(Icons.navigation_rounded,
            color: Colors.white, size: 16);
        break;
      case StopStatus.pending:
        color = AppColors.textMuted;
        icon = const Icon(Icons.delete_rounded, color: Colors.white, size: 14);
        break;
    }

    return Marker(
      point: LatLng(stop.lat, stop.lng),
      width: stop.status == StopStatus.current ? 44 : 36,
      height: stop.status == StopStatus.current ? 44 : 36,
      child: GestureDetector(
        onTap: () => context.push('/job/active/bin/${stop.clusterId}'),
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
          child: Center(child: icon),
        ),
      ),
    );
  }

  Marker _buildVehicleMarker() {
    return Marker(
      point: _currentPosition!,
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentBlue,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(Icons.local_shipping_rounded,
            color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildTopOverlay(
      BuildContext context, Job job, CargoState cargo) {
    return SafeArea(
      child: Column(
        children: [
          // Progress header
          ProgressHeader(
            collected: job.binsCollected,
            total: job.binsTotal,
            zoneName: job.zoneName,
            onBack: () => context.go('/home'),
          ),
          // Cargo bar
          CargoWeightBar(
            currentKg: cargo.currentKg,
            limitKg: cargo.limitKg,
          ),
        ],
      ),
    );
  }

  Widget _buildNextStopCard(BuildContext context, Job job) {
    final nextStop = job.stops.firstWhere(
      (s) => s.status == StopStatus.current || s.status == StopStatus.pending,
      orElse: () => job.stops.last,
    );

    final totalBins = nextStop.bins.length;
    final binTypes = nextStop.bins.map((b) => b.type.name).toSet().join(', ');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEXT STOP',
                  style: TextStyle(
                    color: AppColors.accentRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.accentTeal, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextStop.clusterName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalBins bin${totalBins != 1 ? 's' : ''} · $binTypes',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Arrive button
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
                    color: AppColors.accentTeal.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/job/active/bin/${nextStop.clusterId}'),
                icon: const Icon(Icons.directions_car_rounded, size: 20),
                label: const Text('ARRIVE AT STOP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoBanner(CargoState cargo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cargo.isAtLimit ? AppColors.accentRed : AppColors.accentOrange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cargo.isAtLimit
                  ? '🛑 Vehicle at capacity — return to depot'
                  : '⚠️ Nearing weight limit — ${cargo.currentKg.toInt()} / ${cargo.limitKg.toInt()} kg',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Arrival sheet ───────────────────────────────────────────────────────────

class _ArrivalSheet extends StatelessWidget {
  final BinStop stop;
  const _ArrivalSheet({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('📍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            "You've arrived at",
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(stop.clusterName,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'Ready to collect ${stop.bins.length} bin${stop.bins.length != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  child: const Text('Not yet'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/job/active/bin/${stop.clusterId}');
                  },
                  child: const Text('Start collecting'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
