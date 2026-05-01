enum BinStatus { pending, collected, skipped }
enum BinType { glass, paper, food, plastic, metal, general }
enum StopStatus { pending, current, completed }

class BinStop {
  final String clusterId;
  final String clusterName;
  final double lat;
  final double lng;
  final List<Bin> bins;
  StopStatus status;
  final int stopIndex;

  BinStop({
    required this.clusterId,
    required this.clusterName,
    required this.lat,
    required this.lng,
    required this.bins,
    required this.stopIndex,
    this.status = StopStatus.pending,
  });

  factory BinStop.fromJson(Map<String, dynamic> json) {
    return BinStop(
      clusterId: json['cluster_id'] as String,
      clusterName: json['cluster_name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      stopIndex: json['stop_index'] as int? ?? 0,
      status: _parseStopStatus(json['status'] as String? ?? 'PENDING'),
      bins: (json['bins'] as List<dynamic>? ?? [])
          .map((b) => Bin.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cluster_id': clusterId,
        'cluster_name': clusterName,
        'lat': lat,
        'lng': lng,
        'stop_index': stopIndex,
        'status': status.name.toUpperCase(),
        'bins': bins.map((b) => b.toJson()).toList(),
      };

  bool get allActioned =>
      bins.every((b) => b.status != BinStatus.pending);

  static StopStatus _parseStopStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'CURRENT':
        return StopStatus.current;
      case 'COMPLETED':
        return StopStatus.completed;
      default:
        return StopStatus.pending;
    }
  }
}

class Bin {
  final String id;
  final BinType type;
  final double fillLevel;
  final double estimatedWeightKg;
  BinStatus status;
  String? skipReason;
  double? actualWeightKg;
  String? notes;
  String? photoUrl;
  bool isSyncing;

  Bin({
    required this.id,
    required this.type,
    required this.fillLevel,
    required this.estimatedWeightKg,
    this.status = BinStatus.pending,
    this.skipReason,
    this.actualWeightKg,
    this.notes,
    this.photoUrl,
    this.isSyncing = false,
  });

  factory Bin.fromJson(Map<String, dynamic> json) {
    return Bin(
      id: json['id'] as String,
      type: _parseBinType(json['type'] as String? ?? 'general'),
      fillLevel: (json['fill_level'] as num?)?.toDouble() ?? 0.0,
      estimatedWeightKg:
          (json['estimated_weight_kg'] as num?)?.toDouble() ?? 0.0,
      status: _parseBinStatus(json['status'] as String? ?? 'PENDING'),
      skipReason: json['skip_reason'] as String?,
      actualWeightKg: (json['actual_weight_kg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'fill_level': fillLevel,
        'estimated_weight_kg': estimatedWeightKg,
        'status': status.name.toUpperCase(),
        'skip_reason': skipReason,
        'actual_weight_kg': actualWeightKg,
        'notes': notes,
        'photo_url': photoUrl,
      };

  Bin copyWith({
    BinStatus? status,
    String? skipReason,
    double? actualWeightKg,
    String? notes,
    String? photoUrl,
    bool? isSyncing,
  }) {
    return Bin(
      id: id,
      type: type,
      fillLevel: fillLevel,
      estimatedWeightKg: estimatedWeightKg,
      status: status ?? this.status,
      skipReason: skipReason ?? this.skipReason,
      actualWeightKg: actualWeightKg ?? this.actualWeightKg,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  static BinType _parseBinType(String raw) {
    switch (raw.toLowerCase()) {
      case 'glass':
        return BinType.glass;
      case 'paper':
        return BinType.paper;
      case 'food':
        return BinType.food;
      case 'plastic':
        return BinType.plastic;
      case 'metal':
        return BinType.metal;
      default:
        return BinType.general;
    }
  }

  static BinStatus _parseBinStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'COLLECTED':
        return BinStatus.collected;
      case 'SKIPPED':
        return BinStatus.skipped;
      default:
        return BinStatus.pending;
    }
  }
}
