import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

/// Singleton Dio client with JWT auth interceptor and automatic token refresh.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey  = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Dio get dio => _dio;

  // ---- Token management ----

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey,  value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<String?> getAccessToken()  => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // ---- Interceptors ----

  Future<void> _onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Attempt token refresh
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await Dio().post(
            '${ApiConstants.baseUrl}${ApiConstants.refresh}',
            data: {'refreshToken': refreshToken},
          );
          final newAccessToken = response.data['data']['accessToken'] as String;
          await _storage.write(key: _accessTokenKey, value: newAccessToken);

          // Retry original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          await clearTokens();
        }
      }
    }
    handler.next(err);
  }
}
