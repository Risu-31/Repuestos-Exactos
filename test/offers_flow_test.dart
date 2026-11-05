import 'dart:async';

import 'package:autoscan/features/offers/domain/entities/marketplace_provider.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_search_result.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/offers/data/models/offer_dto.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_offer.dart';
import 'package:autoscan/features/offers/domain/entities/saved_part.dart';
import 'package:autoscan/features/offers/domain/entities/saved_parts_page.dart';
import 'package:autoscan/features/offers/domain/repositories/offers_repository.dart';
import 'package:autoscan/features/offers/presentation/controllers/offers_controller.dart';
import 'package:autoscan/features/offers/presentation/widgets/marketplace_offer_card.dart';
import 'package:autoscan/features/search/domain/entities/catalog_option.dart';

class _Repository implements OffersRepository {
  Completer<List<MarketplaceOffer>>? pending;
  final keys = <String>[];
  bool fail = false;
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
  }) async =>
      MarketplaceSearchResult(items: await pending!.future, provider: provider);
  @override
  Future<SavedPart> save({
    required String token,
    required String key,
    required String note,
  }) async {
    keys.add(key);
    if (fail) throw const AppFailure('Conexión interrumpida.');
    return SavedPart(
      id: 'saved',
      externalId: 'MLC12345678',
      url: null,
      kind: 'catalog_product',
      code: 'P0301',
      component: 'Bujía',
      author: 'Técnico',
      note: note,
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<SavedPartsPage> saved({int offset = 0}) async =>
      const SavedPartsPage([], null);
}

MarketplaceOffer offer() => MarketplaceOffer(
  token: 't',
  externalId: 'MLC12345678',
  title: 'Bujía NGK',
  price: null,
  currency: null,
  url: null,
  kind: 'catalog_product',
  catalogStatus: 'inactive',
  queriedAt: DateTime.utc(2026),
);
void main() {
  test('cambiar componente descarta la respuesta tardía', () async {
    final repo = _Repository()..pending = Completer();
    final state = OffersController(repo, code: 'P0301');
    addTearDown(state.dispose);
    state.select('c');
    final pending = state.search();
    state.select('otra');
    repo.pending!.complete([offer()]);
    await pending;
    expect(state.offers, isEmpty);
    expect(state.searched, isFalse);
  });
  test(
    'reintentar guardar mantiene idempotencia y bloquea doble guardado',
    () async {
      final repo = _Repository()..fail = true;
      final state = OffersController(repo, code: 'P0301');
      addTearDown(state.dispose);
      await state.save(offer(), 'Revisar antes de cotizar');
      expect(state.error, isNotNull);
      repo.fail = false;
      await state.save(offer(), 'Revisar antes de cotizar');
      expect(repo.keys[0], repo.keys[1]);
      await state.save(offer(), 'Revisar antes de cotizar');
      expect(repo.keys.length, 2);
      expect(state.saved, contains('t'));
    },
  );
  test('el contrato rechaza un precio atribuido a catálogo técnico', () {
    expect(
      () => parseOffer({
        'provider': 'mercadolibre',
        'kind': 'catalog_product',
        'compatibility': 'unverified',
        'price': '0',
      }),
      throwsA(isA<AppFailure>()),
    );
  });
  testWidgets(
    'referencia inactiva no muestra precio, stock ni enlace de compra',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarketplaceOfferCard(
              offer: offer(),
              saving: false,
              saved: false,
              onSave: () {},
            ),
          ),
        ),
      );
      expect(find.text('Sin precio disponible'), findsOneWidget);
      expect(find.textContaining('catálogo inactiva'), findsOneWidget);
      expect(find.text('Ver publicación'), findsNothing);
      expect(find.text('Guardar alternativa'), findsOneWidget);
    },
  );
}
