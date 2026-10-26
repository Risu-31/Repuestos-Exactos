import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/history/domain/entities/history_page.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';
import 'package:autoscan/features/history/presentation/controllers/history_controller.dart';

import 'support/history_fakes.dart';

void main() {
  test('late initial response cannot overwrite a new filter', () async {
    final pending = Completer<HistoryPage>();
    final repository = FakeHistoryRepository()
      ..handler = (status, _) async => status == null
          ? pending.future
          : HistoryPage(items: [historyEntry('filtered', status: status)]);
    final controller = HistoryController(repository);
    addTearDown(controller.dispose);
    final old = controller.refresh();
    await controller.filter(HistoryStatus.completado);
    pending.complete(HistoryPage(items: [historyEntry('stale')]));
    await old;
    expect(controller.items.single.id, 'filtered');
    expect(controller.status, HistoryStatus.completado);
  });

  test('page failures preserve results and retry the same cursor', () async {
    var fail = true;
    final repository = FakeHistoryRepository()
      ..handler = (_, cursor) async {
        if (cursor == null) {
          return HistoryPage(
            items: [historyEntry('first')],
            nextCursor: 'next',
          );
        }
        if (fail) throw const AppFailure('Sin conexión');
        return HistoryPage(
          items: [historyEntry('first'), historyEntry('second')],
        );
      };
    final controller = HistoryController(repository);
    addTearDown(controller.dispose);
    await controller.refresh();
    await controller.loadMore();
    expect(controller.items.single.id, 'first');
    expect(controller.pageError, 'Sin conexión');
    fail = false;
    await controller.loadMore();
    expect(controller.items.map((item) => item.id), ['first', 'second']);
    expect(controller.hasMore, isFalse);
    expect(repository.calls.map((call) => call.cursor), [null, 'next', 'next']);
  });

  test(
    'filter change discards pending page responses and resets cursor',
    () async {
      final pending = Completer<HistoryPage>();
      final repository = FakeHistoryRepository()
        ..handler = (status, cursor) async {
          if (status != null) return const HistoryPage(items: []);
          if (cursor != null) return pending.future;
          return HistoryPage(
            items: [historyEntry('first')],
            nextCursor: 'next',
          );
        };
      final controller = HistoryController(repository);
      addTearDown(controller.dispose);
      await controller.refresh();
      final more = controller.loadMore();
      await controller.filter(HistoryStatus.cancelado);
      pending.complete(HistoryPage(items: [historyEntry('stale')]));
      await more;
      expect(controller.items, isEmpty);
      expect(controller.hasMore, isFalse);
      expect(controller.loadingMore, isFalse);
    },
  );

  test('dispose ignores pending completion', () async {
    final pending = Completer<HistoryPage>();
    final repository = FakeHistoryRepository()
      ..handler = (_, _) => pending.future;
    final controller = HistoryController(repository);
    final loading = controller.refresh();
    controller.dispose();
    pending.complete(HistoryPage(items: [historyEntry('late')]));
    await loading;
    expect(controller.items, isEmpty);
  });

  test(
    'initial error can be retried and repeated cursor is rejected',
    () async {
      var fail = true;
      final repository = FakeHistoryRepository()
        ..handler = (_, cursor) async {
          if (fail) throw const AppFailure('Servicio no disponible');
          return HistoryPage(
            items: [historyEntry('first')],
            nextCursor: 'same',
          );
        };
      final controller = HistoryController(repository);
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.errorMessage, 'Servicio no disponible');
      fail = false;
      await controller.refresh();
      expect(controller.errorMessage, isNull);
      await controller.loadMore();
      expect(controller.pageError, contains('Actualiza la lista'));
      expect(controller.items.length, 1);
    },
  );
}
