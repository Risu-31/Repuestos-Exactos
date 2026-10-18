import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/history/data/models/history_page_dto.dart';
import 'package:autoscan/features/history/domain/entities/history_page.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';
import 'package:autoscan/features/history/domain/repositories/history_repository.dart';

class ApiHistoryRepository implements HistoryRepository {
  ApiHistoryRepository(this._client);
  final ApiClient _client;
  @override
  Future<HistoryPage> load({
    HistoryStatus? status,
    String? cursor,
    int limit = 20,
  }) async {
    final data = await _client.get(
      '/sessions',
      queryParameters: {
        'limit': limit,
        if (status != null) 'status': status.name,
        'cursor': ?cursor,
      },
    );
    try {
      return HistoryPageDto.parse(data);
    } on FormatException catch (_) {
      throw const AppFailure(
        'No pudimos interpretar el historial. Intenta nuevamente.',
      );
    }
  }
}
