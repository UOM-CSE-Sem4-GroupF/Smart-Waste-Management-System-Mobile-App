import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waste_collect_driver/app.dart';
import 'package:waste_collect_driver/core/auth/auth_provider.dart';
import 'package:waste_collect_driver/core/auth/keycloak_service.dart';
import 'package:waste_collect_driver/models/driver.dart';
import 'package:waste_collect_driver/models/job.dart';
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

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required AuthState authState,
  Job? job,
}) async {
  late GoRouter router;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keycloakServiceProvider.overrideWith(() => FakeAuthNotifier(authState)),
        jobProvider.overrideWith(() => FakeJobNotifier(job)),
        driverStatsProvider.overrideWith((ref) async => {
              'jobs_today': 0,
              'bins_today': 0,
              'weight_today_kg': 0.0,
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

  testWidgets('redirects unauthenticated users to login', (tester) async {
    final router = await _pumpApp(
      tester,
      authState: const AuthState(isLoggedIn: false),
    );

    router.go('/home');
    await tester.pumpAndSettle();

    expect(find.text('Sign in with Keycloak'), findsOneWidget);
  });

  testWidgets('redirects logged-in users away from login', (tester) async {
    final router = await _pumpApp(
      tester,
      authState: const AuthState(isLoggedIn: true, driver: _driver),
    );

    router.go('/login');
    await tester.pumpAndSettle();

    expect(find.text("You're Available"), findsOneWidget);
  });
}
