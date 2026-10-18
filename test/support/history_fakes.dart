import 'dart:async';

import 'package:autoscan/features/history/domain/entities/history_entry.dart';
import 'package:autoscan/features/history/domain/entities/history_page.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';
import 'package:autoscan/features/history/domain/repositories/history_repository.dart';

HistoryEntry historyEntry(
  String id, {
  HistoryStatus status = HistoryStatus.pendiente,
  bool hidden = false,
}) => HistoryEntry(
  id: id,
  status: status,
  startedAt: DateTime.utc(2026, 10, 18, 12),
  method: 'manual',
  userName: 'Diego Rojas',
  faultCount: 2,
  vehicleId: hidden ? null : '00000000-0000-0000-0000-000000000002',
  brand: hidden ? null : 'Toyota',
  model: hidden ? null : 'Yaris',
  year: hidden ? null : 2018,
  plate: hidden ? null : 'GHJK34',
);

class FakeHistoryRepository implements HistoryRepository {
  final calls = <({HistoryStatus? status, String? cursor, int limit})>[];
  Future<HistoryPage> Function(HistoryStatus? status, String? cursor)? handler;
  @override
  Future<HistoryPage> load({
    HistoryStatus? status,
    String? cursor,
    int limit = 20,
  }) async {
    calls.add((status: status, cursor: cursor, limit: limit));
    return handler == null
        ? const HistoryPage(items: [])
        : handler!(status, cursor);
  }
}
