import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';

part 'auth_provider.g.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  const AuthState({this.status = AuthStatus.unknown});
  AuthState copyWith({AuthStatus? status}) =>
      AuthState(status: status ?? this.status);
}

@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() {
    setLogoutCallback(_logout);
    _checkToken();
    return const AuthState();
  }

  Future<void> _checkToken() async {
    final token = await TokenStorage.getAccess();
    state = AuthState(
      status: token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> loginWithTokens(String access, String refresh) async {
    await TokenStorage.save(access, refresh);
    state = const AuthState(status: AuthStatus.authenticated);
  }

  Future<void> _logout() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
