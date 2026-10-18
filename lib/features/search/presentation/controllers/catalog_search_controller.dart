import 'package:flutter/foundation.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/search/domain/entities/dtc_option.dart';
import 'package:autoscan/features/search/domain/entities/part_result.dart';
import 'package:autoscan/features/search/domain/entities/vehicle_match.dart';
import 'package:autoscan/features/search/domain/repositories/search_repository.dart';

class CatalogSearchController extends ChangeNotifier {
  CatalogSearchController(this._repository, {required this.canLookupVehicle});
  final SearchRepository _repository;
  final bool canLookupVehicle;
  List<CatalogOption> brands = const [], models = const [];
  List<DtcOption> codes = const [];
  List<PartResult> parts = const [];
  String? brandId, modelId;
  int? year;
  DtcOption? selectedCode;
  VehicleMatch? vehicleMatch;
  bool loadingBrands = false, loadingModels = false, loadingCodes = false;
  bool loadingVin = false, loadingParts = false, loadingMore = false;
  bool codesHaveMore = false, searched = false;
  String? brandError, modelError, codeError, vinMessage, partsError, pageError;
  String _codeQuery = '';
  int? _nextOffset;
  bool get hasMore => _nextOffset != null;
  bool _disposed = false;
  int _brandGeneration = 0, _modelGeneration = 0, _codeGeneration = 0;
  int _vinGeneration = 0, _partGeneration = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _clearParts() {
    _partGeneration++;
    parts = const [];
    _nextOffset = null;
    searched = false;
    loadingParts = false;
    loadingMore = false;
    partsError = null;
    pageError = null;
  }

  Future<void> initialize() async {
    if (_disposed) return;
    final generation = ++_brandGeneration;
    loadingBrands = true;
    brandError = null;
    _notify();
    try {
      final items = await _repository.brands();
      if (_disposed || generation != _brandGeneration) return;
      brands = List.unmodifiable(items);
    } on AppFailure catch (error) {
      if (!_disposed && generation == _brandGeneration) {
        brandError = error.message;
      }
    } finally {
      if (!_disposed && generation == _brandGeneration) {
        loadingBrands = false;
        _notify();
      }
    }
  }

  Future<void> selectBrand(String? id) async {
    if (_disposed) return;
    _vinGeneration++;
    loadingVin = false;
    vehicleMatch = null;
    vinMessage = null;
    brandId = id;
    modelId = null;
    year = null;
    models = const [];
    modelError = null;
    _clearParts();
    final generation = ++_modelGeneration;
    loadingModels = id != null;
    _notify();
    if (id == null) return;
    try {
      final values = await _repository.models(id);
      if (_disposed || generation != _modelGeneration) return;
      models = List.unmodifiable(values);
    } on AppFailure catch (error) {
      if (!_disposed && generation == _modelGeneration) {
        modelError = error.message;
      }
    } finally {
      if (!_disposed && generation == _modelGeneration) {
        loadingModels = false;
        _notify();
      }
    }
  }

  void selectModel(String? id) {
    if (_disposed) return;
    _vinGeneration++;
    loadingVin = false;
    modelId = id;
    year = null;
    vehicleMatch = null;
    vinMessage = null;
    _clearParts();
    _notify();
  }

  void selectYear(String value) {
    if (_disposed) return;
    year = int.tryParse(value);
    _clearParts();
    _notify();
  }

  void changeCodeQuery(String value) {
    if (_disposed) return;
    _codeQuery = value.trim().toUpperCase();
    _codeGeneration++;
    loadingCodes = false;
    codes = const [];
    selectedCode = null;
    codesHaveMore = false;
    codeError = null;
    _clearParts();
    _notify();
  }

  Future<void> searchCodes() async {
    if (_disposed) return;
    if (!RegExp(r'^(?:[PCBU](?:[0-3][0-9A-F]{0,3})?)?$').hasMatch(_codeQuery)) {
      codeError = 'Ingresa un código como P0300 o un prefijo como P03.';
      _notify();
      return;
    }
    final generation = ++_codeGeneration;
    loadingCodes = true;
    codeError = null;
    codes = const [];
    selectedCode = null;
    _clearParts();
    _notify();
    try {
      final page = await _repository.codes(_codeQuery);
      if (_disposed || generation != _codeGeneration) return;
      codes = page.items;
      codesHaveMore = page.hasMore;
      if (codes.length == 1) selectedCode = codes.single;
      if (codes.isEmpty) {
        codeError = 'No hay códigos que coincidan. Prueba otro prefijo.';
      }
    } on AppFailure catch (error) {
      if (!_disposed && generation == _codeGeneration) {
        codeError = error.message;
      }
    } finally {
      if (!_disposed && generation == _codeGeneration) {
        loadingCodes = false;
        _notify();
      }
    }
  }

  void selectCode(String? code) {
    if (_disposed) return;
    selectedCode = code == null
        ? null
        : codes.where((item) => item.code == code).firstOrNull;
    _clearParts();
    _notify();
  }

  void changeVin() {
    if (_disposed) return;
    _vinGeneration++;
    loadingVin = false;
    vinMessage = null;
    if (vehicleMatch != null) {
      vehicleMatch = null;
      brandId = null;
      modelId = null;
      year = null;
      models = const [];
      _clearParts();
    }
    _notify();
  }

  Future<void> lookupVin(String input) async {
    if (_disposed) return;
    final vin = input.trim().toUpperCase();
    if (!canLookupVehicle) {
      vinMessage = 'Tu rol puede usar el catálogo por modelo.';
      _notify();
      return;
    }
    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin)) {
      vinMessage = 'Ingresa un VIN de 17 caracteres, sin I, O ni Q.';
      _notify();
      return;
    }
    final generation = ++_vinGeneration;
    final modelGeneration = ++_modelGeneration;
    loadingVin = true;
    loadingModels = false;
    vinMessage = null;
    vehicleMatch = null;
    brandId = null;
    modelId = null;
    year = null;
    models = const [];
    _clearParts();
    _notify();
    try {
      final match = await _repository.vehicle(vin);
      if (_disposed || generation != _vinGeneration) return;
      if (match == null) {
        vinMessage = 'No encontramos un vehículo visible con ese VIN en tu taller. Puedes elegir el modelo manualmente.';
        return;
      }
      final options = await _repository.models(match.brandId);
      if (_disposed ||
          generation != _vinGeneration ||
          modelGeneration != _modelGeneration) {
        return;
      }
      if (!brands.any((item) => item.id == match.brandId) ||
          !options.any((item) => item.id == match.modelId)) {
        throw const AppFailure(
          'No pudimos completar los datos del vehículo. Actualiza el catálogo.',
        );
      }
      models = List.unmodifiable(options);
      brandId = match.brandId;
      modelId = match.modelId;
      year = match.year;
      vehicleMatch = match;
      vinMessage =
          'Vehículo encontrado: ${match.brandName} ${match.modelName} · ${match.plate}';
    } on AppFailure catch (error) {
      if (!_disposed && generation == _vinGeneration) {
        vinMessage = error.message;
      }
    } finally {
      if (!_disposed && generation == _vinGeneration) {
        loadingVin = false;
        _notify();
      }
    }
  }

  Future<void> searchParts() async {
    if (_disposed) return;
    if (selectedCode == null) {
      partsError = 'Busca y selecciona un código de falla DTC.';
      _notify();
      return;
    }
    if (brandId != null && modelId == null) {
      partsError = 'Selecciona un modelo o limpia el filtro de vehículo.';
      _notify();
      return;
    }
    if (modelId != null && (year == null || year! < 1981 || year! > 2100)) {
      partsError =
          'Ingresa un año entre 1981 y 2100 para filtrar compatibilidad.';
      _notify();
      return;
    }
    final generation = ++_partGeneration;
    parts = const [];
    _nextOffset = null;
    searched = false;
    partsError = null;
    pageError = null;
    loadingParts = true;
    loadingMore = false;
    _notify();
    try {
      final page = await _repository.parts(
        selectedCode!.code,
        model: modelId,
        year: year,
      );
      if (_disposed || generation != _partGeneration) return;
      parts = page.items;
      _nextOffset = page.nextOffset;
      searched = true;
    } on AppFailure catch (error) {
      if (!_disposed && generation == _partGeneration) {
        partsError = error.message;
      }
    } finally {
      if (!_disposed && generation == _partGeneration) {
        loadingParts = false;
        _notify();
      }
    }
  }

  Future<void> loadMore() async {
    final offset = _nextOffset;
    if (_disposed ||
        loadingParts ||
        loadingMore ||
        offset == null ||
        selectedCode == null) {
      return;
    }
    final generation = _partGeneration;
    loadingMore = true;
    pageError = null;
    _notify();
    try {
      final page = await _repository.parts(
        selectedCode!.code,
        model: modelId,
        year: year,
        offset: offset,
      );
      if (_disposed || generation != _partGeneration) return;
      if (page.nextOffset != null && page.nextOffset! <= offset) {
        throw const AppFailure('No pudimos avanzar. Repite la búsqueda.');
      }
      final ids = parts.map((item) => item.id).toSet();
      parts = List.unmodifiable([
        ...parts,
        ...page.items.where((item) => ids.add(item.id)),
      ]);
      _nextOffset = page.nextOffset;
    } on AppFailure catch (error) {
      if (!_disposed && generation == _partGeneration) {
        pageError = error.message;
      }
    } finally {
      if (!_disposed && generation == _partGeneration) {
        loadingMore = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
