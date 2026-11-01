import 'package:flutter/foundation.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/search/domain/repositories/search_repository.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_vehicle.dart';
import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_sessions_repository.dart';

class VehicleRegistrationController extends ChangeNotifier {
  VehicleRegistrationController(this.catalog, this.repository, {this.vin});
  final String? vin;
  final SearchRepository catalog;
  final DiagnosticSessionsRepository repository;
  List<CatalogOption> brands = [], models = [];
  String? brand, model, error;
  String year = '', plate = '', engine = '';
  bool busy = false, _disposed = false;
  int _generation = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    busy = true;
    _notify();
    try {
      final result = await catalog.brands();
      if (!_disposed) brands = result;
    } catch (e) {
      if (!_disposed) {
        error = e is AppFailure
            ? e.message
            : 'No se pudieron cargar las marcas.';
      }
    } finally {
      if (!_disposed) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> selectBrand(String? id) async {
    brand = id;
    model = null;
    models = [];
    error = null;
    final gen = ++_generation;
    if (id == null) {
      _notify();
      return;
    }
    busy = true;
    _notify();
    try {
      final result = await catalog.models(id);
      if (!_disposed && gen == _generation) models = result;
    } catch (e) {
      if (!_disposed && gen == _generation) {
        error = e is AppFailure
            ? e.message
            : 'No se pudieron cargar los modelos.';
      }
    } finally {
      if (!_disposed && gen == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  void selectModel(String? id) {
    model = id;
    _notify();
  }

  Future<DiagnosticVehicle?> save() async {
    if (busy) return null;
    final value = int.tryParse(year);
    if (model == null ||
        value == null ||
        value < 1981 ||
        value > 2100 ||
        plate.trim().isEmpty ||
        engine.trim().isEmpty) {
      error = 'Completa modelo, año, patente y motor.';
      _notify();
      return null;
    }
    busy = true;
    error = null;
    _notify();
    try {
      return await repository.registerVehicle(
        modelId: model!,
        year: value,
        plate: plate,
        engine: engine,
        vin: vin,
      );
    } catch (e) {
      if (!_disposed) {
        error = e is AppFailure
            ? e.message
            : 'No se pudo registrar el vehículo.';
      }
      return null;
    } finally {
      if (!_disposed) {
        busy = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    super.dispose();
  }
}
