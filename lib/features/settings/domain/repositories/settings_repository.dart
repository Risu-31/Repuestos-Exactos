import 'package:autoscan/features/settings/domain/entities/workshop_settings.dart';

abstract class SettingsRepository {
  Future<WorkshopSettings> load();
}
