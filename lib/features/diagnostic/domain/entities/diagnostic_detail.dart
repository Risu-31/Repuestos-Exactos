import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_fault.dart';

class DiagnosticDetail {
  const DiagnosticDetail({
    required this.id,
    this.vin,
    required this.vehicleId,
    required this.modelId,
    required this.year,
    required this.label,
    required this.observations,
    required this.services,
  });
  final String id;
  final String? vin;
  final String? vehicleId;
  final String? modelId;
  final int? year;
  final String label;
  final List<DiagnosticFault> observations;
  final Map<String, String> services;
}
