import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/features/search/domain/entities/catalog_option.dart';
import 'package:autoscan/features/search/domain/entities/dtc_page.dart';
import 'package:autoscan/features/search/domain/entities/part_page.dart';
import 'package:autoscan/features/search/domain/entities/vehicle_match.dart';
import 'package:autoscan/features/search/presentation/controllers/catalog_search_controller.dart';

import 'support/search_fakes.dart';

void main() {
  CatalogSearchController create(
    FakeSearchRepository repository, {
    bool vin = true,
  }) {
    final controller = CatalogSearchController(
      repository,
      canLookupVehicle: vin,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> selectCode(CatalogSearchController controller) async {
    controller.changeCodeQuery('P0300');
    await controller.searchCodes();
  }

  test(
    'DTC and complete vehicle filter are required before querying parts',
    () async {
      final repository = FakeSearchRepository();
      final controller = create(repository);
      await controller.searchParts();
      expect(repository.partCalls, isEmpty);
      await selectCode(controller);
      await controller.selectBrand('brand');
      controller.selectModel('model');
      await controller.searchParts();
      expect(repository.partCalls, isEmpty);
      expect(controller.partsError, contains('año'));
      controller.selectYear('2018');
      await controller.searchParts();
      expect(repository.partCalls.single.model, 'model');
      expect(repository.partCalls.single.year, 2018);
      await controller.selectBrand(null);
      expect(controller.parts, isEmpty);
    },
  );
  test(
    'late code and model responses cannot overwrite newer selections',
    () async {
      final pendingCode = Completer<DtcPage>();
      final pendingModels = Completer<List<CatalogOption>>();
      final repository = FakeSearchRepository();
      repository.codeHandler = (_) => pendingCode.future;
      repository.modelHandler = (brand) async =>
          brand == 'brand' ? pendingModels.future : const [];
      final controller = create(repository);
      controller.changeCodeQuery('P03');
      final codeLoad = controller.searchCodes();
      controller.changeCodeQuery('P04');
      pendingCode.complete(const DtcPage(items: [searchCode], hasMore: false));
      await codeLoad;
      expect(controller.codes, isEmpty);
      final oldModelLoad = controller.selectBrand('brand');
      await controller.selectBrand('other');
      pendingModels.complete(const [CatalogOption(id: 'stale', name: 'Old')]);
      await oldModelLoad;
      expect(controller.models, isEmpty);
      expect(controller.brandId, 'other');
    },
  );
  test('parts from an earlier filter are discarded', () async {
    final pending = Completer<PartPage>();
    final repository = FakeSearchRepository()
      ..partHandler = (_, _, _, _) => pending.future;
    final controller = create(repository);
    await selectCode(controller);
    final load = controller.searchParts();
    controller.changeCodeQuery('P04');
    pending.complete(PartPage(items: [searchPart('stale')]));
    await load;
    expect(controller.parts, isEmpty);
    expect(controller.searched, isFalse);
  });
  test(
    'VIN fills model/year and editing it clears the previous match',
    () async {
      final repository = FakeSearchRepository();
      final controller = create(repository);
      await controller.initialize();
      await controller.lookupVin('jtdbr32e760123456');
      expect(controller.modelId, 'model');
      expect(controller.year, 2018);
      controller.changeVin();
      expect(controller.modelId, isNull);
      expect(controller.vehicleMatch, isNull);
    },
  );
  test(
    'manual selection cancels a pending VIN and auditor cannot query it',
    () async {
      final pending = Completer<VehicleMatch?>();
      final repository = FakeSearchRepository()
        ..vehicleHandler = (_) => pending.future;
      final controller = create(repository);
      await controller.initialize();
      final load = controller.lookupVin(searchVehicle.vin);
      await controller.selectBrand('other');
      pending.complete(searchVehicle);
      await load;
      expect(controller.brandId, 'other');
      expect(controller.vehicleMatch, isNull);
      final auditorRepository = FakeSearchRepository();
      final auditor = create(auditorRepository, vin: false);
      await auditor.lookupVin(searchVehicle.vin);
      expect(auditorRepository.vehicleCalls, 0);
    },
  );
  test(
    'page failure preserves results and retry does not duplicate items',
    () async {
      var fail = true;
      final repository = FakeSearchRepository()
        ..partHandler = (_, _, _, offset) async {
          if (offset == 0) {
            return PartPage(items: [searchPart('first')], nextOffset: 1);
          }
          if (fail) throw const AppFailure('Sin conexión');
          return PartPage(items: [searchPart('first'), searchPart('second')]);
        };
      final controller = create(repository);
      await selectCode(controller);
      await controller.searchParts();
      await controller.loadMore();
      expect(controller.parts.single.id, 'first');
      expect(controller.pageError, 'Sin conexión');
      fail = false;
      await controller.loadMore();
      expect(controller.parts.length, 2);
      expect(controller.hasMore, isFalse);
    },
  );
  test('dispose ignores pending results', () async {
    final pending = Completer<DtcPage>();
    final repository = FakeSearchRepository()
      ..codeHandler = (_) => pending.future;
    final controller = CatalogSearchController(
      repository,
      canLookupVehicle: true,
    );
    final load = controller.searchCodes();
    controller.dispose();
    pending.complete(const DtcPage(items: [searchCode], hasMore: false));
    await load;
    expect(controller.codes, isEmpty);
  });
}
