import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:autoscan/core/utils/new_uuid.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_device.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_vehicle.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_detail.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_scan.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_exception.dart';
import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_scanner.dart';
import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_sessions_repository.dart';

class DiagnosticController extends ChangeNotifier {
  DiagnosticController(this.scanner, this.repository) {
    _connectionSubscription = scanner.connectionErrors.listen((message) {
      if (_disposed) return;
      connected = false;
      if (scan == null) error = message;
      _notify();
    });
  }
  late final StreamSubscription<String> _connectionSubscription;
  final DiagnosticScanner scanner;
  final DiagnosticSessionsRepository repository;
  List<DiagnosticVehicle> vehicles = [];
  List<DiagnosticDevice> devices = [];
  DiagnosticVehicle? vehicle;
  DiagnosticDevice? device;
  String mileage = '';
  String? error;
  String? vinNotice;
  bool _saveAttempted = false;
  String progress =
      'Selecciona el adaptador. El VIN se intentará leer junto con las fallas.';
  bool loading = false, busy = false, connected = false, saving = false;
  ObdScan? scan;
  DiagnosticDetail? saved;
  int _generation = 0;
  bool _disposed = false;
  String? _saveKey;
  final _deviceKey = newUuid();
  bool get supported => scanner.supported;
  bool get locked => busy || saving || connected || scan != null;
  bool get vehicleLocked =>
      busy || saving || connected || saved != null || _saveAttempted;
  bool _current(int generation) => !_disposed && generation == _generation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _message(Object e) => e is ObdException
      ? e.message
      : e is AppFailure
      ? e.message
      : 'No pudimos completar la operación. Intenta nuevamente.';
  Future<void> load() async {
    if (loading) return;
    loading = true;
    error = null;
    final gen = _generation;
    _notify();
    try {
      final values = await Future.wait([
        repository.vehicles(),
        repository.devices(),
      ]);
      if (!_current(gen)) return;
      vehicles = (values[0] as List<DiagnosticVehicle>);
      devices = (values[1] as List<DiagnosticDevice>);
      device = devices.length == 1 ? devices.single : null;
    } catch (e) {
      if (_current(gen)) error = _message(e);
    } finally {
      if (_current(gen)) {
        loading = false;
        _notify();
      }
    }
  }

  void addVehicle(DiagnosticVehicle value) {
    if (vehicleLocked) return;
    vehicles = [...vehicles.where((v) => v.id != value.id), value];
    vehicle = value;
    error = null;
    _notify();
  }

  void selectVehicle(String? id) {
    if (vehicleLocked) return;
    final selected = vehicles.where((v) => v.id == id).firstOrNull;
    if (scan?.vin != null &&
        selected?.vin != null &&
        scan!.vin != selected!.vin) {
      error = 'El VIN leído no corresponde al vehículo seleccionado.';
      _notify();
      return;
    }
    vehicle = selected;
    error = null;
    _notify();
  }

  void selectDevice(String? id) {
    if (locked) return;
    device = devices.where((v) => v.id == id).firstOrNull;
    error = null;
    _notify();
  }

  Future<void> registerDevice() async {
    if (locked || loading) return;
    loading = true;
    error = null;
    final gen = _generation;
    _notify();
    try {
      final added = await repository.registerDevice(_deviceKey);
      if (!_current(gen)) return;
      devices = [...devices.where((d) => d.id != added.id), added];
      device = added;
    } catch (e) {
      if (_current(gen)) error = _message(e);
    } finally {
      if (_current(gen)) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> connect() async {
    if (locked || loading) return;
    if (device == null) {
      error = 'Selecciona un adaptador registrado en el taller.';
      _notify();
      return;
    }
    busy = true;
    error = null;
    progress = 'Selecciona el vLinker MC en el navegador…';
    final gen = ++_generation;
    _notify();
    try {
      await scanner.connect();
      if (!_current(gen)) return;
      connected = true;
      progress = 'Adaptador listo. Puedes leer las fallas del vehículo.';
    } catch (e) {
      if (_current(gen)) {
        connected = false;
        error = _message(e);
      }
    } finally {
      if (_current(gen)) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> read() async {
    if (!connected || busy || saving || scan != null) return;
    final gen = ++_generation;
    busy = true;
    error = null;
    _notify();
    try {
      final result = await scanner.scan(
        onProgress: (text) {
          if (_current(gen)) {
            progress = text;
            _notify();
          }
        },
      );
      await scanner.disconnect();
      if (!_current(gen)) return;
      connected = false;
      scan = result;
      error = null;
      _saveKey = newUuid();
      if (result.vin != null) {
        if (vehicle?.vin != null && vehicle!.vin != result.vin) vehicle = null;
        try {
          final matches = await repository.vehicles(vin: result.vin);
          if (!_current(gen)) return;
          if (matches.length == 1 && matches.single.vin == result.vin) {
            final matched = matches.single;
            vehicles = [...vehicles.where((v) => v.id != matched.id), matched];
            vehicle = matched;
            vinNotice = 'Vehículo identificado por VIN en tu taller.';
          } else {
            vinNotice = 'VIN nuevo en tu taller. Selecciona o registra el vehículo y confirma sus datos antes de guardar.';
          }
        } catch (_) {
          if (!_current(gen)) return;
          vinNotice = 'No se pudo buscar el VIN en tu taller. Las fallas están conservadas; puedes seleccionar el vehículo manualmente.';
        }
      }
      progress = 'Lectura terminada. Guarda el diagnóstico para verlo en el historial.';
    } catch (e) {
      if (_current(gen)) {
        connected = false;
        error = _message(e);
      }
    } finally {
      if (_current(gen)) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> save() async {
    if (scan == null || saving || busy || saved != null) return;
    final km = int.tryParse(mileage);
    if (vehicle == null ||
        device == null ||
        km == null ||
        km < 0 ||
        km > 2147483647) {
      error = 'Selecciona o registra el vehículo e ingresa un kilometraje válido. La lectura se conserva.';
      _notify();
      return;
    }
    _saveAttempted = true;
    saving = true;
    error = null;
    final gen = _generation;
    _notify();
    try {
      final detail = await repository.save(
        scan!,
        vehicleId: vehicle!.id,
        deviceId: device!.id,
        mileage: int.parse(mileage),
        key: _saveKey!,
      );
      if (_current(gen)) {
        saved = detail;
        progress = 'Diagnóstico guardado en el historial del taller.';
      }
    } catch (e) {
      if (_current(gen)) {
        error = _message(e);
        if (e is AppFailure && {400, 404, 409}.contains(e.statusCode)) {
          _saveAttempted = false;
          _saveKey = newUuid();
        }
      }
    } finally {
      if (_current(gen)) {
        saving = false;
        _notify();
      }
    }
  }

  Future<void> reset() async {
    if (saving) return;
    final gen = ++_generation;
    busy = true;
    _notify();
    await scanner.disconnect();
    if (!_current(gen)) return;
    connected = false;
    scan = null;
    saved = null;
    _saveKey = null;
    _saveAttempted = false;
    vinNotice = null;
    busy = false;
    loading = false;
    error = null;
    progress = 'Selecciona el vehículo y el adaptador del taller.';
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    unawaited(_connectionSubscription.cancel());
    unawaited(scanner.dispose());
    super.dispose();
  }
}
