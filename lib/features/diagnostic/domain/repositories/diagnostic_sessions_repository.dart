import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_device.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_vehicle.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_detail.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_scan.dart';

abstract interface class DiagnosticSessionsRepository {
  Future<List<DiagnosticVehicle>> vehicles({String? vin});
  Future<DiagnosticVehicle> registerVehicle({
    required String modelId,
    required int year,
    required String plate,
    required String engine,
    String? vin,
  });
  Future<List<DiagnosticDevice>> devices();
  Future<DiagnosticDevice> registerDevice(String key);
  Future<DiagnosticDetail> save(
    ObdScan scan, {
    required String vehicleId,
    required String deviceId,
    required int mileage,
    required String key,
  });
  Future<DiagnosticDetail> detail(String id);
}
