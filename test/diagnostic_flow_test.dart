import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:autoscan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autoscan/features/diagnostic/data/repositories/obd_diagnostic_scanner.dart';
import 'package:autoscan/features/diagnostic/presentation/controllers/diagnostic_controller.dart';
import 'package:autoscan/features/diagnostic/presentation/views/diagnostic_screen.dart';

import 'support/obd_transport_fake.dart';
import 'support/obd_vin_fixture.dart';

import 'package:autoscan/features/diagnostic/domain/entities/diagnostic_vehicle.dart';

import 'support/diagnostic_repository_fake.dart';
import 'support/session_fakes.dart';

void main() {
  Future<DiagnosticController> ready(
    ObdTransportFake t,
    DiagnosticRepositoryFake r,
  ) async {
    final c = DiagnosticController(ObdDiagnosticScanner(t), r);
    await c.load();
    c.selectVehicle('v');
    c.mileage = '120000';
    return c;
  }

  test(
    'Guardar reintenta con la misma clave y conserva el resultado real',
    () async {
      final r = DiagnosticRepositoryFake()..failSave = true;
      final t = ObdTransportFake();
      final c = await ready(t, r);
      addTearDown(c.dispose);
      await c.connect();
      await c.read();
      expect(c.scan, isNotNull);
      expect(c.connected, isFalse);
      expect(t.closed, isTrue);
      await c.save();
      expect(c.error, isNotNull);
      expect(c.scan, isNotNull);
      await c.save();
      expect(c.saved, isNotNull);
      expect(r.keys.length, 2);
      expect(r.keys.first, r.keys.last);
      await c.save();
      expect(r.keys.length, 2);
    },
  );
  test(
    'Cancelar una lectura pendiente no publica un resultado tardío',
    () async {
      final t = ObdTransportFake()..responses.remove('03');
      final c = await ready(t, DiagnosticRepositoryFake());
      addTearDown(c.dispose);
      await c.connect();
      final pending = c.read();
      await Future<void>.delayed(Duration.zero);
      await c.reset();
      await pending;
      expect(c.scan, isNull);
      expect(c.connected, isFalse);
      expect(c.busy, isFalse);
      expect(t.closed, isTrue);
    },
  );
  test('Desconexión física en espera exige una nueva conexión', () async {
    final t = ObdTransportFake();
    final c = await ready(t, DiagnosticRepositoryFake());
    addTearDown(c.dispose);
    await c.connect();
    t.events.addError(StateError('disconnected'));
    await Future<void>.delayed(Duration.zero);
    expect(c.connected, isFalse);
    expect(c.error, isNotNull);
  });
  test('VIN registrado identifica vehículo sin selección previa', () async {
    final r = DiagnosticRepositoryFake()
      ..registeredVehicles = [
        const DiagnosticVehicle(
          id: 'auto',
          modelId: 'm',
          year: 2017,
          label: 'Vehículo de prueba',
          vin: vin,
        ),
      ];
    final c = await ready(
      ObdTransportFake()..responses['0902'] = '${canVin(vin)}\r>',
      r,
    );
    addTearDown(c.dispose);
    c.selectVehicle(null);
    await c.connect();
    await c.read();
    expect(c.vehicle?.id, 'auto');
    expect(c.scan?.vin, vin);
    await c.save();
    expect(c.saved?.vin, vin);
  });
  test(
    'VIN nuevo preserva DTC y permite elegir vehículo después de leer',
    () async {
      final c = await ready(
        ObdTransportFake()..responses['0902'] = '${canVin(vin)}\r>',
        DiagnosticRepositoryFake(),
      );
      addTearDown(c.dispose);
      c.selectVehicle(null);
      await c.connect();
      await c.read();
      expect(c.vehicle, isNull);
      expect(c.scan?.observations.length, 3);
      await c.save();
      expect(c.error, isNotNull);
      expect(c.scan, isNotNull);
      c.selectVehicle('v');
      await c.save();
      expect(c.saved, isNotNull);
    },
  );
  test(
    'VIN diferente limpia selección y no permite asociar otro auto',
    () async {
      final r = DiagnosticRepositoryFake()
        ..registeredVehicles = [
          const DiagnosticVehicle(
            id: 'v',
            modelId: 'm',
            year: 2017,
            label: 'Otro',
            vin: 'VF300000000000002',
          ),
        ];
      final c = await ready(
        ObdTransportFake()..responses['0902'] = '${canVin(vin)}\r>',
        r,
      );
      addTearDown(c.dispose);
      await c.connect();
      await c.read();
      expect(c.vehicle, isNull);
      c.selectVehicle('v');
      expect(c.vehicle, isNull);
      expect(c.scan, isNotNull);
    },
  );
  test(
    'conflicto confirmado permite corregir contexto sin perder fallas',
    () async {
      final c = await ready(
        ObdTransportFake(),
        DiagnosticRepositoryFake()..rejectSaveStatus = 409,
      );
      addTearDown(c.dispose);
      await c.connect();
      await c.read();
      await c.save();
      expect(c.vehicleLocked, isFalse);
      expect(c.scan, isNotNull);
      c.selectVehicle('v');
      await c.save();
      expect(c.saved, isNotNull);
    },
  );
  testWidgets(
    'Pantalla estrecha: conectar, leer y guardar sin desbordamiento',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = await ready(ObdTransportFake(), DiagnosticRepositoryFake());
      final auth = AuthController(
        FakeAuthRepository(),
        FakeSettingsRepository(),
      );
      addTearDown(c.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: c),
            ChangeNotifierProvider.value(value: auth),
          ],
          child: const MaterialApp(home: DiagnosticScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('P0171'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Conectar vLinker MC').hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conectar vLinker MC'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Leer fallas del vehículo').hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leer fallas del vehículo'));
      await tester.pumpAndSettle();
      expect(c.scan!.observations.length, 3);
      await tester.scrollUntilVisible(
        find.text('Guardar diagnóstico'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Guardar diagnóstico'));
      await tester.pumpAndSettle();
      expect(c.saved, isNotNull);
      await tester.scrollUntilVisible(
        find.text('Ver historial del taller'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ver historial del taller'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
