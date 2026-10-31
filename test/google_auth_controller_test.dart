import 'package:flutter/material.dart';
import 'package:autoscan/features/auth/presentation/widgets/google_access_panel.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/auth/domain/entities/auth_session.dart';
import 'package:autoscan/features/auth/domain/entities/google_login_result.dart';
import 'package:autoscan/features/auth/domain/repositories/google_auth_repository.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoscan/features/auth/presentation/controllers/google_auth_controller.dart';

import 'support/session_fakes.dart';

class _GoogleRepository implements GoogleAuthRepository {
  String? id = 'client.apps.googleusercontent.com';
  GoogleLoginResult result = const GoogleLoginResult(
    onboardingToken: 'ticket',
    email: 'owner@gmail.com',
    name: 'Dueño',
    canRegister: true,
  );
  Future<GoogleLoginResult> Function()? loginAction;
  Exception? completeError;
  String? acceptedAction;
  @override
  Future<String?> clientId() async => id;
  @override
  Future<String> challenge() async => 'nonce';
  @override
  Future<GoogleLoginResult> login(String token, String nonce) async =>
      loginAction?.call() ?? result;
  @override
  Future<AuthSession> complete(
    String ticket,
    String action, {
    String? workshopName,
    String? invitationToken,
    String? password,
  }) async {
    acceptedAction = action;
    if (completeError != null) throw completeError!;
    return testSession();
  }
}

void main() {
  late FakeAuthRepository password;
  late AuthController auth;
  late _GoogleRepository repository;
  late GoogleAuthController google;
  setUp(() {
    password = FakeAuthRepository();
    auth = AuthController(password, FakeSettingsRepository());
    repository = _GoogleRepository();
    google = GoogleAuthController(repository, auth);
  });
  tearDown(() {
    google.dispose();
    auth.dispose();
  });
  test('sin Client ID mantiene disponible el login tradicional', () async {
    repository.id = null;
    await google.prepare();
    expect(google.configured, isFalse);
    expect(google.nonce, isNull);
    await auth.login('admin@example.test', 'password');
    expect(auth.isAuthenticated, isTrue);
  });
  test(
    'Google identificado sin taller no obtiene sesión ni permisos',
    () async {
      await google.prepare();
      await google.authenticate('id-token');
      expect(auth.isAuthenticated, isFalse);
      expect(google.pending?.email, 'owner@gmail.com');
      expect(google.nonce, isNull);
      expect(auth.busy, isFalse);
    },
  );
  test('alta completada adopta la sesión validada y carga el taller', () async {
    await google.prepare();
    await google.authenticate('id-token');
    await google.complete('register', workshopName: 'Mi taller');
    await Future<void>.delayed(Duration.zero);
    expect(repository.acceptedAction, 'register');
    expect(auth.session?.role, 'propietario');
    expect(auth.workshop?.id, testWorkshop.id);
  });
  test('invitación inválida deja reintentar sin iniciar sesión', () async {
    await google.prepare();
    await google.authenticate('id-token');
    repository.completeError = const AppFailure('La invitación venció.');
    await google.complete('accept', invitationToken: 'invalid');
    expect(auth.isAuthenticated, isFalse);
    expect(google.pending, isNotNull);
    expect(google.error, contains('venció'));
  });
  test('no permite dos métodos de login simultáneos', () async {
    final gate = Completer<GoogleLoginResult>();
    repository.loginAction = () => gate.future;
    await google.prepare();
    final attempt = google.authenticate('id-token');
    await auth.login('other@example.test', 'password');
    expect(password.loginCalls, 0);
    gate.complete(repository.result);
    await attempt;
    expect(auth.busy, isFalse);
  });

  testWidgets('registro visible y funcional en pantalla estrecha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await google.prepare();
    await google.authenticate('id-token');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoogleAccessPanel(controller: google),
          ),
        ),
      ),
    );
    expect(find.text('Crear mi taller'), findsOneWidget);
    expect(find.text('Aceptar invitación'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('google-workshop-name')),
      'Taller de prueba',
    );
    await tester.tap(find.byKey(const Key('google-register-workshop')));
    await tester.pumpAndSettle();
    expect(repository.acceptedAction, 'register');
    expect(auth.isAuthenticated, isTrue);
    expect(tester.takeException(), isNull);
    await auth.logout();
    await tester.pumpAndSettle();
  });
}
