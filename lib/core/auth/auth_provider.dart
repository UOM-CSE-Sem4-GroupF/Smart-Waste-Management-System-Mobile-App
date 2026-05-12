import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'keycloak_service.dart';
import '../../models/driver.dart';

/// The singleton KeycloakService as a [NotifierProvider].
/// Using [NotifierProvider] instead of the legacy [ChangeNotifierProvider]
/// avoids the `!_dirty` framework assertion in Flutter 3.41+.
final keycloakServiceProvider =
    NotifierProvider<KeycloakService, AuthState>(KeycloakService.new);

/// Convenience accessor for the full auth state.
final authStateProvider = Provider<AuthState>(
  (ref) => ref.watch(keycloakServiceProvider),
);

/// Current logged-in driver. (Mocked for bypass)
final currentDriverProvider = Provider<Driver?>(
  (ref) => const Driver(
    id: '1024',
    keycloakId: 'mock-id',
    name: 'John Driver',
    email: 'john@example.com',
    vehicleId: 'LORRY-03',
    vehicleName: 'LORRY-03',
    vehicleCapacityKg: 2000,
    zoneId: '3',
    zoneName: 'Zone 3',
  ),
);

/// Whether the user is currently logged in. (Hardcoded to true for bypass)
final isLoggedInProvider = Provider<bool>(
  (ref) => true,
);
