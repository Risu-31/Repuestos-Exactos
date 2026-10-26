import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoscan/features/settings/domain/entities/workshop_settings.dart';

import 'support/session_fakes.dart';

void main() {
  test(
    'invalid credentials leave the app signed out with a useful error',
    () async {
      final repo = FakeAuthRepository()
        ..loginError = const AppFailure(
          'Correo o contraseña incorrectos.',
          statusCode: 401,
        );
      final auth = AuthController(repo, FakeSettingsRepository());
      addTearDown(auth.dispose);
      await auth.login('user@example.com', 'incorrect');
      expect(auth.isAuthenticated, isFalse);
      expect(auth.busy, isFalse);
      expect(auth.errorMessage, contains('incorrectos'));
    },
  );

  test('late workshop response cannot repopulate data after logout', () async {
    final pending = Completer<WorkshopSettings>();
    final settings = FakeSettingsRepository()..action = () => pending.future;
    final auth = AuthController(FakeAuthRepository(), settings);
    addTearDown(auth.dispose);
    await auth.login('user@example.com', 'test-password');
    await Future<void>.delayed(Duration.zero);
    expect(auth.loadingWorkshop, isTrue);
    await auth.logout();
    pending.complete(testWorkshop);
    await Future<void>.delayed(Duration.zero);
    expect(auth.session, isNull);
    expect(auth.workshop, isNull);
  });

  test('API rejection clears both identity and workshop', () async {
    final repo = FakeAuthRepository();
    final auth = AuthController(repo, FakeSettingsRepository());
    addTearDown(auth.dispose);
    await auth.login('user@example.com', 'test-password');
    await Future<void>.delayed(Duration.zero);
    expect(auth.workshop, isNotNull);
    repo.expired?.call();
    expect(auth.session, isNull);
    expect(auth.workshop, isNull);
  });

  test(
    'workshop errors are retryable without inventing workshop information',
    () async {
      final settings = FakeSettingsRepository()
        ..action = () async =>
            throw const AppFailure('Servicio no disponible.');
      final auth = AuthController(FakeAuthRepository(), settings);
      addTearDown(auth.dispose);
      await auth.login('user@example.com', 'test-password');
      await Future<void>.delayed(Duration.zero);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.workshop, isNull);
      expect(auth.workshopError, isNotNull);
      settings.action = null;
      await auth.refreshWorkshop();
      expect(auth.workshop?.name, testWorkshop.name);
      expect(auth.workshopError, isNull);
    },
  );

  test(
    'logout still removes local identity if the server is unavailable',
    () async {
      final repo = FakeAuthRepository()
        ..logoutError = const AppFailure('Sin conexión.');
      final auth = AuthController(repo, FakeSettingsRepository());
      addTearDown(auth.dispose);
      await auth.login('user@example.com', 'test-password');
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.errorMessage, contains('este dispositivo'));
    },
  );
}
