import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/features/history/data/models/history_page_dto.dart';
import 'package:autoscan/features/history/domain/entities/history_status.dart';

void main() {
  Map<String, Object?> row() => {
    'id_publico': '00000000-0000-0000-0000-000000000001',
    'estado': 'pendiente',
    'iniciada_en': '2026-10-18T12:00:00.123456Z',
    'metodo_ingreso': 'manual',
    'usuario_nombre': 'Diego Rojas',
    'fallas': 2,
    'vehiculo_id_publico': null,
    'vehiculo_patente': null,
    'vehiculo_anio': null,
    'modelo_nombre': null,
    'marca_nombre': null,
    'severidad_maxima': 'alta',
  };
  test(
    'accepts a hidden vehicle and preserves typed status and microseconds',
    () {
      final page = HistoryPageDto.parse({
        'data': [row()],
        'next_cursor': null,
      });
      expect(page.items.single.vehicleId, isNull);
      expect(page.items.single.status, HistoryStatus.pendiente);
      expect(page.items.single.startedAt.microsecond, 456);
    },
  );
  test('rejects malformed rows, duplicates and invalid pagination', () {
    for (final edit in <Map<String, Object?>>[
      {'fallas': '2'},
      {'fallas': -1},
      {'estado': 'unknown'},
      {'iniciada_en': '2026-02-30T00:00:00.000Z'},
      {'id_publico': 'bad'},
      {'metodo_ingreso': 'unknown'},
      {'vehiculo_anio': '2018'},
    ]) {
      expect(
        () => HistoryPageDto.parse({
          'data': [
            {...row(), ...edit},
          ],
          'next_cursor': null,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => HistoryPageDto.parse({
        'data': [row(), row()],
        'next_cursor': null,
      }),
      throwsFormatException,
    );
    expect(
      () => HistoryPageDto.parse({'data': [], 'next_cursor': 'next'}),
      throwsFormatException,
    );
    expect(
      () => HistoryPageDto.parse({
        'data': [row()],
      }),
      throwsFormatException,
    );
  });
}
