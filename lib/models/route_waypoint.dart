class RouteWaypoint {
  final double lat;
  final double lng;
  final int sequence;

  const RouteWaypoint({
    required this.lat,
    required this.lng,
    required this.sequence,
  });

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      sequence: json['sequence'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'sequence': sequence,
      };
}
