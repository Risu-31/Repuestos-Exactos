import 'package:autoscan/core/network/json_reader.dart';
import 'package:autoscan/features/history/domain/entities/history_entry.dart';
import 'package:autoscan/features/history/domain/entities/history_page.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';

class HistoryPageDto {
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static HistoryPage parse(Object? value) {
    final json = JsonReader.object(value);
    final data = json['data'];
    final cursor = json['next_cursor'];
    if (data is! List ||
        data.length > 100 ||
        !json.containsKey('next_cursor') ||
        (cursor != null &&
            (cursor is! String ||
                cursor.isEmpty ||
                cursor.length > 512 ||
                !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(cursor)))) {
      throw const FormatException('Página de historial inválida.');
    }
    final items = data.map((item) => _entry(JsonReader.object(item))).toList();
    if ((items.isEmpty && cursor != null) ||
        items.map((item) => item.id).toSet().length != items.length) {
      throw const FormatException('Página de historial inconsistente.');
    }
    return HistoryPage(
      items: List.unmodifiable(items),
      nextCursor: cursor as String?,
    );
  }

  static HistoryEntry _entry(Map<String, dynamic> json) {
    final id = JsonReader.text(json, 'id_publico');
    final status = JsonReader.text(json, 'estado');
    final dateText = JsonReader.text(json, 'iniciada_en');
    final date = DateTime.tryParse(dateText);
    final method = JsonReader.text(json, 'metodo_ingreso');
    final faults = json['fallas'];
    final vehicleId = _optionalText(json, 'vehiculo_id_publico');
    final year = json['vehiculo_anio'];
    final severity = _optionalText(json, 'severidad_maxima');
    if (!_uuid.hasMatch(id) ||
        !HistoryStatus.values.any((v) => v.name == status) ||
        date == null ||
        !date.isUtc ||
        date.year < 1 ||
        date.year > 9999 ||
        date.toIso8601String() != dateText ||
        !{'manual', 'obd_bluetooth'}.contains(method) ||
        faults is! int ||
        faults < 0 ||
        (vehicleId != null && !_uuid.hasMatch(vehicleId)) ||
        (year != null && (year is! int || year < 1886 || year > 9999)) ||
        (severity != null &&
            !{'baja', 'media', 'alta', 'critica'}.contains(severity))) {
      throw const FormatException('Diagnóstico inválido.');
    }
    return HistoryEntry(
      id: id,
      status: HistoryStatus.values.byName(status),
      startedAt: date,
      method: method,
      userName: JsonReader.text(json, 'usuario_nombre'),
      faultCount: faults,
      vehicleId: vehicleId,
      year: year as int?,
      plate: _optionalText(json, 'vehiculo_patente'),
      model: _optionalText(json, 'modelo_nombre'),
      brand: _optionalText(json, 'marca_nombre'),
      maxSeverity: severity,
    );
  }

  static String? _optionalText(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (!json.containsKey(key) ||
        (value != null && (value is! String || value.trim().isEmpty))) {
      throw const FormatException('Campo de historial inválido.');
    }
    return value as String?;
  }
}
