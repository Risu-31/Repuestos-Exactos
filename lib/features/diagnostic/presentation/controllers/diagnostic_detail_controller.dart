import 'package:flutter/foundation.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_detail.dart';
import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_sessions_repository.dart';

class DiagnosticDetailController extends ChangeNotifier {
  DiagnosticDetailController(this.repository, this.id);
  final DiagnosticSessionsRepository repository;
  final String id;
  DiagnosticDetail? detail;
  String? error;
  bool loading = false, _disposed = false;
  Future<void> load() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await repository.detail(id);
      if (!_disposed) detail = result;
    } catch (e) {
      if (!_disposed) {
        error = e is AppFailure
            ? e.message
            : 'No se pudo cargar el diagnóstico.';
      }
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
