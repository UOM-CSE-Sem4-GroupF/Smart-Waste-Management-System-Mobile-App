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

/// Current logged-in driver.
final currentDriverProvider = Provider<Driver?>(
  (ref) => ref.watch(authStateProvider).driver,
);

/// Whether the user is currently logged in.
final isLoggedInProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).isLoggedIn,
);
