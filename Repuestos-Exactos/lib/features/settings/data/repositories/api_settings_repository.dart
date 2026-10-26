import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/settings/data/models/workshop_settings_dto.dart';
import 'package:autoscan/features/settings/domain/entities/workshop_settings.dart';
import 'package:autoscan/features/settings/domain/repositories/settings_repository.dart';

class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository(this._client);
  final ApiClient _client;
  @override
  Future<WorkshopSettings> load() async {
    final data = await _client.get('/settings');
    try {
      return WorkshopSettingsDto.parse(data);
    } on FormatException catch (_) {
      throw const AppFailure('No pudimos interpretar los datos del taller.');
    }
  }
}
