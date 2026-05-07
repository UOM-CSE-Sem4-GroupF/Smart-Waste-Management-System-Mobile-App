import 'package:flutter_test/flutter_test.dart';
import 'package:waste_collect_driver/models/job.dart';
import 'package:waste_collect_driver/models/bin_stop.dart';
import 'package:waste_collect_driver/models/route_waypoint.dart';

void main() {
  test('Job.fromJson parses fields and derived values', () {
    final json = {
      'id': 'JOB-1',
      'type': 'EMERGENCY',
      'zone_id': 'Z1',
      'zone_name': 'Zone 1',
      'state': 'IN_PROGRESS',
      'assigned_driver_id': 'DRV-1',
      'vehicle_id': 'VEH-1',
      'stops': [
        {
          'cluster_id': 'C1',
          'cluster_name': 'Cluster 1',
          'lat': 6.9,
          'lng': 79.8,
          'stop_index': 1,
          'status': 'CURRENT',
          'bins': [
            {
              'id': 'BIN-1',
              'type': 'glass',
              'fill_level': 70,
              'estimated_weight_kg': 20,
              'status': 'COLLECTED',
            }
          ],
        }
      ],
      'waypoints': [
        {'lat': 6.9, 'lng': 79.8, 'sequence': 1}
      ],
      'estimated_minutes': 12,
      'estimated_distance_km': 5.5,
      'estimated_weight_kg': 40.0,
      'cargo_limit_kg': 2000,
      'bins_collected': 1,
      'bins_skipped': 0,
      'bins_total': 1,
      'actual_weight_kg': 35.0,
      'assigned_at': '2026-05-06T10:00:00Z',
      'started_at': '2026-05-06T10:05:00Z',
      'completed_at': '2026-05-06T10:25:00Z',
    };

    final job = Job.fromJson(json);

    expect(job.type, JobType.emergency);
    expect(job.state, JobState.inProgress);
    expect(job.zoneName, 'Zone 1');
    expect(job.stops.length, 1);
    expect(job.waypoints.length, 1);
    expect(job.binsRemaining, 0);
    expect(job.isComplete, true);
    expect(job.duration?.inMinutes, 20);
  });

  test('Job.toJson preserves core fields', () {
    final job = Job(
      id: 'JOB-2',
      type: JobType.routine,
      zoneId: 'Z2',
      zoneName: 'Zone 2',
      state: JobState.assigned,
      assignedDriverId: 'DRV-2',
      vehicleId: 'VEH-2',
      stops: [
        BinStop(
          clusterId: 'C2',
          clusterName: 'Cluster 2',
          lat: 6.91,
          lng: 79.81,
          stopIndex: 0,
          bins: [
            Bin(
              id: 'BIN-2',
              type: BinType.general,
              fillLevel: 30,
              estimatedWeightKg: 12,
            )
          ],
        )
      ],
      waypoints: [
        const RouteWaypoint(lat: 6.91, lng: 79.81, sequence: 1)
      ],
      estimatedMinutes: 20,
      estimatedDistanceKm: 7.2,
      estimatedWeightKg: 50,
      cargoLimitKg: 2000,
      binsCollected: 0,
      binsSkipped: 0,
      binsTotal: 3,
      actualWeightKg: 0,
      assignedAt: DateTime.parse('2026-05-06T11:00:00Z'),
    );

    final json = job.toJson();

    expect(json['type'], 'ROUTINE');
    expect(json['zone_id'], 'Z2');
    expect(json['bins_total'], 3);
    expect(json['assigned_driver_id'], 'DRV-2');
  });
}
