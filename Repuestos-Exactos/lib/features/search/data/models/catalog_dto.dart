import 'package:autoscan/core/network/json_reader.dart';
import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/search/domain/entities/dtc_option.dart';
import 'package:autoscan/features/search/domain/entities/dtc_page.dart';
import 'package:autoscan/features/search/domain/entities/part_result.dart';
import 'package:autoscan/features/search/domain/entities/part_page.dart';
import 'package:autoscan/features/search/domain/entities/vehicle_match.dart';

class CatalogDto {
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static String _id(Map<String, dynamic> json, String key) {
    final value = JsonReader.text(json, key);
    if (!_uuid.hasMatch(value)) throw const FormatException('UUID inválido.');
    return value;
  }

  static int _integer(
    Map<String, dynamic> json,
    String key, {
    int min = 0,
    int max = 2147483647,
  }) {
    final value = json[key];
    if (value is! int || value < min || value > max) {
      throw const FormatException('Entero inválido.');
    }
    return value;
  }

  static String _enum(
    Map<String, dynamic> json,
    String key,
    Set<String> allowed,
  ) {
    final value = JsonReader.text(json, key);
    if (!allowed.contains(value)) {
      throw const FormatException('Valor de catálogo inválido.');
    }
    return value;
  }

  static List<Map<String, dynamic>> _rows(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) {
      throw const FormatException('Lista de catálogo inválida.');
    }
    return data.map(JsonReader.object).toList();
  }

  static List<CatalogOption> options(Object? value) {
    final rows = _rows(JsonReader.object(value));
    final items = rows
        .map(
          (row) => CatalogOption(
            id: _id(row, 'id_publico'),
            name: JsonReader.text(row, 'nombre'),
          ),
        )
        .toList();
    if (items.map((item) => item.id).toSet().length != items.length) {
      throw const FormatException('Opciones duplicadas.');
    }
    return List.unmodifiable(items);
  }

  static DtcPage codes(Object? value) {
    final json = JsonReader.object(value);
    final more = json['has_more'];
    if (more is! bool) throw const FormatException('Paginación DTC inválida.');
    final items = _rows(json).map((row) {
      final code = JsonReader.text(row, 'codigo');
      if (!RegExp(r'^[PCBU][0-3][0-9A-F]{3}$').hasMatch(code)) {
        throw const FormatException('DTC inválido.');
      }
      return DtcOption(
        code: code,
        description: JsonReader.text(row, 'descripcion'),
        severity: _enum(row, 'severidad_sugerida', {
          'baja',
          'media',
          'alta',
          'critica',
        }),
        componentCount: _integer(row, 'componentes'),
      );
    }).toList();
    if (items.length > 100 ||
        items.map((item) => item.code).toSet().length != items.length ||
        (items.isEmpty && more)) {
      throw const FormatException('Lista DTC inconsistente.');
    }
    return DtcPage(items: List.unmodifiable(items), hasMore: more);
  }

  static PartPage parts(Object? value) {
    final json = JsonReader.object(value);
    final offset = json['next_offset'];
    if (!json.containsKey('next_offset') ||
        (offset != null && (offset is! int || offset < 1))) {
      throw const FormatException('Paginación de repuestos inválida.');
    }
    final items = _rows(json).map((row) {
      final priceText = JsonReader.text(row, 'precio_venta');
      final price = BigInt.tryParse(priceText);
      final currency = JsonReader.text(row, 'moneda');
      if (!RegExp(r'^(0|[1-9][0-9]{0,18})$').hasMatch(priceText) ||
          price == null ||
          price > BigInt.parse('9223372036854775807') ||
          !RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
        throw const FormatException('Precio inválido.');
      }
      return PartResult(
        id: _id(row, 'id_publico'),
        componentId: _id(row, 'componente_id_publico'),
        componentName: JsonReader.text(row, 'componente_nombre'),
        profile: _enum(row, 'perfil', {'genuino', 'oem', 'generico'}),
        brand: JsonReader.text(row, 'marca'),
        name: JsonReader.text(row, 'nombre'),
        manufacturerCode: JsonReader.text(row, 'codigo_fabricante'),
        durability: _integer(row, 'durabilidad_estimada_km', min: 1),
        risk: _enum(row, 'riesgo', {'bajo', 'medio', 'alto'}),
        salePrice: price,
        currency: currency,
      );
    }).toList();
    if (items.length > 100 ||
        items.map((item) => item.id).toSet().length != items.length ||
        (items.isEmpty && offset != null)) {
      throw const FormatException('Lista de repuestos inconsistente.');
    }
    return PartPage(
      items: List.unmodifiable(items),
      nextOffset: offset as int?,
    );
  }

  static VehicleMatch? vehicle(Object? value) {
    final json = JsonReader.object(value);
    if (!json.containsKey('data')) {
      throw const FormatException('Vehículo inválido.');
    }
    if (json['data'] == null) return null;
    final row = JsonReader.object(json['data']);
    final vin = JsonReader.text(row, 'vin');
    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin)) {
      throw const FormatException('VIN inválido.');
    }
    return VehicleMatch(
      id: _id(row, 'id_publico'),
      vin: vin,
      plate: JsonReader.text(row, 'patente'),
      year: _integer(row, 'anio', min: 1981, max: 2100),
      modelId: _id(row, 'modelo_id_publico'),
      modelName: JsonReader.text(row, 'modelo_nombre'),
      brandId: _id(row, 'marca_id_publico'),
      brandName: JsonReader.text(row, 'marca_nombre'),
    );
  }
}
