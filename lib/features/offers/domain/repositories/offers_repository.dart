import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_provider.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_search_result.dart';
import 'package:autoscan/features/offers/domain/entities/saved_part.dart';
import 'package:autoscan/features/offers/domain/entities/saved_parts_page.dart';

abstract interface class OffersRepository {
  Future<List<CatalogOption>> components(String code);
  Future<MarketplaceSearchResult> search({
    required String code,
    required String componentId,
    MarketplaceProvider provider = MarketplaceProvider.mercadolibre,
    String? model,
    int? year,
    String? vehicleId,
    String? sessionId,
  });
  Future<SavedPart> save({
    required String token,
    required String key,
    required String note,
  });
  Future<SavedPartsPage> saved({int offset = 0});
}
