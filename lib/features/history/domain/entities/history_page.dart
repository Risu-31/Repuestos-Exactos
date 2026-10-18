import 'package:autoscan/features/history/domain/entities/history_entry.dart';

class HistoryPage {
  const HistoryPage({required this.items, this.nextCursor});
  final List<HistoryEntry> items;
  final String? nextCursor;
}
