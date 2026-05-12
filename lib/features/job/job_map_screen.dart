import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/env.dart';
import '../../models/bin_stop.dart';
import '../../models/job.dart';
import '../../providers/cargo_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cargo_weight_bar.dart';
import '../../widgets/progress_header.dart';

class JobMapScreen extends ConsumerStatefulWidget {
  /// Optional lat/lng to initially centre the map on a specific stop.
  final double? focusLat;
  final double? focusLng;

  const JobMapScreen({super.key, this.focusLat, this.focusLng});

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
              // New Bottom Overlays (Left: Status, Right: View Bins)
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: _buildBottomControls(context, job),
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
    final focusLat = widget.focusLat;
    final focusLng = widget.focusLng;
    final isFocused = focusLat != null && focusLng != null;

    final standbyCenter = isFocused
        ? LatLng(focusLat!, focusLng!)
        : const LatLng(6.9271, 79.8612);
    final initialZoom = isFocused ? 16.0 : 13.5;

    final focusMarkers = isFocused
        ? [
            _makeStandbyMarker(
                LatLng(focusLat!, focusLng!), AppColors.accentTeal, Icons.location_on_rounded),
          ]
        : [
            _makeStandbyMarker(
                const LatLng(6.9271, 79.8612), AppColors.accentTeal, Icons.delete_rounded),
            _makeStandbyMarker(
                const LatLng(6.9310, 79.8650), AppColors.accentGreen, Icons.check_rounded),
            _makeStandbyMarker(
                const LatLng(6.9230, 79.8580), AppColors.textMuted, Icons.delete_rounded),
            _makeStandbyMarker(
                const LatLng(6.9290, 79.8700), AppColors.textMuted, Icons.delete_rounded),
          ];

    // Build a dummy stop for the View Bins dialog when focused on a specific location
    final dummyStop = isFocused
        ? BinStop(
            clusterId: 'focus-stop',
            clusterName: 'Active Stop',
            lat: focusLat!,
            lng: focusLng!,
            stopIndex: 0,
            status: StopStatus.current,
            bins: [
              Bin(id: 'bs-1', type: BinType.general,  fillLevel: 0.85, estimatedWeightKg: 12.0),
              Bin(id: 'bs-2', type: BinType.plastic,  fillLevel: 0.60, estimatedWeightKg: 5.0),
              Bin(id: 'bs-3', type: BinType.paper,    fillLevel: 0.70, estimatedWeightKg: 7.0),
            ],
          )
        : null;

    return Stack(
      children: [
        // Full-screen standby map
        FlutterMap(
          options: MapOptions(
            initialCenter: standbyCenter,
            initialZoom: initialZoom,
            interactionOptions: const InteractionOptions(
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
            MarkerLayer(markers: focusMarkers),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isFocused ? 'ACTIVE STOP' : 'NO ACTIVE JOB',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFocused
                              ? 'Tap View Bins to manage collection'
                              : 'Standby — waiting for assignment',
                          style: const TextStyle(
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
                      color: isFocused
                          ? AppColors.accentGreen.withValues(alpha: 0.15)
                          : AppColors.accentYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isFocused
                              ? AppColors.accentGreen.withValues(alpha: 0.4)
                              : AppColors.accentYellow.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            size: 7,
                            color: isFocused
                                ? AppColors.accentGreen
                                : AppColors.accentYellow),
                        const SizedBox(width: 5),
                        Text(
                          isFocused ? 'IN PROGRESS' : 'STANDBY',
                          style: TextStyle(
                            color: isFocused
                                ? AppColors.accentGreen
                                : AppColors.accentYellow,
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
        // Bottom overlays: Status badge (left) + View Bins (right)
        if (isFocused)
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Non-clickable status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.accentGreen),
                      SizedBox(width: 8),
                      Text(
                        'IN PROGRESS',
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Clickable View Bins button
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => _BinsDialog(stop: dummyStop!),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.tealGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentTeal.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.black, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'VIEW BINS',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          key: ValueKey(AppEnv.mapTileUrl(context)),
          urlTemplate: AppEnv.mapTileUrl(context),
          userAgentPackageName: 'com.groupf.waste_collect_driver',
          retinaMode: false,
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

  Widget _buildBottomControls(BuildContext context, Job job) {
    final nextStop = job.stops.firstWhere(
      (s) => s.status == StopStatus.current || s.status == StopStatus.pending,
      orElse: () => job.stops.last,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Non-clickable status badge
        _buildStaticStatusBadge(nextStop.status),
        // Right: Clickable view bins button
        _buildViewBinsButton(context, nextStop),
      ],
    );
  }

  Widget _buildStaticStatusBadge(StopStatus status) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewBinsButton(BuildContext context, BinStop stop) {
    return GestureDetector(
      onTap: () => _showBinsDialog(context, stop),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.tealGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentTeal.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.black, size: 18),
            SizedBox(width: 8),
            Text(
              'VIEW BINS',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBinsDialog(BuildContext context, BinStop stop) {
    showDialog(
      context: context,
      builder: (context) => _BinsDialog(stop: stop),
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

class _BinsDialog extends ConsumerStatefulWidget {
  final BinStop stop;
  const _BinsDialog({required this.stop});

  @override
  ConsumerState<_BinsDialog> createState() => _BinsDialogState();
}

class _BinsDialogState extends ConsumerState<_BinsDialog> {
  late List<Bin> _tempBins;

  @override
  void initState() {
    super.initState();
    _tempBins = List.from(widget.stop.bins);
  }

  void _toggleBin(int index) {
    setState(() {
      final bin = _tempBins[index];
      _tempBins[index] = bin.copyWith(
        status: bin.status == BinStatus.collected
            ? BinStatus.pending
            : BinStatus.collected,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTicked = _tempBins.every((b) => b.status == BinStatus.collected);

    return AlertDialog(
      title: Text(widget.stop.clusterName),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _tempBins.length,
          itemBuilder: (context, index) {
            final bin = _tempBins[index];
            return CheckboxListTile(
              title: Text('Bin #${bin.id.substring(bin.id.length - 4)} (${bin.type.name.toUpperCase()})'),
              subtitle: Text('Level: ${(bin.fillLevel * 100).toInt()}%'),
              value: bin.status == BinStatus.collected,
              onChanged: (_) => _toggleBin(index),
              activeColor: AppColors.accentTeal,
              checkColor: Colors.black,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            // Update stop status if all ticked
            if (allTicked) {
              ref.read(jobProvider.notifier).updateStopStatus(
                widget.stop.clusterId,
                StopStatus.completed,
              );
            }
            Navigator.pop(context);
          },
          child: Text(allTicked ? 'COMPLETE STOP' : 'DONE'),
        ),
      ],
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
