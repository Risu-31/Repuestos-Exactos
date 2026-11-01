import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/offers/data/models/offer_dto.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_offer.dart';
import 'package:autoscan/features/offers/domain/entities/saved_part.dart';
import 'package:autoscan/features/offers/domain/entities/saved_parts_page.dart';
import 'package:autoscan/features/offers/domain/repositories/offers_repository.dart';

class ApiOffersRepository implements OffersRepository {
  ApiOffersRepository(this.client);
  final ApiClient client;
  List<dynamic> _items(Object? data) {
    final items = offerObject(data)['items'];
    if (items is! List) {
      throw const AppFailure('El listado recibido no es válido.');
    }
    return items;
  }

  @override
  Future<List<CatalogOption>> components(String code) async =>
      _items(await client.get('/catalog/dtc/$code/components')).map((raw) {
        final v = offerObject(raw);
        return CatalogOption(
          id: offerString(v, 'id'),
          name: offerString(v, 'name'),
        );
      }).toList();
  @override
  Future<List<MarketplaceOffer>> search({
    required String code,
    required String componentId,
    String? model,
    int? year,
    String? vehicleId,
    String? sessionId,
  }) async {
    final data = await client.post(
      '/offers/search',
      data: {
        'dtc': code,
        'component_id': componentId,
        'model': ?model,
        'year': ?year,
        'vehicle_id': ?vehicleId,
        'session_id': ?sessionId,
      },
    );
    return _items(data).map(parseOffer).toList();
  }

  @override
  Future<SavedPart> save({
    required String token,
    required String key,
    required String note,
  }) async => parseSavedPart(
    await client.post(
      '/saved-parts',
      data: {'offer_token': token, 'idempotency_key': key, 'note': note},
    ),
  );
  @override
  Future<SavedPartsPage> saved({int offset = 0}) async {
    final data = offerObject(
      await client.get('/saved-parts', queryParameters: {'offset': offset}),
    );
    final next = data['next_offset'];
    if (next != null && (next is! int || next <= offset)) {
      throw const AppFailure('La página recibida no es válida.');
    }
    return SavedPartsPage(
      _items(data).map(parseSavedPart).toList(),
      next as int?,
    );
  }
}
