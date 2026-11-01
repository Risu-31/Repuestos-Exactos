import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_fault.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_device.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_vehicle.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_detail.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_scan.dart';
import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_sessions_repository.dart';

class DiagnosticRepositoryFake implements DiagnosticSessionsRepository {
  bool failSave = false;
  int? rejectSaveStatus;
  List<DiagnosticVehicle> registeredVehicles = [vehicle];
  final keys = <String>[];
  static const vehicle = DiagnosticVehicle(
    id: 'v',
    modelId: 'm',
    year: 2018,
    label: 'Toyota Yaris · 2018',
  );
  static const device = DiagnosticDevice(id: 'd', name: 'vLinker MC');
  @override
  Future<DiagnosticVehicle> registerVehicle({
    required String modelId,
    required int year,
    required String plate,
    required String engine,
    String? vin,
  }) async => vehicle;
  @override
  Future<List<DiagnosticVehicle>> vehicles({String? vin}) async =>
      registeredVehicles.where((v) => vin == null || v.vin == vin).toList();
  @override
  Future<List<DiagnosticDevice>> devices() async => [device];
  @override
  Future<DiagnosticDevice> registerDevice(String key) async => device;
  @override
  Future<DiagnosticDetail> save(
    ObdScan scan, {
    required String vehicleId,
    required String deviceId,
    required int mileage,
    required String key,
  }) async {
    keys.add(key);
    if (rejectSaveStatus != null) {
      final status = rejectSaveStatus!;
      rejectSaveStatus = null;
      throw AppFailure('Conflicto de vehículo', statusCode: status);
    }
    if (failSave) {
      failSave = false;
      throw const AppFailure('No hay conexión. Reintenta.', statusCode: 503);
    }
    return DiagnosticDetail(
      id: 'saved',
      vehicleId: vehicleId,
      vin: scan.vin,
      modelId: 'm',
      year: 2018,
      label: vehicle.label,
      observations: scan.observations
          .map(
            (o) => DiagnosticFault(
              code: o.code,
              ecu: o.ecu,
              kind: o.kind,
              description: o.code == 'P3999' ? null : 'Falla de encendido',
            ),
          )
          .toList(),
      services: scan.services,
    );
  }

  @override
  Future<DiagnosticDetail> detail(String id) async => const DiagnosticDetail(
    id: 'saved',
    vehicleId: 'v',
    modelId: 'm',
    year: 2018,
    label: 'Toyota Yaris',
    observations: [],
    services: {},
  );
}
