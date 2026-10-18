class VehicleMatch {
  const VehicleMatch({
    required this.id,
    required this.vin,
    required this.plate,
    required this.year,
    required this.modelId,
    required this.modelName,
    required this.brandId,
    required this.brandName,
  });
  final String id;
  final String vin;
  final String plate;
  final int year;
  final String modelId;
  final String modelName;
  final String brandId;
  final String brandName;
}
