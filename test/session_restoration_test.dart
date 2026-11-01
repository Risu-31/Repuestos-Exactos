import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/core/network/session_transport.dart';
import 'package:autoscan/features/auth/domain/entities/auth_session.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';

import 'support/http_stub.dart';
import 'support/session_fakes.dart';

Map<String, Object> renewedBody() => {
  'access_token': List.filled(43, 'N').join(),
  'token_type': 'Bearer',
  'expires_at': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 1))
      .toIso8601String(),
  'usuario': {
    'id_publico': '11111111-1111-4111-8111-111111111111',
    'nombre': 'Test',
    'rol': 'propietario',
  },
  'taller': {'id_publico': '22222222-2222-4222-8222-222222222222'},
};
void main() {
  setUp(() => rememberSessionLogout(false));
  testWidgets(
    'renueva antes de vencer y reintenta un fallo temporal sin expulsar',
    (tester) async {
      var calls = 0;
      final repo = FakeAuthRepository()
        ..restoreAction = () async {
          calls++;
          if (calls == 1) throw const AppFailure('Sin red', statusCode: 503);
          return testSession();
        };
      final auth = AuthController(repo, FakeSettingsRepository());

      await auth.login('demo', 'test');
      await tester.pump(const Duration(minutes: 58));
      await tester.pump();
      expect(calls, 1);
      expect(auth.isAuthenticated, isTrue);
      await tester.pump(const Duration(seconds: 30));
      await tester.pump();
      expect(calls, 2);
      expect(auth.isAuthenticated, isTrue);
      auth.dispose();
    },
  );
  test(
    'restauración espera credencial y recupera usuario/taller sin login',
    () async {
      final pending = Completer<AuthSession?>();
      final repo = FakeAuthRepository()..restoreAction = () => pending.future;
      final auth = AuthController(repo, FakeSettingsRepository());
      addTearDown(auth.dispose);
      final restoring = auth.restoreSession();
      expect(auth.restoring, isTrue);
      expect(auth.isAuthenticated, isFalse);
      pending.complete(testSession());
      await restoring;
      await Future<void>.delayed(Duration.zero);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.restoring, isFalse);
      expect(auth.workshop?.id, testWorkshop.id);
      expect(repo.loginCalls, 0);
    },
  );
  test(
    'fallo de red permite reintentar sin tratarlo como sesión vencida',
    () async {
      final repo = FakeAuthRepository()
        ..restoreAction = () async =>
            throw const AppFailure('Sin red', statusCode: 503);
      final auth = AuthController(repo, FakeSettingsRepository());
      addTearDown(auth.dispose);
      await auth.restoreSession();
      expect(auth.restoreError, isNotNull);
      expect(auth.errorMessage, isNull);
      repo.restoreAction = () async => testSession();
      await auth.restoreSession();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.restoreError, isNull);
    },
  );
  test(
    'sesión revocada vuelve a login y no queda bloqueada en restauración',
    () async {
      final repo = FakeAuthRepository()
        ..restoreAction = () async =>
            throw const AppFailure('Venció', statusCode: 401);
      final auth = AuthController(repo, FakeSettingsRepository());
      addTearDown(auth.dispose);
      await auth.restoreSession();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.restoring, isFalse);
      expect(auth.restoreError, isNull);
    },
  );
  test('logout durante restauración descarta la respuesta tardía', () async {
    final pending = Completer<AuthSession?>();
    final repo = FakeAuthRepository()..restoreAction = () => pending.future;
    final auth = AuthController(repo, FakeSettingsRepository());
    addTearDown(auth.dispose);
    final restoring = auth.restoreSession();
    await auth.logout();
    pending.complete(testSession());
    await restoring;
    expect(auth.isAuthenticated, isFalse);
    expect(auth.restoring, isFalse);
  });
  test(
    'renovación no permite cambiar de taller o perfil silenciosamente',
    () async {
      final repo = FakeAuthRepository();
      final auth = AuthController(repo, FakeSettingsRepository());
      addTearDown(auth.dispose);
      await auth.login('demo', 'test');
      repo.renewed!(
        testSession(workshopId: '33333333-3333-4333-8333-333333333333'),
      );
      expect(auth.isAuthenticated, isFalse);
    },
  );
  test(
    'tres respuestas 401 comparten una renovación y repiten con nuevo acceso',
    () async {
      final started = Completer<void>(), pending = Completer<ResponseBody>();
      var refreshes = 0, successful = 0;
      final dio = Dio()
        ..httpClientAdapter = StubAdapter((options) async {
          if (options.path == '/auth/refresh') {
            refreshes++;
            if (!started.isCompleted) started.complete();
            return pending.future;
          }
          if (options.headers['authorization'] ==
              'Bearer ${List.filled(43, 'N').join()}') {
            successful++;
            return jsonResponse({'ok': true});
          }
          return jsonResponse({'error': 'invalid_session'}, status: 401);
        });
      final client = ApiClient(dio: dio)..acceptLoginToken('old');
      addTearDown(client.close);
      final requests = Future.wait(
        List.generate(3, (_) => client.get('/settings')),
      );
      await started.future;
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 1);
      pending.complete(jsonResponse(renewedBody()));
      await requests;
      expect(successful, 3);
      expect(refreshes, 1);
    },
  );
  test(
    'renovación 503 conserva la sesión actual y no notifica expulsión',
    () async {
      final dio = Dio()
        ..httpClientAdapter = StubAdapter(
          (options) async => jsonResponse(
            {},
            status: options.path == '/auth/refresh' ? 503 : 401,
          ),
        );
      final client = ApiClient(dio: dio)..acceptLoginToken('old');
      addTearDown(client.close);
      var invalidations = 0;
      client.onUnauthorized = () => invalidations++;
      await expectLater(client.get('/settings'), throwsA(isA<AppFailure>()));
      expect(client.accessToken, 'old');
      expect(invalidations, 0);
    },
  );
  test('logout espera renovación en vuelo y no resucita el acceso', () async {
    final started = Completer<void>(), pending = Completer<ResponseBody>();
    var logoutCalls = 0;
    final dio = Dio()
      ..httpClientAdapter = StubAdapter((options) async {
        if (options.path == '/auth/refresh') {
          started.complete();
          return pending.future;
        }
        if (options.path == '/auth/logout') {
          logoutCalls++;
          return jsonResponse({}, status: 204);
        }
        return jsonResponse({});
      });
    final client = ApiClient(dio: dio)..acceptLoginToken('old');
    addTearDown(client.close);
    final renewing = client.renewSession();
    final rejected = expectLater(renewing, throwsA(isA<AppFailure>()));
    await started.future;
    final closing = client.endSession();
    expect(client.accessToken, isNull);
    pending.complete(jsonResponse(renewedBody()));
    await rejected;
    await closing;
    expect(logoutCalls, 1);
    expect(client.accessToken, isNull);
    expect(client.canRestoreSession, isFalse);
  });
  test(
    'logout sin red conserva intención de salida para una nueva instancia',
    () async {
      final dio = Dio()
        ..httpClientAdapter = StubAdapter(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        );
      final client = ApiClient(dio: dio)..acceptLoginToken('old');
      addTearDown(client.close);
      await expectLater(client.endSession(), throwsA(isA<AppFailure>()));
      final fresh = ApiClient(
        dio: Dio()
          ..httpClientAdapter = StubAdapter((_) async => jsonResponse({})),
      );
      addTearDown(fresh.close);
      expect(fresh.canRestoreSession, isFalse);
      await expectLater(fresh.renewSession(), throwsA(isA<AppFailure>()));
    },
  );
}
