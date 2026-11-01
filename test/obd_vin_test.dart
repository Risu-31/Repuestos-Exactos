import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/features/diagnostic/data/protocol/obd_decoder.dart';
import 'package:autoscan/features/diagnostic/data/protocol/obd_vin_decoder.dart';
import 'package:autoscan/features/diagnostic/data/repositories/obd_diagnostic_scanner.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_exception.dart';

import 'support/obd_transport_fake.dart';

import 'support/obd_vin_fixture.dart';

void main() {
  test('VIN CAN 11/29 bits y respuestas coincidentes de varias ECU', () {
    for (final ecu in ['7E8', '18DAF110']) {
      final protocol = ecu.length == 3 ? 6 : 7;
      expect(
        ObdVinDecoder.decode(
          ObdDecoder.messages(canVin(vin, ecu: ecu), protocol, 0x49),
        ),
        vin,
      );
    }
    final two = '${canVin(vin)}\n${canVin(vin, ecu: '7E9')}';
    expect(ObdVinDecoder.decode(ObdDecoder.messages(two, 6, 0x49)), vin);
  });
  test('VIN heredado ensambla cinco segmentos y elimina sólo relleno inicial', () {
    final bytes = [0, 0, 0, ...vin.codeUnits];
    final response = [
      for (var i = 0; i < 5; i++)
        '48 6B 10 49 02 ${hex(i + 1)} ${bytes.skip(i * 4).take(4).map(hex).join(' ')} 00',
    ].join('\n');
    expect(ObdVinDecoder.decode(ObdDecoder.messages(response, 3, 0x49)), vin);
  });
  test('rechaza truncamiento, VIN inválido y discrepancia entre ECU', () {
    for (final raw in [
      canVin(vin).split('\n').take(2).join('\n'),
      canVin('IF300000000000001'),
      '${canVin(vin)}\n${canVin('VF300000000000002', ecu: '7E9')}',
    ]) {
      expect(
        () => ObdVinDecoder.decode(ObdDecoder.messages(raw, 6, 0x49)),
        throwsA(isA<ObdException>()),
      );
    }
  });
  test('lee VIN después de DTC y preserva todos los códigos', () async {
    final t = ObdTransportFake()..responses['0902'] = '${canVin(vin)}\r>';
    final scanner = ObdDiagnosticScanner(t);
    addTearDown(scanner.dispose);
    await scanner.connect();
    final scan = await scanner.scan(onProgress: (_) {});
    expect(scan.vin, vin);
    expect(scan.vinStatus, 'read');
    expect(scan.observations.length, 3);
    expect(t.commands.last, '0902');
    expect(t.commands, isNot(contains('04')));
  });
  test('VIN no soportado o inválido no descarta las fallas', () async {
    for (final response in [
      'NO DATA\r>',
      '7E8 03 7F 09 11\r>',
      '${canVin('IF300000000000001')}\r>',
    ]) {
      final t = ObdTransportFake()..responses['0902'] = response;
      final scanner = ObdDiagnosticScanner(t);
      await scanner.connect();
      final scan = await scanner.scan(onProgress: (_) {});
      expect(scan.vin, isNull);
      expect(scan.observations.length, 3);
      await scanner.dispose();
    }
  });
  test(
    'timeout VIN conserva DTC y cierra puerto para impedir contaminación',
    () async {
      final t = ObdTransportFake()..responses.remove('0902');
      final scanner = ObdDiagnosticScanner(t);
      addTearDown(scanner.dispose);
      await scanner.connect();
      final scan = await scanner.scan(onProgress: (_) {});
      expect(scan.vin, isNull);
      expect(scan.observations.length, 3);
      expect(t.closed, isTrue);
    },
  );
}
