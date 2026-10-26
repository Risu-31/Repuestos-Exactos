import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/auth/domain/entities/auth_session.dart';
import 'package:autoscan/features/auth/domain/repositories/auth_repository.dart';
import 'package:autoscan/features/settings/domain/entities/workshop_settings.dart';
import 'package:autoscan/features/settings/domain/repositories/settings_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._auth, this._settings) {
    _auth.onUnauthorized = invalidateSession;
  }
  final AuthRepository _auth;
  final SettingsRepository _settings;
  AuthSession? _session;
  WorkshopSettings? _workshop;
  Timer? _expiry;
  int _generation = 0;
  bool _disposed = false;
  bool busy = false;
  bool loadingWorkshop = false;
  String? errorMessage;
  String? workshopError;

  AuthSession? get session => _session;
  WorkshopSettings? get workshop => _workshop;
  bool get isAuthenticated => _session != null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (busy) return;
    final generation = ++_generation;
    busy = true;
    errorMessage = null;
    _notify();
    try {
      final session = await _auth.login(email, password);
      if (_disposed || generation != _generation) return;
      final remaining = session.expiresAt.difference(DateTime.now().toUtc());
      if (remaining <= Duration.zero) {
        _auth.clearSession();
        throw const AppFailure('Tu sesión terminó. Vuelve a ingresar.');
      }
      _session = session;
      _workshop = null;
      _expiry?.cancel();
      _expiry = Timer(remaining, invalidateSession);
    } on AppFailure catch (error) {
      if (generation == _generation) errorMessage = error.message;
    } finally {
      if (generation == _generation && !_disposed) {
        busy = false;
        _notify();
      }
    }
    if (isAuthenticated && generation == _generation && !_disposed) {
      unawaited(refreshWorkshop());
    }
  }

  Future<void> refreshWorkshop() async {
    final current = _session;
    if (current == null || loadingWorkshop) return;
    final generation = _generation;
    loadingWorkshop = true;
    workshopError = null;
    _notify();
    try {
      final verified = await _auth.verify(current);
      if (_disposed || generation != _generation) return;
      final workshop = await _settings.load();
      if (_disposed || generation != _generation) return;
      if (workshop.id != verified.workshopId) {
        invalidateSession();
        return;
      }
      _session = verified;
      _workshop = workshop;
    } on AppFailure catch (error) {
      if (generation == _generation) {
        if (error.statusCode == 401) {
          invalidateSession();
        } else {
          workshopError = error.message;
        }
      }
    } finally {
      if (generation == _generation && !_disposed) {
        loadingWorkshop = false;
        _notify();
      }
    }
  }

  void invalidateSession() {
    if (_disposed) return;
    _generation++;
    _expiry?.cancel();
    _auth.clearSession();
    _session = null;
    _workshop = null;
    loadingWorkshop = false;
    busy = false;
    workshopError = null;
    errorMessage = 'Tu sesión terminó. Vuelve a ingresar.';
    _notify();
  }

  Future<void> logout() async {
    if (busy) return;
    final generation = ++_generation;
    _expiry?.cancel();
    busy = true;
    _notify();
    String? notice;
    try {
      await _auth.logout();
    } on AppFailure catch (_) {
      notice =
          'Sesión cerrada en este dispositivo. No pudimos confirmar '
          'el cierre en el servidor.';
    } finally {
      if (generation == _generation && !_disposed) {
        _auth.clearSession();
        _session = null;
        _workshop = null;
        loadingWorkshop = false;
        workshopError = null;
        busy = false;
        errorMessage = notice;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _expiry?.cancel();
    _auth.onUnauthorized = null;
    super.dispose();
  }
}
