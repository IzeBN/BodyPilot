import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = 'https://api.bodypilot.online';
const baseUrl = _baseUrl;

late final Dio apiDio;

class TokenStorage {
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  static Future<void> save(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, access);
    await prefs.setString(_keyRefresh, refresh);
  }

  static Future<String?> getAccess() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccess);
  }

  static Future<String?> getRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefresh);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
  }
}

typedef LogoutCallback = Future<void> Function();
LogoutCallback? _onLogout;

void setLogoutCallback(LogoutCallback cb) => _onLogout = cb;

Future<void> initApiClient() async {
  apiDio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  apiDio.interceptors.add(_AuthInterceptor(apiDio));
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  Completer<String?>? _refreshCompleter;

  static bool _isAuthPath(String path) =>
      path.contains('/api/v1/auth/login') ||
      path.contains('/api/v1/auth/register') ||
      path.contains('/api/v1/auth/refresh') ||
      path.contains('/api/v1/auth/apple');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthPath(options.path)) {
      final token = await TokenStorage.getAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (_isAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    if (_refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) {
        try {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retryResp = await _dio.fetch(opts);
          handler.resolve(retryResp);
        } catch (_) {
          handler.next(err);
        }
      } else {
        handler.next(err);
      }
      return;
    }

    _refreshCompleter = Completer<String?>();
    String? newAccess;
    try {
      final refreshToken = await TokenStorage.getRefresh();
      if (refreshToken == null) {
        if (!_refreshCompleter!.isCompleted) _refreshCompleter!.complete(null);
        await _handleLogout();
        handler.next(err);
        return;
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final resp = await refreshDio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = resp.data as Map<String, dynamic>;
      newAccess = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;
      await TokenStorage.save(newAccess, newRefresh);

      if (!_refreshCompleter!.isCompleted) _refreshCompleter!.complete(newAccess);
    } catch (_) {
      if (!_refreshCompleter!.isCompleted) _refreshCompleter!.complete(null);
      _refreshCompleter = null;
      await _handleLogout();
      handler.next(err);
      return;
    }

    _refreshCompleter = null;

    try {
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccess';
      final retryResp = await _dio.fetch(opts);
      handler.resolve(retryResp);
    } catch (e) {
      if (e is DioException) {
        handler.next(e);
      } else {
        handler.next(err);
      }
    }
  }

  Future<void> _handleLogout() async {
    await TokenStorage.clear();
    await _onLogout?.call();
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class PaymentRequiredException implements Exception {
  const PaymentRequiredException();
  @override
  String toString() => 'PaymentRequiredException';
}
