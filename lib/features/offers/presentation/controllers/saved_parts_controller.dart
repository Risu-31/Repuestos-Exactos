import 'package:flutter/foundation.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/offers/domain/entities/saved_part.dart';
import 'package:autoscan/features/offers/domain/repositories/offers_repository.dart';

class SavedPartsController extends ChangeNotifier {
  SavedPartsController(this.repository);
  final OffersRepository repository;
  List<SavedPart> items = const [];
  bool loading = false, loadingMore = false;
  String? error, pageError;
  int? nextOffset;
  bool _disposed = false;
  int _generation = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    loading = true;
    loadingMore = false;
    error = null;
    pageError = null;
    nextOffset = null;
    items = const [];
    _notify();
    try {
      final page = await repository.saved();
      if (!_disposed && generation == _generation) {
        items = page.items;
        nextOffset = page.nextOffset;
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

  Future<void> loadMore() async {
    final offset = nextOffset, generation = _generation;
    if (loading || loadingMore || offset == null || _disposed) return;
    loadingMore = true;
    pageError = null;
    _notify();
    try {
      final page = await repository.saved(offset: offset);
      if (!_disposed && generation == _generation) {
        final ids = items.map((i) => i.id).toSet();
        items = [...items, ...page.items.where((i) => ids.add(i.id))];
        nextOffset = page.nextOffset;
      }
    } on AppFailure catch (e) {
      if (!_disposed && generation == _generation) pageError = e.message;
    } finally {
      if (!_disposed && generation == _generation) {
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
