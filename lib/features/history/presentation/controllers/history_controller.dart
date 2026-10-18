import 'package:flutter/foundation.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/history/domain/entities/history_entry.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';
import 'package:autoscan/features/history/domain/repositories/history_repository.dart';

class HistoryController extends ChangeNotifier {
  HistoryController(this._repository);
  final HistoryRepository _repository;
  List<HistoryEntry> _items = const [];
  List<HistoryEntry> get items => _items;
  HistoryStatus? _status;
  HistoryStatus? get status => _status;
  String? _nextCursor;
  bool get hasMore => _nextCursor != null;
  bool loading = false;
  bool loadingMore = false;
  String? errorMessage;
  String? pageError;
  bool _disposed = false;
  int _generation = 0;

  Future<void> filter(HistoryStatus? value) async {
    if (_disposed || _status == value) return;
    _status = value;
    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_generation;
    loading = true;
    loadingMore = false;
    errorMessage = null;
    pageError = null;
    // No mostrar resultados de un filtro anterior como si fueran del nuevo.
    _items = const [];
    _nextCursor = null;
    notifyListeners();
    try {
      final page = await _repository.load(status: _status);
      if (_disposed || generation != _generation) return;
      _items = List.unmodifiable(page.items);
      _nextCursor = page.nextCursor;
    } on AppFailure catch (error) {
      if (!_disposed && generation == _generation) errorMessage = error.message;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (_disposed || loading || loadingMore || cursor == null) return;
    final generation = _generation;
    loadingMore = true;
    pageError = null;
    notifyListeners();
    try {
      final page = await _repository.load(status: _status, cursor: cursor);
      if (_disposed || generation != _generation) return;
      if (page.nextCursor == cursor) {
        throw const AppFailure(
          'No pudimos avanzar en el historial. Actualiza la lista.',
        );
      }
      // Evita duplicados si una sesión cambia mientras se recorren las páginas.
      final ids = _items.map((item) => item.id).toSet();
      _items = List.unmodifiable([
        ..._items,
        ...page.items.where((item) => ids.add(item.id)),
      ]);
      _nextCursor = page.nextCursor;
    } on AppFailure catch (error) {
      if (!_disposed && generation == _generation) pageError = error.message;
    } finally {
      if (!_disposed && generation == _generation) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
