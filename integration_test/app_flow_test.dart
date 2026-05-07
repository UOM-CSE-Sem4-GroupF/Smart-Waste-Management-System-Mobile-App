import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waste_collect_driver/app.dart';
import 'package:waste_collect_driver/core/auth/auth_provider.dart';
import 'package:waste_collect_driver/core/auth/keycloak_service.dart';
import 'package:waste_collect_driver/models/bin_stop.dart';
import 'package:waste_collect_driver/models/driver.dart';
import 'package:waste_collect_driver/models/job.dart';
import 'package:waste_collect_driver/models/route_waypoint.dart';
import 'package:waste_collect_driver/providers/job_provider.dart';

class FakeAuthNotifier extends Notifier<AuthState> {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class FakeJobNotifier extends JobNotifier {
  FakeJobNotifier(this._job);
  final Job? _job;

  @override
  Future<Job?> build() async => _job;

  @override
  Future<Job?> fetchJobById(String jobId) async => _job;
}

class _TestApp extends ConsumerWidget {
  const _TestApp({required this.onRouterReady});

  final void Function(GoRouter router) onRouterReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter(ref);
    onRouterReady(router);
    return MaterialApp.router(routerConfig: router);
  }
}

const _driver = Driver(
  id: 'DRV-1',
  keycloakId: 'KC-1',
  name: 'Driver One',
  email: 'driver@example.com',
  vehicleId: 'LORRY-01',
  vehicleName: 'LORRY-01',
  vehicleCapacityKg: 2000,
  zoneId: '1',
  zoneName: 'Zone 1',
);

Job _buildJob() {
  return Job(
    id: 'JOB-1',
    type: JobType.routine,
    zoneId: 'Z1',
    zoneName: 'Zone 1',
    state: JobState.inProgress,
    assignedDriverId: 'DRV-1',
    vehicleId: 'LORRY-01',
    stops: [
      BinStop(
        clusterId: 'C1',
        clusterName: 'Cluster 1',
        lat: 6.9271,
        lng: 79.8612,
        stopIndex: 0,
        status: StopStatus.current,
        bins: [
          Bin(
            id: 'BIN-1',
            type: BinType.general,
            fillLevel: 45,
            estimatedWeightKg: 12,
            status: BinStatus.pending,
          ),
        ],
      ),
    ],
    waypoints: [
      const RouteWaypoint(lat: 6.9271, lng: 79.8612, sequence: 1),
    ],
    estimatedMinutes: 25,
    estimatedDistanceKm: 8.5,
    estimatedWeightKg: 45,
    cargoLimitKg: 2000,
    binsCollected: 1,
    binsSkipped: 0,
    binsTotal: 3,
    actualWeightKg: 0,
    assignedAt: DateTime.parse('2026-05-06T11:30:00Z'),
  );
}

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required AuthState authState,
  required Job job,
}) async {
  late GoRouter router;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keycloakServiceProvider.overrideWith(() => FakeAuthNotifier(authState)),
        jobProvider.overrideWith(() => FakeJobNotifier(job)),
        driverStatsProvider.overrideWith((ref) async => {
              'jobs_today': 1,
              'bins_today': 3,
              'weight_today_kg': 45.0,
            }),
      ],
      child: _TestApp(onRouterReady: (r) => router = r),
    ),
  );

  await tester.pumpAndSettle();
  return router;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows active job card when job exists', (tester) async {
    final router = await _pumpApp(
      tester,
      authState: const AuthState(isLoggedIn: true, driver: _driver),
      job: _buildJob(),
    );

    router.go('/home');
    await tester.pumpAndSettle();

    expect(find.text('ACTIVE JOB'), findsOneWidget);
    expect(find.textContaining('bins remaining'), findsOneWidget);
    expect(find.text('Continue job'), findsOneWidget);
  });
}
