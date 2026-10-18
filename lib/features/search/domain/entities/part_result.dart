class PartResult {
  const PartResult({
    required this.id,
    required this.componentId,
    required this.componentName,
    required this.profile,
    required this.brand,
    required this.name,
    required this.manufacturerCode,
    required this.durability,
    required this.risk,
    required this.salePrice,
    required this.currency,
  });
  final String id;
  final String componentId;
  final String componentName;
  final String profile;
  final String brand;
  final String name;
  final String manufacturerCode;
  final int durability;
  final String risk;
  final BigInt salePrice;
  final String currency;
}
