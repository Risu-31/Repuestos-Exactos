import 'package:autoscan/features/diagnostic/domain/entities/dtc_observation.dart';

class ObdScan {
  ObdScan({
    required this.capturedAt,
    required this.protocol,
    this.vin,
    this.vinStatus = 'not_requested',
    required Map<String, String> services,
    required List<DtcObservation> observations,
  }) : services = Map.unmodifiable(services),
       observations = List.unmodifiable(observations);
  final DateTime capturedAt;
  final String protocol;
  final String? vin;
  final String vinStatus;
  final Map<String, String> services;
  final List<DtcObservation> observations;
}
