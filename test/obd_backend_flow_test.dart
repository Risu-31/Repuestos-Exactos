import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';
import 'package:autoscan/core/utils/new_uuid.dart';
import 'package:autoscan/features/diagnostic/data/repositories/obd_diagnostic_scanner.dart';
import 'package:autoscan/features/diagnostic/data/repositories/api_diagnostic_sessions_repository.dart';
import 'package:autoscan/features/offers/data/repositories/api_offers_repository.dart';

import 'support/obd_transport_fake.dart';

import 'package:autoscan/features/search/data/repositories/api_search_repository.dart';

import 'support/obd_vin_fixture.dart';

void main() {
  test('Motor OBD → API → PostgreSQL → historial → alternativa asociada', () async {
    expect(Platform.environment['DB_NAME'], startsWith('re_api_preflight_'));
    final client = ApiClient(baseUrl: Platform.environment['TEST_API_URL']);
    addTearDown(client.close);
    final login = await client.post(
      '/auth/login',
      authenticated: false,
      data: {
        'email': 'mecanico2@losaromos.example',
        'password': Platform.environment['DEMO_PASSWORD'],
      },
    ) as Map<String, dynamic>;
    client.setAccessToken(login['access_token'] as String);
    final repo = ApiDiagnosticSessionsRepository(client);
    final vehicles = await repo.vehicles();
    final devices = await repo.devices();
    expect(vehicles, isNotEmpty);
    expect(devices, isNotEmpty);
    final nonce = DateTime.now().microsecondsSinceEpoch.toString();
    final observedVin = 'VF3${nonce.substring(nonce.length - 14)}';
    expect(observedVin.length, 17);
    final scanner = ObdDiagnosticScanner(
      ObdTransportFake()..responses['0902'] = '${canVin(observedVin)}\r>',
    );
    addTearDown(scanner.dispose);
    await scanner.connect();
    final scan = await scanner.scan(onProgress: (_) {});
    await scanner.disconnect();
    final key = newUuid();
    final catalog = ApiSearchRepository(client);
    final peugeot = (await catalog.brands()).singleWhere(
      (b) => b.name == 'Peugeot',
    );
    final model3008 = (await catalog.models(peugeot.id))
        .singleWhere((m) => m.name == '3008');
    final plate =
        'QA${DateTime.now().microsecondsSinceEpoch.remainder(10000).toString().padLeft(4, '0')}';
    final v = await repo.registerVehicle(
      modelId: model3008.id,
      year: 2017,
      plate: plate,
      engine: '1.6 gasolina',
    );
    expect(
      (await repo.registerVehicle(
        modelId: model3008.id,
        year: 2017,
        plate: plate,
        engine: '1.6 gasolina',
      )).id,
      v.id,
    );
    final d = devices.first;
    // El VIN no se asocia si falla la creación de la sesión: todo revierte.
    await expectLater(
      repo.save(
        scan,
        vehicleId: v.id,
        deviceId: newUuid(),
        mileage: 120000,
        key: newUuid(),
      ),
      throwsA(isA<AppFailure>().having((e) => e.statusCode, 'status', 404)),
    );
    expect(await repo.vehicles(vin: observedVin), isEmpty);
    final saved = await Future.wait(
      List.generate(
        2,
        (_) => repo.save(
          scan,
          vehicleId: v.id,
          deviceId: d.id,
          mileage: 120000,
          key: key,
        ),
      ),
    );
    expect(saved.first.id, saved.last.id);
    final id = saved.first.id;
    final detail = await repo.detail(id);
    expect(detail.observations.length, 3);
    expect(detail.vin, observedVin);
    expect((await repo.vehicles(vin: observedVin)).single.id, v.id);
    final mismatchVehicle = await repo.registerVehicle(
      modelId: v.modelId,
      year: v.year,
      plate:
          'QA${(int.parse(plate.substring(2)) + 1).remainder(10000).toString().padLeft(4, '0')}',
      engine: '1.6 gasolina',
      vin: 'VF4${observedVin.substring(3)}',
    );
    await expectLater(
      repo.save(
        scan,
        vehicleId: mismatchVehicle.id,
        deviceId: d.id,
        mileage: 120000,
        key: newUuid(),
      ),
      throwsA(isA<AppFailure>().having((e) => e.statusCode, 'status', 409)),
    );
    expect((await repo.detail(id)).vin, observedVin);
    await expectLater(
      repo.registerVehicle(
        modelId: v.modelId,
        year: v.year,
        plate:
            'QA${(int.parse(plate.substring(2)) + 2).remainder(10000).toString().padLeft(4, '0')}',
        engine: '1.6 gasolina',
        vin: observedVin,
      ),
      throwsA(isA<AppFailure>().having((e) => e.statusCode, 'status', 409)),
    );
    expect(
      detail.observations.firstWhere((o) => o.code == 'P3999').description,
      isNull,
    );
    final history = await client.get('/sessions') as Map<String, dynamic>;
    final entry = (history['data'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((e) => e['id_publico'] == id);
    expect(entry['fallas'], 2);
    expect(entry['estado'], 'pendiente');
    expect(entry['cotizacion_total'], isNull);
    final offers = ApiOffersRepository(client);
    final components = await offers.components('P0301');
    final found = await offers.search(
      code: 'P0301',
      componentId: components.first.id,
      model: v.modelId,
      year: v.year,
      vehicleId: v.id,
      sessionId: id,
    );
    expect(found, isNotEmpty);
    await offers.save(
      token: found.first.token,
      key: newUuid(),
      note: 'Integración aislada del escáner',
    );
    final alternatives =
        await client.get('/saved-parts?limit=100') as Map<String, dynamic>;
    expect(
      (alternatives['items'] as List).cast<Map<String, dynamic>>().any(
        (a) => a['session_id'] == id,
      ),
      isTrue,
    );
    await expectLater(
      client.post(
        '/diagnostic-devices',
        data: {'name': 'vLinker MC', 'idempotency_key': newUuid()},
      ),
      throwsA(isA<AppFailure>().having((e) => e.statusCode, 'status', 403)),
    );
    final other = ApiClient(baseUrl: Platform.environment['TEST_API_URL']);
    addTearDown(other.close);
    final otherLogin = await other.post(
      '/auth/login',
      authenticated: false,
      data: {
        'email': 'admin@nuble.example',
        'password': Platform.environment['DEMO_PASSWORD'],
      },
    ) as Map<String, dynamic>;
    other.setAccessToken(otherLogin['access_token'] as String);
    expect(
      await ApiDiagnosticSessionsRepository(other).vehicles(vin: observedVin),
      isEmpty,
    );
    await expectLater(
      other.get('/sessions/$id'),
      throwsA(isA<AppFailure>().having((e) => e.statusCode, 'status', 404)),
    );
    await expectLater(
      ApiDiagnosticSessionsRepository(other).save(
        scan,
        vehicleId: v.id,
        deviceId: d.id,
        mileage: 120000,
        key: newUuid(),
      ),
      throwsA(isA<AppFailure>().having((e) => e.statusCode, 'status', 404)),
    );
    await client.post('/auth/logout');
    await other.post('/auth/logout');
  }, skip: Platform.environment['RUN_OBD_HTTP_TESTS'] != 'true');
}
