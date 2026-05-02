import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../../models/driver.dart';
import '../env.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoggedIn;
  final Driver? driver;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.driver,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    Driver? driver,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      driver: driver ?? this.driver,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Notifier (replaces ChangeNotifier) ──────────────────────────────────────

/// Riverpod [Notifier] replacement for the old [ChangeNotifier]-based service.
/// Using [Notifier] avoids the `!_dirty` framework assertion that occurs when
/// [ChangeNotifierProvider] calls [notifyListeners] during [ProviderScope]'s
/// first build phase in Flutter 3.41+.
class KeycloakService extends Notifier<AuthState> {
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static AuthorizationServiceConfiguration get _serviceConfig =>
      AuthorizationServiceConfiguration(
        authorizationEndpoint: AppEnv.authEndpoint,
        tokenEndpoint: AppEnv.tokenEndpoint,
      );

  @override
  AuthState build() {
    // Kick off session restore asynchronously after the first frame.
    Future.microtask(init);
    return const AuthState(isLoading: true);
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Restore session on app launch (also called by [build]).
  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      final accessToken = await _storage.read(key: 'access_token');
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (accessToken == null || refreshToken == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final refreshed = await _tryRefresh(refreshToken);
      if (refreshed) return;
      await _clearTokens();
    } catch (e) {
      await _clearTokens();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// PKCE login via browser.
  Future<void> login() async {
    state = state.copyWith(isLoading: true, error: null);

    // MOCK LOGIN FOR WEB DEVELOPMENT
    if (kIsWeb) {
      await Future.delayed(const Duration(seconds: 1));
      state = AuthState(
        isLoggedIn: true,
        driver: Driver(
          id: 'dev-123',
          keycloakId: 'dev-123',
          name: 'Kamal Perera',
          email: 'kamal@waste-mgmt.lk',
          vehicleId: 'WP-LC-1234',
          vehicleName: 'Compactor A',
          vehicleCapacityKg: 5000.0,
          zoneId: '1',
          zoneName: 'Colombo 01',
        ),
        accessToken: 'mock_token',
        isLoading: false,
      );
      return;
    }

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppEnv.keycloakClientId,
          AppEnv.redirectUri,
          serviceConfiguration: _serviceConfig,
          scopes: ['openid', 'profile', 'email'],
        ),
      );
      if (result != null) {
        await _handleTokenResponse(result);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<bool> refreshIfNeeded() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;
    return _tryRefresh(refresh);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');

  Future<void> logout() async {
    await _clearTokens();
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<bool> _tryRefresh(String refreshToken) async {
    try {
      final result = await _appAuth.token(
        TokenRequest(
          AppEnv.keycloakClientId,
          AppEnv.redirectUri,
          serviceConfiguration: _serviceConfig,
          refreshToken: refreshToken,
          scopes: ['openid', 'profile'],
        ),
      );
      if (result != null) {
        await _handleTokenResponse(result);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _handleTokenResponse(TokenResponse r) async {
    final access = r.accessToken;
    final refresh = r.refreshToken;
    if (access == null) return;

    await _storage.write(key: 'access_token', value: access);
    if (refresh != null) {
      await _storage.write(key: 'refresh_token', value: refresh);
    }
    if (r.idToken != null) {
      await _storage.write(key: 'id_token', value: r.idToken);
    }

    final claims = _parseClaims(access);
    final driver = Driver.fromClaims(claims);

    state = AuthState(
      isLoggedIn: true,
      driver: driver,
      accessToken: access,
      refreshToken: refresh,
      isLoading: false,
    );
  }

  Future<void> _clearTokens() async {
    await _storage.deleteAll();
    state = const AuthState(isLoggedIn: false, isLoading: false);
  }

  Map<String, dynamic> _parseClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final normalized = base64Url.normalize(parts[1]);
      final payload = base64Url.decode(normalized);
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
