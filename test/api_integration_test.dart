import 'package:autoscan/features/history/data/repositories/api_history_repository.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/auth/data/repositories/api_auth_repository.dart';
import 'package:autoscan/features/settings/data/repositories/api_settings_repository.dart';

void main() {
  test(
    'Dio connects Flutter repositories to login, me, settings and logout',
    () async {
      final client = ApiClient(baseUrl: Platform.environment['TEST_API_URL']!);
      addTearDown(client.close);
      final auth = ApiAuthRepository(client);
      final settings = ApiSettingsRepository(client);
      final history = ApiHistoryRepository(client);
      final password = Platform.environment['TEST_DEMO_PASSWORD']!;
      final first = await auth.login('admin@losaromos.example', password);
      final me = await auth.verify(first);
      expect(me.userId, first.userId);
      final firstWorkshop = await settings.load();
      expect(firstWorkshop.id, first.workshopId);
      expect(firstWorkshop.currency, 'CLP');
      final firstHistory = await history.load(limit: 2);
      expect(firstHistory.items, isNotEmpty);
      expect(firstHistory.nextCursor, isNotNull);
      final nextHistory = await history.load(
        limit: 2,
        cursor: firstHistory.nextCursor,
      );
      expect(
        nextHistory.items
            .map((item) => item.id)
            .toSet()
            .intersection(firstHistory.items.map((item) => item.id).toSet()),
        isEmpty,
      );
      final filtered = await history.load(status: HistoryStatus.cotizado);
      expect(
        filtered.items.every((item) => item.status == HistoryStatus.cotizado),
        isTrue,
      );
      await auth.logout();
      client.setAccessToken(first.accessToken);
      await expectLater(
        client.get('/auth/me'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.statusCode,
            'status',
            401,
          ),
        ),
      );
      final second = await auth.login('admin@nuble.example', password);
      final secondWorkshop = await settings.load();
      expect(secondWorkshop.id, second.workshopId);
      expect(secondWorkshop.id == firstWorkshop.id, isFalse);
      final secondHistory = await history.load(limit: 100);
      expect(
        secondHistory.items
            .map((item) => item.id)
            .toSet()
            .intersection(firstHistory.items.map((item) => item.id).toSet()),
        isEmpty,
      );
      await auth.logout();
    },
    skip:
        Platform.environment['TEST_API_URL'] == null ||
        Platform.environment['TEST_DEMO_PASSWORD'] == null,
  );
}
