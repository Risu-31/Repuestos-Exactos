import 'package:autoscan/core/network/json_reader.dart';
import 'package:autoscan/features/settings/domain/entities/workshop_settings.dart';

class WorkshopSettingsDto {
  static WorkshopSettings parse(Object? data) {
    final json = JsonReader.object(data);
    final theme = JsonReader.text(json, 'tema');
    final years = json['retencion_anios'];
    if (years is! int || years < 0 || !{'claro', 'oscuro'}.contains(theme)) {
      throw const FormatException('Configuración de taller inválida.');
    }
    return WorkshopSettings(
      id: JsonReader.text(json, 'id_publico'),
      name: JsonReader.text(json, 'nombre'),
      currency: JsonReader.text(json, 'moneda'),
      theme: theme,
      marginPercent: JsonReader.number(json, 'margen_pct'),
      retentionYears: years,
    );
  }
}
