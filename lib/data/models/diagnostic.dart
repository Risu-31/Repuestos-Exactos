class DiagnosticReport {
  final String code;
  final String description;
  final String system;
  final List<PartOption> partOptions;

  DiagnosticReport({
    required this.code,
    required this.description,
    required this.system,
    required this.partOptions,
  });
}

enum PartRisk { bajo, medio, alto }
enum PartType { genuino, oem, alternativo }

class PartOption {
  final PartType type;
  final String brand;
  final double price;
  final String estimatedLife;
  final PartRisk risk;

  PartOption({
    required this.type,
    required this.brand,
    required this.price,
    required this.estimatedLife,
    required this.risk,
  });
}
