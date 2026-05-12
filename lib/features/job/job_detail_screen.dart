import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/env.dart';
import '../../models/job.dart';
import '../../models/bin_stop.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 600; // 10 minutes
  bool _isAccepting = false;
  bool _isRejecting = false;
  Job? _job;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJob();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadJob() async {
    final notifier = ref.read(jobProvider.notifier);
    final job = await notifier.fetchJobById(widget.jobId);
    if (mounted) {
      setState(() {
        _job = job;
        _loading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        t.cancel();
        _onTimerExpired();
      }
    });
  }

  void _onTimerExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Job Reassigned',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This job has been reassigned to another driver.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child:
                const Text('OK', style: TextStyle(color: AppColors.accentTeal)),
          ),
        ],
      ),
    );
  }

  Future<void> _onAccept() async {
    if (_isAccepting || _job == null) return;
    setState(() => _isAccepting = true);
    final ok = await ref.read(jobProvider.notifier).accept(_job!.id);
    if (!mounted) return;
    if (ok) {
      context.go('/job/active/map');
    } else {
      setState(() => _isAccepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept job. Try again.'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  Future<void> _onReject() async {
    if (_job == null) return;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RejectReasonSheet(),
    );
    if (reason == null || !mounted) return;
    setState(() => _isRejecting = true);
    final ok =
        await ref.read(jobProvider.notifier).reject(_job!.id, reason);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      setState(() => _isRejecting = false);
    }
  }

  String get _timerText {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentTeal),
        ),
      );
    }

    if (_job == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(
          child: Text('Job not found',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final job = _job!;
    final isEmergency = job.type == JobType.emergency;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isEmergency),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Job type badge
                _buildTypeBadge(isEmergency),
                const SizedBox(height: 12),
                Text(
                  job.zoneName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                // Vehicle
                _InfoSection(title: 'Your vehicle', children: [
                  _buildVehicleRow(job.vehicleId, job.cargoLimitKg),
                ]),
                const SizedBox(height: 16),
                // Stops
                _InfoSection(
                  title: 'Collection stops (${job.stops.length})',
                  children: job.stops
                      .map((s) => _buildStopRow(s))
                      .toList(),
                ),
                const SizedBox(height: 16),
                // Stats
                _buildJobStats(job),
                const SizedBox(height: 16),
                // Map preview
                _buildMapPreview(context, job),
                const SizedBox(height: 20),
                // Timer
                _buildTimer(),
                const SizedBox(height: 24),
                // Buttons
                _buildButtons(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isEmergency) {
    return SliverAppBar(
      backgroundColor: AppColors.bgCard,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => context.pop(),
      ),
      title: const Text('New Job Assigned'),
      actions: [
        if (isEmergency)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '⚡ URGENT',
              style: TextStyle(
                color: AppColors.accentRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeBadge(bool isEmergency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isEmergency ? AppColors.accentRed : AppColors.accentTeal)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              (isEmergency ? AppColors.accentRed : AppColors.accentTeal)
                  .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEmergency ? '🚨 EMERGENCY JOB' : '📋 ROUTINE JOB',
            style: TextStyle(
              color: isEmergency
                  ? AppColors.accentRed
                  : AppColors.accentTeal,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleRow(String vehicleId, double capacity) {
    return Row(
      children: [
        const Icon(Icons.local_shipping_rounded,
            color: AppColors.accentBlue, size: 20),
        const SizedBox(width: 10),
        Text(
          '$vehicleId  (${capacity.toInt().toString()} kg capacity)',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStopRow(BinStop stop) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              color: AppColors.accentTeal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(stop.clusterName,
                style: const TextStyle(color: AppColors.textPrimary)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${stop.bins.length} bin${stop.bins.length != 1 ? 's' : ''}',
              style: const TextStyle(
                  color: AppColors.accentTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobStats(Job job) {
    return Row(
      children: [
        _JobStatCard(
          icon: Icons.access_time_rounded,
          label: 'Est. time',
          value: '~${job.estimatedMinutes} min',
          color: AppColors.accentTeal,
        ),
        const SizedBox(width: 10),
        _JobStatCard(
          icon: Icons.route_rounded,
          label: 'Distance',
          value: '${job.estimatedDistanceKm.toStringAsFixed(1)} km',
          color: AppColors.accentBlue,
        ),
        const SizedBox(width: 10),
        _JobStatCard(
          icon: Icons.scale_rounded,
          label: 'Est. weight',
          value: '${job.estimatedWeightKg.toInt()} kg',
          color: AppColors.accentOrange,
        ),
      ],
    );
  }

  Widget _buildMapPreview(BuildContext context, Job job) {
    if (job.stops.isEmpty) return const SizedBox.shrink();
    final center = LatLng(job.stops.first.lat, job.stops.first.lng);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              key: ValueKey(AppEnv.mapTileUrl(context)),
              urlTemplate: AppEnv.mapTileUrl(context),
              userAgentPackageName: 'com.groupf.waste_collect_driver',
              retinaMode: false,
            ),
            MarkerLayer(
              markers: job.stops
                  .map(
                    (s) => Marker(
                      point: LatLng(s.lat, s.lng),
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentTeal,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final isUrgent = _remainingSeconds < 120;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: (isUrgent ? AppColors.accentRed : AppColors.accentOrange)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isUrgent ? AppColors.accentRed : AppColors.accentOrange)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_rounded,
            color:
                isUrgent ? AppColors.accentRed : AppColors.accentOrange,
          ),
          const SizedBox(width: 10),
          Text(
            'Accept within:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            _timerText,
            style: TextStyle(
              color: isUrgent
                  ? AppColors.accentRed
                  : AppColors.accentOrange,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                (_isRejecting || _isAccepting) ? null : _onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentRed,
              side: const BorderSide(color: AppColors.accentRed, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isRejecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accentRed),
                  )
                : const Text('REJECT',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
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
              onPressed:
                  (_isAccepting || _isRejecting) ? null : _onAccept,
              icon: _isAccepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(_isAccepting ? 'Accepting...' : 'ACCEPT JOB'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Reject reason sheet ────────────────────────────────────────────────────

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet();

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  String? _selected;

  static const reasons = [
    'Vehicle issue',
    'Out of zone',
    'Personal reason',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Reason for rejection',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...reasons.map(
            (r) => _ReasonTile(
              label: r,
              selected: _selected == r,
              onTap: () => setState(() => _selected = r),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _selected == null ? null : () => Navigator.pop(context, _selected),
              child: const Text('Confirm rejection'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reason tile (replaces deprecated RadioListTile) ─────────────────────────

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentTeal.withValues(alpha: 0.1)
              : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentTeal : AppColors.divider,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accentTeal : AppColors.textMuted,
                  width: 2,
                ),
                color: selected ? AppColors.accentTeal : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 11, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Helpers ─────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _JobStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _JobStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}


