import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/auth/data/models/auth_session_dto.dart';
import 'package:autoscan/features/auth/data/repositories/api_auth_repository.dart';
import 'package:autoscan/features/settings/data/models/workshop_settings_dto.dart';

class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.action);
  final Future<ResponseBody> Function(RequestOptions) action;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => action(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  test(
    'login sends no token; protected requests send the issued token',
    () async {
      final seen = <RequestOptions>[];
      final dio = Dio()
        ..httpClientAdapter = StubAdapter((options) async {
          seen.add(options);
          return jsonResponse({});
        });
      final client = ApiClient(dio: dio);
      addTearDown(client.close);
      await client.post('/auth/login', authenticated: false, data: {});
      client.setAccessToken('current-token');
      await client.get('/settings');
      expect(seen.first.headers.containsKey('authorization'), isFalse);
      expect(seen.last.headers['authorization'], 'Bearer current-token');
    },
  );

  test(
    'late 401 from an old session cannot sign out the new session',
    () async {
      final pending = Completer<ResponseBody>();
      final started = Completer<void>();
      final dio = Dio()
        ..httpClientAdapter = StubAdapter((options) async {
          started.complete();
          return pending.future;
        });
      final client = ApiClient(dio: dio);
      addTearDown(client.close);
      var expired = 0;
      client.onUnauthorized = () => expired++;
      client.setAccessToken('old-token');
      final request = client.get('/settings');
      final rejected = expectLater(request, throwsA(isA<AppFailure>()));
      await started.future;
      client.setAccessToken('new-token');
      pending.complete(jsonResponse({'error': 'invalid_session'}, status: 401));
      await rejected;
      expect(expired, 0);
      expect(client.accessToken == 'new-token', isTrue);
    },
  );

  test('current session 401 clears credentials and notifies once', () async {
    final dio = Dio()
      ..httpClientAdapter = StubAdapter(
        (_) async => jsonResponse({'error': 'invalid_session'}, status: 401),
      );
    final client = ApiClient(dio: dio)..setAccessToken('current-token');
    addTearDown(client.close);
    var expired = 0;
    client.onUnauthorized = () => expired++;
    await expectLater(client.get('/settings'), throwsA(isA<AppFailure>()));
    expect(expired, 1);
    expect(client.accessToken, isNull);
  });

  test(
    'session invalidation cancels a pending login before storing its token',
    () async {
      final pending = Completer<ResponseBody>();
      final dio = Dio()..httpClientAdapter = StubAdapter((_) => pending.future);
      final client = ApiClient(dio: dio);
      addTearDown(client.close);
      final repository = ApiAuthRepository(client);
      final request = repository.login('a@b.com', 'test-password');
      final rejected = expectLater(request, throwsA(isA<AppFailure>()));
      repository.clearSession();
      pending.complete(jsonResponse({}));
      await rejected;
      expect(client.accessToken, isNull);
    },
  );

  test('DTOs reject invalid sessions and malformed workshop fields', () {
    expect(
      () => AuthSessionDto.parse({'access_token': 'bad'}),
      throwsFormatException,
    );
    expect(
      () => WorkshopSettingsDto.parse({'id_publico': 'test'}),
      throwsFormatException,
    );
  });
}
