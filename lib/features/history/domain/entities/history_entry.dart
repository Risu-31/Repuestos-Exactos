import 'package:autoscan/features/history/domain/entities/history_status.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.method,
    required this.userName,
    required this.faultCount,
    this.vehicleId,
    this.plate,
    this.year,
    this.model,
    this.brand,
    this.maxSeverity,
  });
  final String id;
  final HistoryStatus status;
  final DateTime startedAt;
  final String method;
  final String userName;
  final int faultCount;
  final String? vehicleId;
  final String? plate;
  final int? year;
  final String? model;
  final String? brand;
  final String? maxSeverity;
}
