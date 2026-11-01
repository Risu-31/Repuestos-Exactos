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
    this.catalogStatus,
  });
  final String token, externalId, title, kind;
  final String? price, currency, url, catalogStatus;
  final DateTime queriedAt;
}
