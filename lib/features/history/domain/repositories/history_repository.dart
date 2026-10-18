import 'package:autoscan/features/history/domain/entities/history_page.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';

abstract interface class HistoryRepository {
  Future<HistoryPage> load({
    HistoryStatus? status,
    String? cursor,
    int limit = 20,
  });
}
