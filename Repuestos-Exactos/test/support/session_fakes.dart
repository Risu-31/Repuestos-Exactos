import 'dart:async';

import 'package:autoscan/features/auth/domain/entities/auth_session.dart';
import 'package:autoscan/features/auth/domain/repositories/auth_repository.dart';
import 'package:autoscan/features/settings/domain/entities/workshop_settings.dart';
import 'package:autoscan/features/settings/domain/repositories/settings_repository.dart';

AuthSession testSession({
  String name = 'Carla Fuentes',
  String workshopId = '22222222-2222-4222-8222-222222222222',
}) => AuthSession(
  accessToken: List.filled(43, 'A').join(),
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
  userId: '11111111-1111-4111-8111-111111111111',
  workshopId: workshopId,
  name: name,
  role: 'admin',
);

const testWorkshop = WorkshopSettings(
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Taller Los Aromos',
  currency: 'CLP',
  theme: 'claro',
  marginPercent: 30,
  retentionYears: 6,
);

class FakeAuthRepository implements AuthRepository {
  AuthSession result = testSession();
  Exception? loginError;
  Exception? verifyError;
  Exception? logoutError;
  int loginCalls = 0;
  int logoutCalls = 0;
  void Function()? expired;
  @override
  set onUnauthorized(void Function()? callback) => expired = callback;
  @override
  Future<AuthSession> login(String email, String password) async {
    loginCalls++;
    if (loginError case final error?) throw error;
    return result;
  }

  @override
  Future<AuthSession> verify(AuthSession session) async {
    if (verifyError case final error?) throw error;
    return session;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError case final error?) throw error;
  }

  @override
  void clearSession() {}
}

class FakeSettingsRepository implements SettingsRepository {
  Future<WorkshopSettings> Function()? action;
  @override
  Future<WorkshopSettings> load() =>
      action?.call() ?? Future.value(testWorkshop);
}
