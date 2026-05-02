import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/job.dart';
import '../models/bin_stop.dart';

class JobNotifier extends AsyncNotifier<Job?> {
  @override
  Future<Job?> build() async {
    return _fetchActiveJob();
  }

  Future<Job?> _fetchActiveJob() async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      return Job.fromJson({
        'id': 'job-001',
        'type': 'ROUTINE',
        'zone_id': '1',
        'zone_name': 'Colombo 01',
        'state': 'IN_PROGRESS',
        'assigned_driver_id': 'dev-123',
        'vehicle_id': 'WP-LC-1234',
        'stops': [
          {
            'cluster_id': 'stop-1',
            'cluster_name': 'Stop 1: Main Street',
            'lat': 6.9312,
            'lng': 79.8450,
            'status': 'CURRENT',
            'bins': [
              {
                'id': 'bin-1',
                'type': 'ORGANIC',
                'fill_level': 0.8,
                'status': 'PENDING'
              }
            ]
          },
          {
            'cluster_id': 'stop-2',
            'cluster_name': 'Stop 2: Galle Face',
            'lat': 6.9271,
            'lng': 79.8462,
            'status': 'PENDING',
            'bins': [
              {
                'id': 'bin-2',
                'type': 'PLASTIC',
                'fill_level': 0.6,
                'status': 'PENDING'
              }
            ]
          }
        ],
        'waypoints': [
          {'lat': 6.9312, 'lng': 79.8450},
          {'lat': 6.9271, 'lng': 79.8462}
        ],
        'estimated_minutes': 45,
        'estimated_distance_km': 1.5,
        'estimated_weight_kg': 150.0,
        'cargo_limit_kg': 5000.0,
        'bins_collected': 0,
        'bins_skipped': 0,
        'bins_total': 2,
        'actual_weight_kg': 0.0,
        'started_at': DateTime.now().toIso8601String(),
        'assigned_at': DateTime.now().toIso8601String(),
      });
    }

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        ApiEndpoints.collectionJobs,
        queryParameters: {
          'state': 'IN_PROGRESS',
          'assigned_driver_id': 'me',
        },
      );
      final list = response.data['data'] as List?;
      if (list == null || list.isEmpty) return null;
      return Job.fromJson(list.first as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<Job?> fetchJobById(String jobId) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiEndpoints.jobById(jobId));
      return Job.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> accept(String jobId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiEndpoints.acceptJob(jobId));
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject(String jobId, String reason) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiEndpoints.rejectJob(jobId),
        data: {'reason': reason},
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> collectBin({
    required String jobId,
    required String binId,
    required double fillLevel,
    required double lat,
    required double lng,
    double? actualWeightKg,
    String? notes,
    String? photoUrl,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiEndpoints.collectBin(jobId, binId),
        data: {
          'fill_level_at_collection': fillLevel,
          'gps_lat': lat,
          'gps_lng': lng,
          if (actualWeightKg != null) 'actual_weight_kg': actualWeightKg,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (photoUrl != null) 'photo_url': photoUrl,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> skipBin({
    required String jobId,
    required String binId,
    required String reason,
    String? notes,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiEndpoints.skipBin(jobId, binId),
        data: {
          'reason': reason,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateBinStatus(String clusterId, String binId, BinStatus status,
      {String? skipReason}) {
    state = state.whenData((job) {
      if (job == null) return null;
      final updatedStops = job.stops.map((stop) {
        if (stop.clusterId != clusterId) return stop;
        final updatedBins = stop.bins.map((bin) {
          if (bin.id != binId) return bin;
          return bin.copyWith(status: status, skipReason: skipReason);
        }).toList();
        stop.bins
          ..clear()
          ..addAll(updatedBins);
        return stop;
      }).toList();
      final collected =
          updatedStops.expand((s) => s.bins).where((b) => b.status == BinStatus.collected).length;
      final skipped =
          updatedStops.expand((s) => s.bins).where((b) => b.status == BinStatus.skipped).length;
      return job.copyWith(
        stops: updatedStops,
        binsCollected: collected,
        binsSkipped: skipped,
      );
    });
  }

  void markStopCompleted(String clusterId) {
    state = state.whenData((job) {
      if (job == null) return null;
      final updated = job.stops.map((s) {
        if (s.clusterId == clusterId) {
          s.status = StopStatus.completed;
        }
        return s;
      }).toList();
      // Set next pending stop as current
      final nextPending = updated.firstWhere(
        (s) => s.status == StopStatus.pending,
        orElse: () => updated.last,
      );
      if (nextPending.status == StopStatus.pending) {
        nextPending.status = StopStatus.current;
      }
      return job.copyWith(stops: updated);
    });
  }

  void refreshJob() => ref.invalidateSelf();
}

final jobProvider = AsyncNotifierProvider<JobNotifier, Job?>(
  JobNotifier.new,
);

// Pending job (not yet accepted) for the detail screen
final pendingJobProvider = StateProvider<Job?>((ref) => null);

// Today's driver stats (mock/API)
final driverStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get(ApiEndpoints.driverStats);
    return response.data as Map<String, dynamic>;
  } catch (_) {
    return {'jobs_today': 0, 'bins_today': 0, 'weight_today_kg': 0.0};
  }
});
