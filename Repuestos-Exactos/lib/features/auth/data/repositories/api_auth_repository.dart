import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/auth/data/models/auth_session_dto.dart';
import 'package:autoscan/features/auth/domain/entities/auth_session.dart';
import 'package:autoscan/features/auth/domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);
  final ApiClient _client;
  int _generation = 0;
  @override
  set onUnauthorized(void Function()? callback) =>
      _client.onUnauthorized = callback;

  @override
  Future<AuthSession> login(String email, String password) async {
    final generation = ++_generation;
    final data = await _client.post(
      '/auth/login',
      authenticated: false,
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );
    if (generation != _generation) {
      throw const AppFailure("La solicitud fue cancelada.");
    }
    final session = _parse(data);
    _client.setAccessToken(session.accessToken);
    return session;
  }

  @override
  Future<AuthSession> verify(AuthSession session) async {
    final fresh = _parse(
      await _client.get('/auth/me'),
      accessToken: session.accessToken,
    );
    if (fresh.userId != session.userId ||
        fresh.workshopId != session.workshopId ||
        fresh.role != session.role) {
      clearSession();
      throw const AppFailure('Vuelve a iniciar sesión.', statusCode: 401);
    }
    return fresh;
  }

  AuthSession _parse(Object? data, {String? accessToken}) {
    try {
      return AuthSessionDto.parse(data, accessToken: accessToken);
    } on FormatException catch (_) {
      throw const AppFailure('El servicio devolvió una sesión inválida.');
    }
  }

  @override
  Future<void> logout() async {
    final token = _client.accessToken;
    try {
      await _client.post('/auth/logout');
    } finally {
      _client.clearAccessTokenIfMatches(token);
    }
  }

  @override
  void clearSession() {
    _generation++;
    _client.setAccessToken(null);
  }
}
