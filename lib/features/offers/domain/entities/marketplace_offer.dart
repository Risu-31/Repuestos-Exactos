import 'package:autoscan/features/offers/domain/entities/marketplace_provider.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_environment.dart';

class MarketplaceOffer {
  const MarketplaceOffer({
    required this.token,
    required this.externalId,
    required this.title,
    required this.price,
    required this.currency,
    required this.url,
    required this.queriedAt,
    required this.kind,
    this.provider = MarketplaceProvider.mercadolibre,
    this.environment = MarketplaceEnvironment.production,
    this.catalogStatus,
  });
  final String token, externalId, title, kind;
  final String? price, currency, url, catalogStatus;
  final MarketplaceProvider provider;
  final MarketplaceEnvironment environment;
  final DateTime queriedAt;
}
