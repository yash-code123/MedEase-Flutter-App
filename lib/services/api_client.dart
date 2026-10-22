import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Thin wrapper around Dio that:
/// - points at the SAME backend as the MedEase website
/// - attaches the JWT bearer token to every request (mirrors app.js on web)
/// - centralizes 401 handling (auto-logout on expired/invalid token)
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // TEMPORARY DEBUG LOGGER — prints every request's full URL to the
    // terminal so we can see exactly what's being sent. Remove once
    // the login issue is confirmed fixed.
    _dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: false,
      error: true,
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  static const _tokenKey = 'medease_jwt_token';
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  void Function()? onUnauthorized;

  Dio get dio => _dio;

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}

String describeDioError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (data is Map && data['error'] != null) return data['error'].toString();
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server is taking a while to respond — it may be waking up from sleep. Try again in a few seconds.';
      case DioExceptionType.connectionError:
        return 'Could not reach the MedEase server. Check your internet connection.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
  return error.toString();
}