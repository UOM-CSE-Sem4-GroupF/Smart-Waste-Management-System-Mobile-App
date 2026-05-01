import 'bin_stop.dart';
import 'route_waypoint.dart';

enum JobType { routine, emergency }
enum JobState { pending, assigned, inProgress, completed, cancelled }

class Job {
  final String id;
  final JobType type;
  final String zoneId;
  final String zoneName;
  final JobState state;
  final String assignedDriverId;
  final String vehicleId;
  final List<BinStop> stops;
  final List<RouteWaypoint> waypoints;
  final int estimatedMinutes;
  final double estimatedDistanceKm;
  final double estimatedWeightKg;
  final double cargoLimitKg;
  final int binsCollected;
  final int binsSkipped;
  final int binsTotal;
  final double actualWeightKg;
  final String? blockchainTxId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime assignedAt;

  const Job({
    required this.id,
    required this.type,
    required this.zoneId,
    required this.zoneName,
    required this.state,
    required this.assignedDriverId,
    required this.vehicleId,
    required this.stops,
    required this.waypoints,
    required this.estimatedMinutes,
    required this.estimatedDistanceKm,
    required this.estimatedWeightKg,
    required this.cargoLimitKg,
    required this.binsCollected,
    required this.binsSkipped,
    required this.binsTotal,
    required this.actualWeightKg,
    required this.assignedAt,
    this.blockchainTxId,
    this.startedAt,
    this.completedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      type: json['type'] == 'EMERGENCY' ? JobType.emergency : JobType.routine,
      zoneId: json['zone_id'] as String,
      zoneName: json['zone_name'] as String? ?? 'Zone ${json['zone_id']}',
      state: _parseState(json['state'] as String),
      assignedDriverId: json['assigned_driver_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      stops: (json['stops'] as List<dynamic>? ?? [])
          .map((s) => BinStop.fromJson(s as Map<String, dynamic>))
          .toList(),
      waypoints: (json['waypoints'] as List<dynamic>? ?? [])
          .map((w) => RouteWaypoint.fromJson(w as Map<String, dynamic>))
          .toList(),
      estimatedMinutes: json['estimated_minutes'] as int? ?? 0,
      estimatedDistanceKm:
          (json['estimated_distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedWeightKg:
          (json['estimated_weight_kg'] as num?)?.toDouble() ?? 0.0,
      cargoLimitKg: (json['cargo_limit_kg'] as num?)?.toDouble() ?? 2000.0,
      binsCollected: json['bins_collected'] as int? ?? 0,
      binsSkipped: json['bins_skipped'] as int? ?? 0,
      binsTotal: json['bins_total'] as int? ?? 0,
      actualWeightKg: (json['actual_weight_kg'] as num?)?.toDouble() ?? 0.0,
      blockchainTxId: json['blockchain_tx_id'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      assignedAt: DateTime.parse(
          json['assigned_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type == JobType.emergency ? 'EMERGENCY' : 'ROUTINE',
        'zone_id': zoneId,
        'zone_name': zoneName,
        'state': state.name.toUpperCase(),
        'assigned_driver_id': assignedDriverId,
        'vehicle_id': vehicleId,
        'stops': stops.map((s) => s.toJson()).toList(),
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        'estimated_minutes': estimatedMinutes,
        'estimated_distance_km': estimatedDistanceKm,
        'estimated_weight_kg': estimatedWeightKg,
        'cargo_limit_kg': cargoLimitKg,
        'bins_collected': binsCollected,
        'bins_skipped': binsSkipped,
        'bins_total': binsTotal,
        'actual_weight_kg': actualWeightKg,
        'blockchain_tx_id': blockchainTxId,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'assigned_at': assignedAt.toIso8601String(),
      };

  Job copyWith({
    String? id,
    JobType? type,
    String? zoneId,
    String? zoneName,
    JobState? state,
    String? assignedDriverId,
    String? vehicleId,
    List<BinStop>? stops,
    List<RouteWaypoint>? waypoints,
    int? estimatedMinutes,
    double? estimatedDistanceKm,
    double? estimatedWeightKg,
    double? cargoLimitKg,
    int? binsCollected,
    int? binsSkipped,
    int? binsTotal,
    double? actualWeightKg,
    String? blockchainTxId,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? assignedAt,
  }) {
    return Job(
      id: id ?? this.id,
      type: type ?? this.type,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      state: state ?? this.state,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      vehicleId: vehicleId ?? this.vehicleId,
      stops: stops ?? this.stops,
      waypoints: waypoints ?? this.waypoints,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
      estimatedWeightKg: estimatedWeightKg ?? this.estimatedWeightKg,
      cargoLimitKg: cargoLimitKg ?? this.cargoLimitKg,
      binsCollected: binsCollected ?? this.binsCollected,
      binsSkipped: binsSkipped ?? this.binsSkipped,
      binsTotal: binsTotal ?? this.binsTotal,
      actualWeightKg: actualWeightKg ?? this.actualWeightKg,
      blockchainTxId: blockchainTxId ?? this.blockchainTxId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }

  static JobState _parseState(String raw) {
    switch (raw.toUpperCase()) {
      case 'PENDING':
        return JobState.pending;
      case 'ASSIGNED':
        return JobState.assigned;
      case 'IN_PROGRESS':
        return JobState.inProgress;
      case 'COMPLETED':
        return JobState.completed;
      case 'CANCELLED':
        return JobState.cancelled;
      default:
        return JobState.pending;
    }
  }

  int get binsRemaining => binsTotal - binsCollected - binsSkipped;
  bool get isComplete => binsRemaining <= 0;
  Duration? get duration =>
      startedAt != null && completedAt != null
          ? completedAt!.difference(startedAt!)
          : null;
}
