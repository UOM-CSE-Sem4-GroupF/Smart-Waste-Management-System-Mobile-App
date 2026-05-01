class Driver {
  final String id;
  final String keycloakId;
  final String name;
  final String email;
  final String vehicleId;
  final String vehicleName;
  final double vehicleCapacityKg;
  final String zoneId;
  final String zoneName;

  const Driver({
    required this.id,
    required this.keycloakId,
    required this.name,
    required this.email,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleCapacityKg,
    required this.zoneId,
    required this.zoneName,
  });

  factory Driver.fromClaims(Map<String, dynamic> claims) {
    return Driver(
      id: claims['driver_id'] as String? ?? claims['sub'] as String,
      keycloakId: claims['sub'] as String,
      name: claims['name'] as String? ?? 'Driver',
      email: claims['email'] as String? ?? '',
      vehicleId: claims['vehicle_id'] as String? ?? 'LORRY-01',
      vehicleName: claims['vehicle_name'] as String? ??
          claims['vehicle_id'] as String? ??
          'LORRY-01',
      vehicleCapacityKg:
          (claims['vehicle_capacity_kg'] as num?)?.toDouble() ?? 2000.0,
      zoneId: (claims['zone_id'] ?? '1').toString(),
      zoneName: claims['zone_name'] as String? ??
          'Zone ${(claims['zone_id'] ?? 1).toString()}',
    );
  }

  String get firstName => name.split(' ').first;
}
