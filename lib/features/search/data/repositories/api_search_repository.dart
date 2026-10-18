import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/features/search/data/models/catalog_dto.dart';
import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/search/domain/entities/dtc_page.dart';
import 'package:autoscan/features/search/domain/entities/part_page.dart';
import 'package:autoscan/features/search/domain/entities/vehicle_match.dart';
import 'package:autoscan/features/search/domain/repositories/search_repository.dart';

class ApiSearchRepository implements SearchRepository {
  ApiSearchRepository(this._client);
  final ApiClient _client;
  Future<T> _read<T>(
    String path,
    T Function(Object?) parse, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _client.get(path, queryParameters: query);
    try {
      return parse(data);
    } on FormatException catch (_) {
      throw const AppFailure(
        'No pudimos interpretar los datos de búsqueda. Intenta nuevamente.',
      );
    }
  }

  @override
  Future<List<CatalogOption>> brands() =>
      _read('/catalog/brands', CatalogDto.options);
  @override
  Future<List<CatalogOption>> models(String brand) => _read(
    '/catalog/brands/${Uri.encodeComponent(brand)}/models',
    CatalogDto.options,
  );
  @override
  Future<DtcPage> codes(String prefix) =>
      _read('/catalog/dtc', CatalogDto.codes, query: {'q': prefix});
  @override
  Future<PartPage> parts(
    String code, {
    String? model,
    int? year,
    int offset = 0,
  }) => _read(
    '/catalog/dtc/${Uri.encodeComponent(code)}/parts',
    CatalogDto.parts,
    query: {'model': ?model, 'year': ?year, 'offset': offset, 'limit': 20},
  );
  @override
  Future<VehicleMatch?> vehicle(String vin) =>
      _read('/search', CatalogDto.vehicle, query: {'vin': vin});
}
