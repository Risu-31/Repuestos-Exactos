import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/offers/domain/entities/marketplace_offer.dart';
import 'package:autoscan/features/offers/domain/repositories/offers_repository.dart';

class OffersController extends ChangeNotifier {
  OffersController(
    this.repository, {
    required this.code,
    this.model,
    this.year,
    this.vehicleId,
    this.sessionId,
  });
  final OffersRepository repository;
  final String code;
  final String? model, vehicleId, sessionId;
  final int? year;
  List<CatalogOption> components = const [];
  List<MarketplaceOffer> offers = const [];
  String? selectedComponent, error, message;
  bool loadingComponents = false, loading = false, searched = false;
  final saving = <String>{}, saved = <String>{};
  final _saveKeys = <String, String>{};
  bool _disposed = false;
  int _generation = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    loadingComponents = true;
    error = null;
    _notify();
    try {
      final items = await repository.components(code);
      if (!_disposed) components = List.unmodifiable(items);
    } on AppFailure catch (e) {
      if (!_disposed) error = e.message;
    } finally {
      if (!_disposed) {
        loadingComponents = false;
        _notify();
      }
    }
  }

  void select(String? id) {
    selectedComponent = id;
    _generation++;
    loading = false;
    offers = const [];
    searched = false;
    error = null;
    message = null;
    _notify();
  }

  Future<void> search() async {
    final component = selectedComponent;
    if (component == null || loading || _disposed) return;
    if (model != null && (year == null || year! < 1981 || year! > 2100)) {
      error = 'Completa el año del vehículo antes de buscar.';
      _notify();
      return;
    }
    final generation = ++_generation;
    loading = true;
    error = null;
    message = null;
    offers = const [];
    searched = false;
    _notify();
    try {
      final result = await repository.search(
        code: code,
        componentId: component,
        model: model,
        year: year,
        vehicleId: vehicleId,
        sessionId: sessionId,
      );
      if (!_disposed && generation == _generation) {
        offers = List.unmodifiable(result);
        searched = true;
      }
    } on AppFailure catch (e) {
      if (!_disposed && generation == _generation) error = e.message;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  String _uuid() {
    final b = List.generate(16, (_) => Random.secure().nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> save(MarketplaceOffer offer, String note) async {
    if (_disposed ||
        saving.contains(offer.token) ||
        saved.contains(offer.token)) {
      return;
    }
    saving.add(offer.token);
    message = null;
    error = null;
    _notify();
    final fingerprint = jsonEncode([offer.token, note.trim()]);
    final key = _saveKeys.putIfAbsent(fingerprint, _uuid);
    try {
      await repository.save(token: offer.token, key: key, note: note.trim());
      if (!_disposed) {
        saved.add(offer.token);
        message = 'Alternativa guardada en el historial del taller.';
      }
    } on AppFailure catch (e) {
      if (!_disposed) error = e.message;
    } finally {
      if (!_disposed) {
        saving.remove(offer.token);
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
