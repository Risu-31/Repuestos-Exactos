import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/history/domain/entities/history_page.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';
import 'package:autoscan/features/history/presentation/controllers/history_controller.dart';
import 'package:autoscan/features/history/presentation/views/history_screen.dart';

import 'support/history_fakes.dart';

void main() {
  Widget app(HistoryController controller) => ChangeNotifierProvider.value(
    value: controller,
    child: MaterialApp(home: const HistoryScreen()),
  );
  testWidgets(
    'loading, real results, next page and empty filter on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<HistoryPage>();
      final repository = FakeHistoryRepository()
        ..handler = (status, cursor) async {
          if (status == HistoryStatus.cancelado) {
            return const HistoryPage(items: []);
          }
          if (cursor != null) {
            return HistoryPage(items: [historyEntry('second', hidden: true)]);
          }
          return pending.future;
        };
      final controller = HistoryController(repository);
      addTearDown(controller.dispose);
      final load = controller.refresh();
      await tester.pumpWidget(app(controller));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(
        HistoryPage(items: [historyEntry('first')], nextCursor: 'next'),
      );
      await load;
      await tester.pumpAndSettle();
      expect(find.text('Toyota Yaris 2018'), findsOneWidget);
      expect(find.text('2 fallas registradas'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('history-load-more')));
      await tester.tap(find.byKey(const Key('history-load-more')));
      await tester.pumpAndSettle();
      expect(find.text('Vehículo no disponible'), findsOneWidget);
      await tester.ensureVisible(find.text('Cancelado'));
      await tester.tap(find.text('Cancelado'));
      await tester.pumpAndSettle();
      expect(find.text('Sin diagnósticos'), findsOneWidget);
      expect(repository.calls.last.status, HistoryStatus.cancelado);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('service error exposes retry and recovers', (tester) async {
    var fail = true;
    final repository = FakeHistoryRepository()
      ..handler = (_, _) async {
        if (fail) {
          throw const AppFailure('No pudimos conectar con el servicio.');
        }
        return const HistoryPage(items: []);
      };
    final controller = HistoryController(repository);
    addTearDown(controller.dispose);
    await controller.refresh();
    await tester.pumpWidget(app(controller));
    expect(find.text('No pudimos conectar con el servicio.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Sin diagnósticos'), findsOneWidget);
  });
}
