import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/search/domain/entities/dtc_option.dart';
import 'package:autoscan/features/search/domain/entities/dtc_page.dart';
import 'package:autoscan/features/search/domain/entities/part_page.dart';
import 'package:autoscan/features/search/domain/entities/part_result.dart';
import 'package:autoscan/features/search/domain/entities/vehicle_match.dart';
import 'package:autoscan/features/search/domain/repositories/search_repository.dart';

const searchCode = DtcOption(
  code: 'P0300',
  description: 'Fallas de encendido',
  severity: 'alta',
  componentCount: 1,
);
PartResult searchPart(String id) => PartResult(
  id: id,
  componentId: 'component',
  componentName: 'Bobina de encendido',
  profile: 'oem',
  brand: 'Denso',
  name: 'Bobina Denso',
  manufacturerCode: 'TEST-01',
  durability: 100000,
  risk: 'bajo',
  salePrice: BigInt.from(45000),
  currency: 'CLP',
);
const searchVehicle = VehicleMatch(
  id: 'vehicle',
  vin: 'JTDBR32E760123456',
  plate: 'GHJK34',
  year: 2018,
  modelId: 'model',
  modelName: 'Yaris',
  brandId: 'brand',
  brandName: 'Toyota',
);

class FakeSearchRepository implements SearchRepository {
  Future<List<CatalogOption>> Function(String)? modelHandler;
  Future<DtcPage> Function(String)? codeHandler;
  Future<PartPage> Function(String, String?, int?, int)? partHandler;
  Future<VehicleMatch?> Function(String)? vehicleHandler;
  int vehicleCalls = 0;
  final partCalls = <({String code, String? model, int? year, int offset})>[];
  @override
  Future<List<CatalogOption>> brands() async => const [
    CatalogOption(id: 'brand', name: 'Toyota'),
    CatalogOption(id: 'other', name: 'Hyundai'),
  ];
  @override
  Future<List<CatalogOption>> models(String brand) async => modelHandler == null
      ? const [CatalogOption(id: 'model', name: 'Yaris')]
      : modelHandler!(brand);
  @override
  Future<DtcPage> codes(String query) async => codeHandler == null
      ? const DtcPage(items: [searchCode], hasMore: false)
      : codeHandler!(query);
  @override
  Future<PartPage> parts(
    String code, {
    String? model,
    int? year,
    int offset = 0,
  }) async {
    partCalls.add((code: code, model: model, year: year, offset: offset));
    return partHandler == null
        ? PartPage(items: [searchPart('first')])
        : partHandler!(code, model, year, offset);
  }

  @override
  Future<VehicleMatch?> vehicle(String vin) async {
    vehicleCalls++;
    return vehicleHandler == null ? searchVehicle : vehicleHandler!(vin);
  }
}
