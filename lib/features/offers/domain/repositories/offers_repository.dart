import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_offer.dart';
import 'package:autoscan/features/offers/domain/entities/saved_part.dart';
import 'package:autoscan/features/offers/domain/entities/saved_parts_page.dart';

abstract interface class OffersRepository {
  Future<List<CatalogOption>> components(String code);
  Future<List<MarketplaceOffer>> search({
    required String code,
    required String componentId,
    String? model,
    int? year,
    String? vehicleId,
  });
  Future<SavedPart> save({
    required String token,
    required String key,
    required String note,
  });
  Future<SavedPartsPage> saved({int offset = 0});
}
