import 'package:flutter/foundation.dart';
import 'package:autoscan/core/errors/app_failure.dart';

import '../../domain/entities/google_login_result.dart';
import '../../domain/repositories/google_auth_repository.dart';
import 'auth_controller.dart';

class GoogleAuthController extends ChangeNotifier {
  GoogleAuthController(this._repository, this._auth);
  final GoogleAuthRepository _repository;
  final AuthController _auth;
  String? clientId;
  String? nonce;
  GoogleLoginResult? pending;
  String? error;
  bool busy = false;
  bool configured = false;
  bool _disposed = false;
  int _generation = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> prepare() async {
    if (busy) return;
    final generation = ++_generation;
    busy = true;
    error = null;
    nonce = null;
    pending = null;
    _notify();
    try {
      final id = await _repository.clientId();
      if (_disposed || generation != _generation) return;
      configured = id != null;
      clientId = id;
      if (id != null) {
        final challenge = await _repository.challenge();
        if (_disposed || generation != _generation) return;
        nonce = challenge;
      }
    } on AppFailure catch (e) {
      if (generation == _generation) error = e.message;
    } finally {
      if (generation == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> authenticate(String token) async {
    if (busy || nonce == null || !_auth.beginExternalLogin()) return;
    final challenge = nonce!;
    nonce = null;
    busy = true;
    error = null;
    final generation = ++_generation;
    _notify();
    try {
      final result = await _repository.login(token, challenge);
      if (_disposed || generation != _generation) return;
      if (result.session != null) {
        _auth.acceptSession(result.session!);
      } else {
        pending = result;
      }
    } on AppFailure catch (e) {
      if (generation == _generation) error = e.message;
    } finally {
      _auth.endExternalLogin();
      if (generation == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> complete(
    String action, {
    String? workshopName,
    String? invitationToken,
    String? password,
  }) async {
    final ticket = pending?.onboardingToken;
    if (busy || ticket == null || !_auth.beginExternalLogin()) return;
    final generation = ++_generation;
    busy = true;
    error = null;
    _notify();
    try {
      final session = await _repository.complete(
        ticket,
        action,
        workshopName: workshopName,
        invitationToken: invitationToken,
        password: password,
      );
      if (_disposed || generation != _generation) return;
      pending = null;
      _auth.acceptSession(session);
    } on AppFailure catch (e) {
      if (generation == _generation) error = e.message;
    } finally {
      _auth.endExternalLogin();
      if (generation == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  void sdkError() {
    error =
        'No pudimos cargar Google. Revisa tu conexión y vuelve a intentarlo.';
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
