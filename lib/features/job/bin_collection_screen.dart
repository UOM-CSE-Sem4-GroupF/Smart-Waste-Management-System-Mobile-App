import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/bin_stop.dart';
import '../../models/job.dart';
import '../../providers/cargo_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fill_level_indicator.dart';

class BinCollectionScreen extends ConsumerStatefulWidget {
  final String clusterId;
  const BinCollectionScreen({super.key, required this.clusterId});

  @override
  ConsumerState<BinCollectionScreen> createState() =>
      _BinCollectionScreenState();
}

class _BinCollectionScreenState extends ConsumerState<BinCollectionScreen> {
  // Track local bin states for optimistic UI
  final Map<String, BinStatus> _localStatus = {};
  final Map<String, bool> _loading = {};

  BinStop? get _stop {
    final job = ref.read(jobProvider).valueOrNull;
    if (job == null) return null;
    try {
      return job.stops.firstWhere((s) => s.clusterId == widget.clusterId);
    } catch (_) {
      return null;
    }
  }

  Job? get _job => ref.read(jobProvider).valueOrNull;

  bool _binStatus(Bin bin) {
    final local = _localStatus[bin.id];
    return local != null ? local != BinStatus.pending : bin.status != BinStatus.pending;
  }

  BinStatus _effectiveStatus(Bin bin) =>
      _localStatus[bin.id] ?? bin.status;

  bool get _allActioned {
    final stop = _stop;
    if (stop == null) return false;
    return stop.bins.every((b) => _binStatus(b));
  }

  Future<void> _onCollect(Bin bin) async {
    if (_loading[bin.id] == true) return;

    final result = await showModalBottomSheet<_CollectResult?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CollectConfirmSheet(bin: bin),
    );

    if (result == null || !mounted) return;

    // Optimistic update
    setState(() {
      _localStatus[bin.id] = BinStatus.collected;
      _loading[bin.id] = true;
    });

    // Update cargo
    ref.read(cargoProvider.notifier).addBin(bin.estimatedWeightKg);

    // API call
    final job = _job;
    if (job != null) {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (_) {}

      final ok = await ref.read(jobProvider.notifier).collectBin(
            jobId: job.id,
            binId: bin.id,
            fillLevel: bin.fillLevel,
            lat: pos?.latitude ?? 0,
            lng: pos?.longitude ?? 0,
            actualWeightKg: result.actualWeight,
            notes: result.notes,
            photoUrl: result.photoUrl,
          );

      if (!mounted) return;
      setState(() => _loading[bin.id] = false);

      if (!ok) {
        // Show sync pending indicator (already optimistically updated)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ Saved offline — will sync when connected'),
            backgroundColor: AppColors.accentOrange,
          ),
        );
      }
    }

    // Check cargo limit
    final cargo = ref.read(cargoProvider);
    if (cargo.isAtLimit && mounted) {
      _showCapacityDialog();
    }
  }

  Future<void> _onSkip(Bin bin) async {
    if (_loading[bin.id] == true) return;

    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _SkipReasonSheet(),
    );

    if (reason == null || !mounted) return;

    setState(() {
      _localStatus[bin.id] = BinStatus.skipped;
      _loading[bin.id] = true;
    });

    final job = _job;
    if (job != null) {
      await ref.read(jobProvider.notifier).skipBin(
            jobId: job.id,
            binId: bin.id,
            reason: reason,
          );
    }
    if (mounted) setState(() => _loading[bin.id] = false);
  }

  Future<void> _onDoneWithStop() async {
    final job = _job;
    final stop = _stop;
    if (job == null || stop == null) return;

    ref.read(jobProvider.notifier).markStopCompleted(stop.clusterId);

    final updatedJob = ref.read(jobProvider).valueOrNull;
    if (updatedJob?.isComplete == true) {
      // All stops done — go back home (job complete page removed)
      context.go('/home');
    } else {
      context.pop();
    }
  }

  void _showCapacityDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Row(
          children: [
            Text('🛑 ', style: TextStyle(fontSize: 24)),
            Text('Vehicle at capacity',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Return to the depot before continuing collection.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood',
                style: TextStyle(color: AppColors.accentTeal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(context, jobAsync.valueOrNull),
      body: jobAsync.when(
        data: (job) {
          final stop = job?.stops
              .cast<BinStop?>()
              .firstWhere((s) => s?.clusterId == widget.clusterId,
                  orElse: () => null);
          if (stop == null) {
            return const Center(
              child: Text('Stop not found',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return _buildBody(context, job!, stop);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentTeal),
        ),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Job? job) {
    final stop = job?.stops
        .cast<BinStop?>()
        .firstWhere((s) => s?.clusterId == widget.clusterId,
            orElse: () => null);
    final idx = stop != null ? job!.stops.indexOf(stop) + 1 : 1;
    final total = job?.stops.length ?? 1;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stop?.clusterName ?? 'Stop',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text('Stop $idx of $total',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, Job job, BinStop stop) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Text(
                'Bins at this stop',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ...stop.bins.asMap().entries.map((e) {
                final idx = e.key;
                final bin = e.value;
                return _BinCard(
                  bin: bin,
                  effectiveStatus: _effectiveStatus(bin),
                  isLoading: _loading[bin.id] == true,
                  onCollect: () => _onCollect(bin),
                  onSkip: () => _onSkip(bin),
                ).animate().fadeIn(delay: (idx * 80).ms).slideY(begin: 0.1);
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Done button
        AnimatedOpacity(
          opacity: _allActioned ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _allActioned
                      ? const LinearGradient(
                          colors: [AppColors.accentTeal, Color(0xFF00A888)],
                        )
                      : const LinearGradient(
                          colors: [AppColors.textMuted, AppColors.textMuted],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _allActioned
                      ? [
                          BoxShadow(
                            color: AppColors.accentTeal.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton.icon(
                  onPressed: _allActioned ? _onDoneWithStop : null,
                  icon: const Icon(Icons.done_all_rounded, size: 20),
                  label: const Text('DONE WITH THIS STOP'),
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
          ),
        ),
      ],
    );
  }
}

// ─── Bin card ─────────────────────────────────────────────────────────────────

class _BinCard extends StatelessWidget {
  final Bin bin;
  final BinStatus effectiveStatus;
  final bool isLoading;
  final VoidCallback onCollect;
  final VoidCallback onSkip;

  const _BinCard({
    required this.bin,
    required this.effectiveStatus,
    required this.isLoading,
    required this.onCollect,
    required this.onSkip,
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
    final isDone = effectiveStatus != BinStatus.pending;
    final isCollected = effectiveStatus == BinStatus.collected;
    final isSkipped = effectiveStatus == BinStatus.skipped;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone
              ? (isCollected
                  ? AppColors.accentGreen.withValues(alpha: 0.4)
                  : AppColors.accentOrange.withValues(alpha: 0.3))
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _typeColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${bin.id}  ·  ${bin.type.name.toUpperCase()}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentTeal,
                  ),
                )
              else if (isCollected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✅ Collected',
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (isSkipped)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '⏭ Skipped',
                    style: TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Fill level
          FillLevelIndicator(
            fillLevel: bin.fillLevel,
            color: _typeColor,
          ),
          const SizedBox(height: 8),
          // Weight
          Row(
            children: [
              const Icon(Icons.scale_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '~${bin.estimatedWeightKg.toInt()} kg',
                style: TextStyle(
                  color: bin.fillLevel > 0.8
                      ? AppColors.accentOrange
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: bin.fillLevel > 0.8
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              if (bin.fillLevel < 0.4) ...[
                const SizedBox(width: 6),
                const Text(
                  '· not urgent',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          // Action buttons (only if not done)
          if (!isDone) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton(
                  onPressed: isLoading ? null : onSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('SKIP'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onCollect,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('COLLECTED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Collect confirm sheet ────────────────────────────────────────────────────

class _CollectResult {
  final double? actualWeight;
  final String? notes;
  final String? photoUrl;

  _CollectResult({this.actualWeight, this.notes, this.photoUrl});
}

class _CollectConfirmSheet extends StatefulWidget {
  final Bin bin;
  const _CollectConfirmSheet({required this.bin});

  @override
  State<_CollectConfirmSheet> createState() => _CollectConfirmSheetState();
}

class _CollectConfirmSheetState extends State<_CollectConfirmSheet> {
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _photoPath;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (xfile != null && mounted) {
      setState(() => _photoPath = xfile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Confirm collection',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${widget.bin.id} · ${widget.bin.type.name}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              'Current fill: ${(widget.bin.fillLevel * 100).toInt()}%',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            // Weight input
            TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Actual weight (kg) — optional',
                suffixText: 'kg',
                suffixStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Notes (optional)',
              ),
            ),
            const SizedBox(height: 12),
            // Photo button
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text(
                  _photoPath == null ? 'Add photo (optional)' : 'Photo taken ✓'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _photoPath != null
                    ? AppColors.accentGreen
                    : AppColors.textSecondary,
                side: BorderSide(
                  color: _photoPath != null
                      ? AppColors.accentGreen
                      : AppColors.divider,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final weight = double.tryParse(_weightCtrl.text);
                  final notes = _notesCtrl.text.isEmpty ? null : _notesCtrl.text;
                  Navigator.pop(
                    context,
                    _CollectResult(
                        actualWeight: weight,
                        notes: notes,
                        photoUrl: _photoPath),
                  );
                },
                child: const Text('Confirm collected'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skip reason sheet ────────────────────────────────────────────────────────

class _SkipReasonSheet extends StatefulWidget {
  const _SkipReasonSheet();

  @override
  State<_SkipReasonSheet> createState() => _SkipReasonSheetState();
}

class _SkipReasonSheetState extends State<_SkipReasonSheet> {
  String? _selected;

  static const reasons = [
    'Bin is locked',
    'Bin is inaccessible',
    'Bin is already empty',
    'Hazardous contents',
    'Bin is missing',
    'Other',
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Reason for skip',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
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
              onPressed: _selected == null
                  ? null
                  : () => Navigator.pop(context, _selected),
              child: const Text('Confirm skip'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared reason tile (replaces deprecated RadioListTile) ───────────────────

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
                  color:
                      selected ? AppColors.accentTeal : AppColors.textMuted,
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
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
