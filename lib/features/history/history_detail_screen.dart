import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/bin_stop.dart';
import '../../models/job.dart';
import '../../theme/app_theme.dart';

final _historyDetailProvider =
    FutureProvider.family<Job?, String>((ref, jobId) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get(ApiEndpoints.jobById(jobId));
    return Job.fromJson(response.data['data'] as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

class HistoryDetailScreen extends ConsumerWidget {
  final String jobId;
  const HistoryDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(_historyDetailProvider(jobId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: jobAsync.when(
        data: (job) => job != null
            ? _buildContent(context, job)
            : _buildNotFound(context),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentTeal),
        ),
        error: (e, _) => _buildNotFound(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Job job) {
    final collected = job.stops.expand((s) => s.bins).where(
          (b) => b.status == BinStatus.collected,
        );
    final skipped = job.stops.expand((s) => s.bins).where(
          (b) => b.status == BinStatus.skipped,
        );

    return CustomScrollView(
      slivers: [
        // App bar
        _buildAppBar(context, job),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status badge
              _buildStatusBadge(context, job),
              const SizedBox(height: 20),

              // Static route map
              _buildRouteMap(job),
              const SizedBox(height: 20),

              // Stats card
              _buildStatsCard(context, job),
              const SizedBox(height: 16),

              // Blockchain TX
              if (job.blockchainTxId != null)
                _buildBlockchainCard(context, job.blockchainTxId!),

              const SizedBox(height: 20),

              // Collected bins
              if (collected.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Bins collected (${collected.length})',
                  color: AppColors.accentGreen,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 10),
                ...collected
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => _BinHistoryRow(
                          bin: e.value,
                          index: e.key,
                          jobAssignedAt: job.assignedAt,
                        )),
                const SizedBox(height: 16),
              ],

              // Skipped bins
              if (skipped.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Bins skipped (${skipped.length})',
                  color: AppColors.accentOrange,
                  icon: Icons.skip_next_rounded,
                ),
                const SizedBox(height: 10),
                ...skipped
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => _BinHistoryRow(
                          bin: e.value,
                          index: e.key,
                          jobAssignedAt: job.assignedAt,
                          isSkipped: true,
                        )),
              ],

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, Job job) {
    final dateStr = DateFormat('EEE d MMM · HH:mm').format(job.assignedAt);
    return SliverAppBar(
      backgroundColor: AppColors.bgCard,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.zoneName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          Text(dateStr,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Job job) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.accentGreen, size: 14),
              SizedBox(width: 6),
              Text(
                'COMPLETED',
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildRouteMap(Job job) {
    if (job.stops.isEmpty) return const SizedBox.shrink();

    final points = job.stops.map((s) => LatLng(s.lat, s.lng)).toList();
    final center = LatLng(
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.groupf.waste_collect_driver',
            ),
            if (job.waypoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: job.waypoints
                        .map((w) => LatLng(w.lat, w.lng))
                        .toList(),
                    strokeWidth: 3.0,
                    color: AppColors.accentTeal.withValues(alpha: 0.8),
                  ),
                ],
              ),
            MarkerLayer(
              markers: job.stops
                  .map(
                    (stop) => Marker(
                      point: LatLng(stop.lat, stop.lng),
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stop.allActioned
                              ? AppColors.accentGreen
                              : AppColors.textMuted,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          stop.allActioned
                              ? Icons.check_rounded
                              : Icons.location_on_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatsCard(BuildContext context, Job job) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stats', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                  icon: Icons.access_time_rounded,
                  label: 'Duration',
                  value: job.duration != null
                      ? '${job.duration!.inMinutes} min'
                      : '—'),
              _StatItem(
                  icon: Icons.scale_rounded,
                  label: 'Weight',
                  value: '${job.actualWeightKg.toInt()} kg'),
              _StatItem(
                  icon: Icons.delete_rounded,
                  label: 'Collected',
                  value: '${job.binsCollected}'),
              _StatItem(
                  icon: Icons.skip_next_rounded,
                  label: 'Skipped',
                  value: '${job.binsSkipped}'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildBlockchainCard(BuildContext context, String txId) {
    final short = txId.length > 10
        ? '${txId.substring(0, 6)}...${txId.substring(txId.length - 4)}'
        : txId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.accentTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded,
              color: AppColors.accentTeal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Blockchain audit',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  short,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text('COPY'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentTeal,
              textStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Job Detail'),
      ),
      body: const Center(
        child: Text('Job not found',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _BinHistoryRow extends StatelessWidget {
  final Bin bin;
  final int index;
  final DateTime jobAssignedAt;
  final bool isSkipped;

  const _BinHistoryRow({
    required this.bin,
    required this.index,
    required this.jobAssignedAt,
    this.isSkipped = false,
  });

  Color get _typeColor {
    switch (bin.type) {
      case BinType.glass:
        return AppColors.accentGreen;
      case BinType.paper:
        return AppColors.accentBlue;
      case BinType.food:
        return AppColors.accentOrange;
      case BinType.plastic:
        return const Color(0xFFEC4899);
      case BinType.metal:
        return const Color(0xFF8B5CF6);
      case BinType.general:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simulate time offset for display
    final time = jobAssignedAt.add(Duration(minutes: 2 * index + 1));
    final timeStr = DateFormat('HH:mm').format(time);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSkipped ? AppColors.accentOrange : _typeColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bin.id,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            bin.type.name,
            style: TextStyle(color: _typeColor, fontSize: 12),
          ),
          const SizedBox(width: 10),
          if (!isSkipped)
            Text(
              '${(bin.actualWeightKg ?? bin.estimatedWeightKg).toInt()} kg',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          if (isSkipped)
            Text(
              bin.skipReason ?? 'Skipped',
              style: const TextStyle(
                  color: AppColors.accentOrange, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(width: 10),
          Text(
            timeStr,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.05);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentTeal, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
