import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/search/domain/entities/dtc_page.dart';
import 'package:autoscan/features/search/domain/entities/part_page.dart';
import 'package:autoscan/features/search/domain/entities/vehicle_match.dart';

abstract interface class SearchRepository {
  Future<List<CatalogOption>> brands();
  Future<List<CatalogOption>> models(String brand);
  Future<DtcPage> codes(String prefix);
  Future<PartPage> parts(
    String code, {
    String? model,
    int? year,
    int offset = 0,
  });
  Future<VehicleMatch?> vehicle(String vin);
}
