import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/keycloak_service.dart';
import '../auth/auth_provider.dart';
import '../env.dart';

final dioProvider = Provider<Dio>((ref) {
  final keycloak = ref.read(keycloakServiceProvider.notifier);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(_JwtInterceptor(dio, keycloak));
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  return dio;
});

class _JwtInterceptor extends Interceptor {
  final Dio _dio;
  final KeycloakService _keycloak;
  bool _isRefreshing = false;

  _JwtInterceptor(this._dio, this._keycloak);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _keycloak.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _keycloak.refreshIfNeeded();
        if (refreshed) {
          final newToken = await _keycloak.getAccessToken();
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        } else {
          await _keycloak.logout();
        }
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}
