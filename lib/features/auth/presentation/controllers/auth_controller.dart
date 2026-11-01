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
    _auth.onSessionRenewed = _sessionRenewed;
  }
  final AuthRepository _auth;
  final SettingsRepository _settings;
  AuthSession? _session;
  WorkshopSettings? _workshop;
  Timer? _expiry;
  int _generation = 0;
  bool _disposed = false;
  bool busy = false;
  bool restoring = false;
  String? restoreError;
  bool loadingWorkshop = false;
  String? errorMessage;
  String? workshopError;

  AuthSession? get session => _session;
  WorkshopSettings? get workshop => _workshop;
  bool get isAuthenticated => _session != null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Restaura desde cookie antes de decidir si corresponde mostrar login.
  Future<void> restoreSession() async {
    if (restoring || busy || _disposed) return;
    final generation = ++_generation;
    restoring = true;
    restoreError = null;
    _notify();
    try {
      final restored = await _auth.restoreSession();
      if (_disposed || generation != _generation) return;
      if (restored != null) {
        restoring = false;
        acceptSession(restored);
      }
    } on AppFailure catch (e) {
      if (generation != _generation || _disposed) return;
      if (e.statusCode == 401 || e.statusCode == 403) {
        _auth.clearSession();
        _session = null;
      } else {
        restoreError = 'No pudimos recuperar tu sesión. Revisa la conexión y vuelve a intentarlo.';
      }
    } finally {
      if (generation == _generation && !_disposed) {
        restoring = false;
        _notify();
      }
    }
  }

  void continueToLogin() {
    ++_generation;
    restoring = false;
    restoreError = null;
    _auth.clearSession();
    _session = null;
    _workshop = null;
    _notify();
  }

  void _scheduleRenewal(Duration remaining) {
    _expiry?.cancel();
    final delay = remaining > const Duration(minutes: 2)
        ? remaining - const Duration(minutes: 2)
        : remaining;
    _expiry = Timer(delay, () => unawaited(_renewSession()));
  }

  void _sessionRenewed(AuthSession value) {
    if (_disposed || restoring || busy || _session == null) return;
    final previous = _session!;
    if (previous.userId != value.userId ||
        previous.workshopId != value.workshopId ||
        previous.role != value.role) {
      invalidateSession();
      return;
    }
    _session = value;
    _scheduleRenewal(value.expiresAt.difference(DateTime.now().toUtc()));
    _notify();
  }

  Future<void> _renewSession() async {
    if (_disposed || _session == null) return;
    final generation = _generation;
    try {
      final value = await _auth.restoreSession();
      if (_disposed || generation != _generation) return;
      if (value == null) {
        invalidateSession();
        return;
      }
      _sessionRenewed(value);
    } on AppFailure catch (e) {
      if (_disposed || generation != _generation) return;
      if (e.statusCode == 401 || e.statusCode == 403) {
        invalidateSession();
      } else {
        _expiry = Timer(
          const Duration(seconds: 30),
          () => unawaited(_renewSession()),
        );
      }
    }
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
      _scheduleRenewal(remaining);
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

  /// Excluye solicitudes de contraseña mientras se verifica Google.
  bool beginExternalLogin() {
    if (_disposed || busy) return false;
    _generation++;
    busy = true;
    errorMessage = null;
    _notify();
    return true;
  }

  void endExternalLogin() {
    if (!_disposed) {
      busy = false;
      _notify();
    }
  }

  /// Recibe una sesión validada por el repositorio de Google.
  void acceptSession(AuthSession session) {
    if (_disposed) return;
    final remaining = session.expiresAt.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      invalidateSession();
      return;
    }
    _generation++;
    _session = session;
    restoring = false;
    restoreError = null;
    _workshop = null;
    busy = false;
    loadingWorkshop = false;
    workshopError = null;
    errorMessage = null;
    _expiry?.cancel();
    _scheduleRenewal(remaining);
    _notify();
    unawaited(refreshWorkshop());
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
    restoring = false;
    restoreError = null;
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
    restoring = false;
    restoreError = null;
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
    _auth.onSessionRenewed = null;
    super.dispose();
  }
}
