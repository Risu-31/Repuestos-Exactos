import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_fault.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_device.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_vehicle.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_detail.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_scan.dart';
import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_sessions_repository.dart';

class ApiDiagnosticSessionsRepository implements DiagnosticSessionsRepository {
  ApiDiagnosticSessionsRepository(this.client);
  final ApiClient client;
  Map<String, dynamic> _object(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const AppFailure('Respuesta de diagnóstico inválida.');
    }
    return value;
  }

  String _string(Map<String, dynamic> row, String field) {
    final v = row[field];
    if (v is! String || v.isEmpty) {
      throw const AppFailure('Respuesta de diagnóstico inválida.');
    }
    return v;
  }

  List<Map<String, dynamic>> _items(Object? value) {
    final list = _object(value)['items'];
    if (list is! List) {
      throw const AppFailure('Respuesta de diagnóstico inválida.');
    }
    return list.map(_object).toList();
  }

  @override
  Future<List<DiagnosticVehicle>> vehicles({String? vin}) async =>
      _items(
        await client.get('/vehicles', queryParameters: {'vin': ?vin}),
      ).map((r) {
        final year = r['anio'];
        if (year is! int) throw const AppFailure('Vehículo inválido.');
        return DiagnosticVehicle(
          id: _string(r, 'id'),
          vin: r['vin'] as String?,
          modelId: _string(r, 'model_id'),
          year: year,
          label:
              '${_string(r, 'brand')} ${_string(r, 'model')} · $year${r['plate'] == null ? '' : ' · ${r['plate']}'}',
        );
      }).toList();
  @override
  Future<DiagnosticVehicle> registerVehicle({
    required String modelId,
    required int year,
    required String plate,
    required String engine,
    String? vin,
  }) async {
    final r = _object(
      await client.post(
        '/vehicles',
        data: {
          'model_id': modelId,
          'year': year,
          'plate': plate,
          'engine': engine,
          'vin': ?vin,
        },
      ),
    );
    final foundYear = r['anio'];
    if (foundYear is! int) throw const AppFailure('Vehículo inválido.');
    return DiagnosticVehicle(
      id: _string(r, 'id'),
      vin: r['vin'] as String?,
      modelId: _string(r, 'model_id'),
      year: foundYear,
      label:
          '${_string(r, 'brand')} ${_string(r, 'model')} · $foundYear · ${r['plate']}',
    );
  }

  @override
  Future<List<DiagnosticDevice>> devices() async =>
      _items(await client.get('/diagnostic-devices'))
          .map(
            (r) => DiagnosticDevice(
              id: _string(r, 'id'),
              name: _string(r, 'name'),
            ),
          )
          .toList();
  @override
  Future<DiagnosticDevice> registerDevice(String key) async {
    final r = _object(
      await client.post(
        '/diagnostic-devices',
        data: {'name': 'vLinker MC', 'idempotency_key': key},
      ),
    );
    return DiagnosticDevice(id: _string(r, 'id'), name: _string(r, 'name'));
  }

  @override
  Future<DiagnosticDetail> save(
    ObdScan scan, {
    required String vehicleId,
    required String deviceId,
    required int mileage,
    required String key,
  }) async => _detail(
    await client.post(
      '/sessions',
      data: {
        'vehicle_id': vehicleId,
        'device_id': deviceId,
        'kilometraje': mileage,
        'idempotency_key': key,
        'captured_at': scan.capturedAt.toUtc().toIso8601String(),
        'protocol': scan.protocol,
        if (scan.vin != null) 'vin': scan.vin,
        'services': scan.services,
        'observations': scan.observations.map((o) => o.toJson()).toList(),
      },
    ),
  );
  @override
  Future<DiagnosticDetail> detail(String id) async =>
      _detail(await client.get('/sessions/$id'));
  DiagnosticDetail _detail(Object? value) {
    final r = _object(value);
    final raw = r['observations'];
    if (raw is! List || raw.length > 512) {
      throw const AppFailure('Detalle de diagnóstico inválido.');
    }
    final observations = raw.map((v) {
      final row = _object(v);
      final code = _string(row, 'code');
      if (!RegExp(r'^[PCBU][0-3][0-9A-F]{3}$').hasMatch(code)) {
        throw const AppFailure('Código de diagnóstico inválido.');
      }
      for (final key in ['ecu', 'kind', 'description']) {
        if (row[key] != null && row[key] is! String) {
          throw const AppFailure('Detalle de diagnóstico inválido.');
        }
      }
      return DiagnosticFault(
        code: code,
        ecu: row['ecu'] as String?,
        kind: row['kind'] as String?,
        description: row['description'] as String?,
      );
    }).toList();
    final services = <String, String>{};
    final rawServices = r['services'];
    if (rawServices != null) {
      for (final e in _object(rawServices).entries) {
        if (e.value is! String) {
          throw const AppFailure('Estado de lectura inválido.');
        }
        services[e.key] = e.value as String;
      }
    }
    if (r['year'] != null && r['year'] is! int) {
      throw const AppFailure('Año inválido.');
    }
    return DiagnosticDetail(
      id: _string(r, 'id'),
      vehicleId: r['vehicle_id'] as String?,
      vin: r['vin'] as String?,
      modelId: r['model_id'] as String?,
      year: r['year'] as int?,
      label:
          '${r['brand'] ?? ''} ${r['model'] ?? 'Vehículo no disponible'} ${r['year'] ?? ''}'
              .trim(),
      observations: List.unmodifiable(observations),
      services: Map.unmodifiable(services),
    );
  }
}
