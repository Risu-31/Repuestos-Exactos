import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/features/search/data/models/catalog_dto.dart';

void main() {
  const id = '00000000-0000-0000-0000-000000000001';
  Map<String, Object?> part() => {
    'id_publico': id,
    'componente_id_publico': id,
    'componente_nombre': 'Bobina',
    'perfil': 'oem',
    'marca': 'Denso',
    'nombre': 'Bobina',
    'codigo_fabricante': 'TEST',
    'durabilidad_estimada_km': 100000,
    'riesgo': 'bajo',
    'precio_venta': '9007199254740993',
    'moneda': 'CLP',
  };
  test('money above the JavaScript integer limit keeps exact precision', () {
    final page = CatalogDto.parts({
      'data': [part()],
      'next_offset': null,
    });
    expect(page.items.single.salePrice.toString(), '9007199254740993');
  });
  test('rejects unsafe amounts, unknown profiles and inconsistent pages', () {
    for (final edit in <Map<String, Object?>>[
      {'precio_venta': 45000},
      {'precio_venta': '-1'},
      {'precio_venta': '9223372036854775808'},
      {'perfil': 'unknown'},
      {'moneda': 'clp'},
      {'durabilidad_estimada_km': 0},
      {'id_publico': 'bad'},
    ]) {
      expect(
        () => CatalogDto.parts({
          'data': [
            {...part(), ...edit},
          ],
          'next_offset': null,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => CatalogDto.parts({
        'data': [part(), part()],
        'next_offset': null,
      }),
      throwsFormatException,
    );
    expect(
      () => CatalogDto.parts({'data': [], 'next_offset': 2}),
      throwsFormatException,
    );
  });
  test('validates DTC shape and avoids duplicate selector options', () {
    expect(
      () => CatalogDto.codes({
        'data': [
          {
            'codigo': 'P9999',
            'descripcion': 'Bad',
            'severidad_sugerida': 'alta',
            'componentes': 1,
          },
        ],
        'has_more': false,
      }),
      throwsFormatException,
    );
    expect(
      () => CatalogDto.options({
        'data': [
          {'id_publico': id, 'nombre': 'Toyota'},
          {'id_publico': id, 'nombre': 'Toyota'},
        ],
      }),
      throwsFormatException,
    );
  });
  test('vehicle match and missing match are distinct typed results', () {
    expect(CatalogDto.vehicle({'data': null}), isNull);
    final vehicle = CatalogDto.vehicle({
      'data': {
        'id_publico': id,
        'vin': 'JTDBR32E760123456',
        'patente': 'GHJK34',
        'anio': 2018,
        'modelo_id_publico': id,
        'modelo_nombre': 'Yaris',
        'marca_id_publico': id,
        'marca_nombre': 'Toyota',
      },
    });
    expect(vehicle!.year, 2018);
    expect(() => CatalogDto.vehicle({}), throwsFormatException);
  });
}
