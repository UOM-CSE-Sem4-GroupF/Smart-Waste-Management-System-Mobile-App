import 'package:flutter_test/flutter_test.dart';
import 'package:waste_collect_driver/models/bin_stop.dart';

void main() {
  test('BinStop.fromJson parses bins and status', () {
    final json = {
      'cluster_id': 'C1',
      'cluster_name': 'Cluster 1',
      'lat': 6.9,
      'lng': 79.8,
      'status': 'CURRENT',
      'stop_index': 2,
      'bins': [
        {
          'id': 'BIN-1',
          'type': 'glass',
          'fill_level': 55,
          'estimated_weight_kg': 12.5,
          'status': 'COLLECTED',
        }
      ],
    };

    final stop = BinStop.fromJson(json);

    expect(stop.clusterId, 'C1');
    expect(stop.status, StopStatus.current);
    expect(stop.bins.first.type, BinType.glass);
  });

  test('BinStop.allActioned returns true when none pending', () {
    final stop = BinStop(
      clusterId: 'C2',
      clusterName: 'Cluster 2',
      lat: 6.9,
      lng: 79.8,
      stopIndex: 0,
      bins: [
        Bin(
          id: 'BIN-1',
          type: BinType.paper,
          fillLevel: 10,
          estimatedWeightKg: 5,
          status: BinStatus.collected,
        ),
        Bin(
          id: 'BIN-2',
          type: BinType.paper,
          fillLevel: 20,
          estimatedWeightKg: 7,
          status: BinStatus.skipped,
        ),
      ],
    );

    expect(stop.allActioned, true);
  });

  test('Bin.fromJson defaults unknown type to general', () {
    final bin = Bin.fromJson({
      'id': 'BIN-3',
      'type': 'radioactive',
      'fill_level': 50,
      'estimated_weight_kg': 8,
      'status': 'PENDING',
    });

    expect(bin.type, BinType.general);
    expect(bin.status, BinStatus.pending);
  });

  test('Bin.copyWith updates status and notes', () {
    final bin = Bin(
      id: 'BIN-4',
      type: BinType.glass,
      fillLevel: 40,
      estimatedWeightKg: 10,
    );

    final updated = bin.copyWith(
      status: BinStatus.collected,
      notes: 'Collected quickly',
    );

    expect(updated.status, BinStatus.collected);
    expect(updated.notes, 'Collected quickly');
  });
}
