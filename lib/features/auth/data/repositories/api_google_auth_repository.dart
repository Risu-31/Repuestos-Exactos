import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';

import '../models/auth_session_dto.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/google_login_result.dart';
import '../../domain/repositories/google_auth_repository.dart';

class ApiGoogleAuthRepository implements GoogleAuthRepository {
  const ApiGoogleAuthRepository(this._client);
  final ApiClient _client;
  Map<String, dynamic> _object(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const AppFailure('El servicio devolvió una respuesta inválida.');
    }
    return data;
  }

  @override
  Future<String?> clientId() async {
    final data = _object(
      await _client.get('/auth/google/config', authenticated: false),
    );
    final id = data['client_id'];
    if (data['enabled'] == false) return null;
    if (id is! String || !id.endsWith('.apps.googleusercontent.com')) {
      throw const AppFailure('La configuración de Google no es válida.');
    }
    return id;
  }

  @override
  Future<String> challenge() async {
    final data = _object(
      await _client.post('/auth/google/challenge', authenticated: false),
    );
    final nonce = data['nonce'];
    if (nonce is! String || nonce.length != 43) {
      throw const AppFailure('No pudimos preparar el ingreso con Google.');
    }
    return nonce;
  }

  AuthSession _session(Object? data) {
    try {
      final s = AuthSessionDto.parse(data);
      _client.setAccessToken(s.accessToken);
      return s;
    } on FormatException {
      throw const AppFailure('El servicio devolvió una sesión inválida.');
    }
  }

  @override
  Future<GoogleLoginResult> login(String idToken, String nonce) async {
    final data = _object(
      await _client.post(
        '/auth/google',
        authenticated: false,
        data: {'id_token': idToken, 'nonce': nonce},
      ),
    );
    if (data['access_token'] != null) {
      return GoogleLoginResult(session: _session(data));
    }
    if (data['status'] != 'onboarding' ||
        data['onboarding_token'] is! String ||
        (data['onboarding_token'] as String).length != 43 ||
        data['email'] is! String ||
        data['name'] is! String ||
        data['requires_link'] is! bool ||
        data['can_register'] is! bool) {
      throw const AppFailure('No pudimos validar tu cuenta.');
    }
    return GoogleLoginResult(
      onboardingToken: data['onboarding_token'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      requiresLink: data['requires_link'] as bool,
      canRegister: data['can_register'] as bool,
    );
  }

  @override
  Future<AuthSession> complete(
    String ticket,
    String action, {
    String? workshopName,
    String? invitationToken,
    String? password,
  }) async => _session(
    await _client.post(
      '/auth/google/complete',
      authenticated: false,
      data: {
        'onboarding_token': ticket,
        'action': action,
        'workshop_name': ?workshopName,
        'invitation_token': ?invitationToken,
        'password': ?password,
      },
    ),
  );
}
