import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/search/domain/entities/part_page.dart';
import 'package:autoscan/features/search/presentation/controllers/catalog_search_controller.dart';
import 'package:autoscan/features/search/presentation/views/manual_search_screen.dart';

import 'support/search_fakes.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    CatalogSearchController controller,
  ) async {
    await controller.initialize();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: ManualSearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('search-dtc-query')), 'P0300');
    await tester.tap(find.byKey(const Key('search-dtc-submit')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('search-parts-submit')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('search-parts-submit')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'small screen loads real-shaped results, accurate price and compatibility label',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = CatalogSearchController(
        FakeSearchRepository(),
        canLookupVehicle: true,
      );
      addTearDown(controller.dispose);
      await show(tester, controller);
      await search(tester);
      await tester.scrollUntilVisible(
        find.text('Bobina Denso'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('CLP 45.000'), findsOneWidget);
      expect(
        find.text(
          'Catálogo general: la compatibilidad con tu vehículo aún no está filtrada.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'auditor uses model catalog and can retry after failure into an empty result',
    (tester) async {
      var fail = true;
      final repository = FakeSearchRepository()
        ..partHandler = (_, _, _, _) async {
          if (fail) throw const AppFailure('Servicio no disponible');
          return const PartPage(items: []);
        };
      final controller = CatalogSearchController(
        repository,
        canLookupVehicle: false,
      );
      addTearDown(controller.dispose);
      await show(tester, controller);
      expect(find.byKey(const Key('search-vin')), findsNothing);
      await search(tester);
      expect(find.text('Servicio no disponible'), findsOneWidget);
      fail = false;
      await tester.scrollUntilVisible(
        find.text('Reintentar búsqueda').hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reintentar búsqueda'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sin repuestos disponibles para estos filtros.'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Sin repuestos disponibles para estos filtros.'),
        findsOneWidget,
      );
    },
  );
}
