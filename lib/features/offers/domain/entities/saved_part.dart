import 'package:autoscan/features/offers/domain/entities/marketplace_provider.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_environment.dart';

class SavedPart {
  const SavedPart({
    required this.id,
    required this.externalId,
    required this.url,
    required this.code,
    required this.component,
    required this.author,
    required this.note,
    required this.createdAt,
    this.vehicle,
    required this.kind,
    this.provider = MarketplaceProvider.mercadolibre,
    this.environment = MarketplaceEnvironment.production,
  });
  final String id, externalId, code, component, author, note, kind;
  final String? url;
  final MarketplaceProvider provider;
  final MarketplaceEnvironment environment;
  final DateTime createdAt;
  final String? vehicle;
}
