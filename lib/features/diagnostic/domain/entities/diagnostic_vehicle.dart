class DiagnosticVehicle {
  const DiagnosticVehicle({
    required this.id,
    this.vin,
    required this.modelId,
    required this.year,
    required this.label,
  });
  final String id;
  final String? vin;
  final String modelId;
  final int year;
  final String label;
}
