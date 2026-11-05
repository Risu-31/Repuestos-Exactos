import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/offers/data/models/offer_dto.dart';
import 'package:autoscan/features/offers/data/repositories/api_offers_repository.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_provider.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_environment.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_search_result.dart';
import 'package:autoscan/features/offers/domain/entities/saved_part.dart';
import 'package:autoscan/features/offers/domain/entities/saved_parts_page.dart';
import 'package:autoscan/features/offers/domain/repositories/offers_repository.dart';
import 'package:autoscan/features/offers/presentation/controllers/offers_controller.dart';
import 'package:autoscan/features/offers/presentation/controllers/saved_parts_controller.dart';
import 'package:autoscan/features/offers/presentation/views/saved_parts_screen.dart';
import 'package:autoscan/features/offers/presentation/widgets/marketplace_search_panel.dart';
import 'package:autoscan/features/search/domain/entities/catalog_option.dart';

import 'support/http_stub.dart';

final sample = <String, dynamic>{
  'provider': 'ebay',
  'environment': 'sandbox',
  'kind': 'listing',
  'external_id': 'v1|110590963673|0',
  'title': 'Bujía de prueba',
  'price': '5.00',
  'currency': 'USD',
  'url': 'https://sandbox.ebay.com/itm/110590963673',
  'queried_at': '2026-11-03T12:00:00Z',
  'compatibility': 'unverified',
  'offer_token': 'a' * 43,
};
SavedPart savedEbay() => SavedPart(
  id: 's',
  externalId: 'v1|110590963673|0',
  url: sample['url'] as String,
  code: 'P0301',
  component: 'Bujía',
  author: 'QA',
  note: 'Revisar',
  createdAt: DateTime.utc(2026),
  kind: 'listing',
  provider: MarketplaceProvider.ebay,
  environment: MarketplaceEnvironment.sandbox,
);

class _Repository implements OffersRepository {
  Completer<MarketplaceSearchResult>? pending;
  Completer<SavedPart>? saving;
  bool empty = false;
  int saves = 0;
  @override
  Future<List<CatalogOption>> components(String code) async => [
    const CatalogOption(id: 'c', name: 'Bujía'),
  ];
  @override
  Future<MarketplaceSearchResult> search({
    required String code,
    required String componentId,
    MarketplaceProvider provider = MarketplaceProvider.mercadolibre,
    String? model,
    int? year,
    String? vehicleId,
    String? sessionId,
  }) async => pending != null
      ? pending!.future
      : MarketplaceSearchResult(
          items: empty ? [] : [parseOffer(sample)],
          provider: provider,
          environment: MarketplaceEnvironment.sandbox,
        );
  @override
  Future<SavedPart> save({
    required String token,
    required String key,
    required String note,
  }) async {
    saves++;
    return saving != null ? saving!.future : savedEbay();
  }

  @override
  Future<SavedPartsPage> saved({int offset = 0}) async =>
      SavedPartsPage([savedEbay()], null);
}

void main() {
  test('eBay conserva moneda y entorno; Mercado Libre heredado conserva su contrato', () {
    final offer = parseOffer(sample);
    expect(offer.provider, MarketplaceProvider.ebay);
    expect(offer.environment, MarketplaceEnvironment.sandbox);
    expect(offer.price, '5.00');
    expect(offer.currency, 'USD');
    final legacy = parseOffer(
      {
        ...sample,
        'provider': 'mercadolibre',
        'environment': 'production',
        'external_id': 'MLC12345678',
        'url': 'https://articulo.mercadolibre.cl/MLC-12345678',
      }..remove('environment'),
    );
    expect(legacy.provider, MarketplaceProvider.mercadolibre);
    expect(legacy.environment, MarketplaceEnvironment.production);
  });
  test('rechaza origen, entorno, ID o enlace incongruentes', () {
    for (final bad in <Map<String, dynamic>>[
      {...sample}..remove('environment'),
      {...sample, 'environment': 'production'},
      {...sample, 'external_id': 'MLC12345678'},
      {...sample, 'url': 'https://sandbox.ebay.com.attacker.example/itm/123'},
      {...sample, 'url': 'https://user:password@sandbox.ebay.com/itm/123'},
      {...sample, 'kind': 'catalog_product'},
      {...sample, 'provider': 'unknown'},
      {...sample, 'currency': 'DOLARES'},
    ]) {
      expect(() => parseOffer(bad), throwsA(isA<AppFailure>()));
    }
  });
  test(
    'repositorio envía proveedor y valida el origen de la respuesta',
    () async {
      var mismatched = false;
      final dio = Dio()
        ..httpClientAdapter = StubAdapter((options) async {
          expect((options.data as Map)['provider'], 'ebay');
          return jsonResponse({
            'provider': mismatched ? 'mercadolibre' : 'ebay',
            'environment': 'sandbox',
            'items': [sample],
          });
        });
      final client = ApiClient(dio: dio)..setAccessToken('a' * 43);
    final repo = ApiOffersRepository(client);
      final result = await repo.search(
        code: 'P0301',
        componentId: 'c',
        provider: MarketplaceProvider.ebay,
      );
      expect(result.items.single.currency, 'USD');
      expect(result.environment, MarketplaceEnvironment.sandbox);
      mismatched = true;
      await expectLater(
        repo.search(
          code: 'P0301',
          componentId: 'c',
          provider: MarketplaceProvider.ebay,
        ),
        throwsA(isA<AppFailure>()),
      );
      dio.close();
    },
  );
  test('cambiar proveedor descarta una búsqueda tardía', () async {
    final repo = _Repository()..pending = Completer();
    final state = OffersController(repo, code: 'P0301');
    addTearDown(state.dispose);
    state.select('c');
    final request = state.search();
    state.selectProvider(MarketplaceProvider.ebay);
    repo.pending!.complete(const MarketplaceSearchResult(items: []));
    await request;
    expect(state.provider, MarketplaceProvider.ebay);
    expect(state.searched, isFalse);
    expect(state.environment, isNull);
    expect(state.offers, isEmpty);
  });
  test('guardado tardío no muestra mensajes en otro proveedor', () async {
    final repo = _Repository()..saving = Completer();
    final state = OffersController(repo, code: 'P0301');
    addTearDown(state.dispose);
    final request = state.save(parseOffer(sample), 'Revisar');
    state.selectProvider(MarketplaceProvider.ebay);
    repo.saving!.complete(savedEbay());
    await request;
    expect(repo.saves, 1);
    expect(state.message, isNull);
    expect(state.saved, isEmpty);
  });
  testWidgets(
    'seleccionar eBay, buscar y guardar muestra Sandbox y USD en pantalla pequeña',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MarketplaceSearchPanel(repository: repo, code: 'P0301'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('marketplace-provider')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('eBay').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('component-P0301')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bujía').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('search-marketplace')));
      await tester.tap(find.byKey(const Key('search-marketplace')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sandbox-search-notice')), findsOneWidget);
      expect(find.text('USD 5.00'), findsOneWidget);
      expect(find.textContaining('eBay · Sandbox'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Guardar alternativa'));
      await tester.tap(find.text('Guardar alternativa'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('saved-part-note')),
        'Revisar',
      );
      await tester.tap(find.byKey(const Key('confirm-save-alternative')));
      await tester.pumpAndSettle();
      expect(repo.saves, 1);
      expect(find.text('Guardada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('una búsqueda vacía conserva el aviso de Sandbox', (
    tester,
  ) async {
    final repo = _Repository()..empty = true;
    final state = OffersController(repo, code: 'P0301');
    addTearDown(state.dispose);
    state.select('c');
    state.selectProvider(MarketplaceProvider.ebay);
    await state.search();
    expect(state.environment, MarketplaceEnvironment.sandbox);
    expect(state.offers, isEmpty);
    expect(state.searched, isTrue);
  });
  testWidgets('historial identifica las referencias eBay de prueba', (
    tester,
  ) async {
    final state = SavedPartsController(_Repository());
    addTearDown(state.dispose);
    await state.refresh();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: SavedPartsScreen()),
      ),
    );
    expect(find.textContaining('eBay · Sandbox'), findsOneWidget);
    expect(
      find.text('Referencia de prueba. No usar para una cotización comercial.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
