import 'package:autoscan/features/offers/domain/entities/marketplace_offer.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_provider.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_environment.dart';

/// Conserva procedencia y entorno incluso cuando no se encontraron artículos.
class MarketplaceSearchResult {
  const MarketplaceSearchResult({
    required this.items,
    this.provider = MarketplaceProvider.mercadolibre,
    this.environment = MarketplaceEnvironment.production,
  });
  final List<MarketplaceOffer> items;
  final MarketplaceProvider provider;
  final MarketplaceEnvironment environment;
}
