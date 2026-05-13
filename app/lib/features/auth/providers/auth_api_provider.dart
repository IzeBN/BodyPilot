import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';

part 'auth_api_provider.g.dart';

@riverpod
AuthApiService authApi(Ref ref) => AuthApiService(ref);

class AuthApiService {
  final Ref _ref;
  AuthApiService(this._ref);

  Future<void> login(String email, String password) async {
    final resp = await apiDio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = resp.data as Map<String, dynamic>;
    await _ref.read(authProvider.notifier).loginWithTokens(
      data['access_token'] as String,
      data['refresh_token'] as String,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final resp = await apiDio.post('/api/v1/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });
    final data = resp.data as Map<String, dynamic>;
    await _ref.read(authProvider.notifier).loginWithTokens(
      data['access_token'] as String,
      data['refresh_token'] as String,
    );
  }
}
