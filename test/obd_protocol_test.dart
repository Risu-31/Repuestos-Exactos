import 'package:flutter_test/flutter_test.dart';
import 'package:autoscan/features/diagnostic/data/protocol/elm327_client.dart';
import 'package:autoscan/features/diagnostic/data/protocol/obd_decoder.dart';
import 'package:autoscan/features/diagnostic/data/repositories/obd_diagnostic_scanner.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_exception.dart';

import 'support/obd_transport_fake.dart';

void main() {
  test(
    'Servicio opcional rechazado o parcial no oculta los códigos ya leídos',
    () async {
      final t = ObdTransportFake()
        ..responses['07'] =
            '7E8 03 7F 07 11 00 00 00 00\r7E9 04 47 01 03 01 00 00 00\r>'
        ..responses['0A'] = '7E8 03 7F 0A 12 00 00 00 00\r>';
      final scanner = ObdDiagnosticScanner(t);
      addTearDown(scanner.dispose);
      await scanner.connect();
      final result = await scanner.scan(onProgress: (_) {});
      expect(result.services['07'], 'partial');
      expect(result.services['0A'], 'unsupported');
      expect(result.observations.where((o) => o.kind == 'stored').length, 2);
    },
  );
  test('CAN usa el contador DTC y no lo interpreta como parte del código', () {
    final response = ObdDecoder.messages('7E8 06 43 01 01 04 00 00', 6, 0x43);
    expect(ObdDecoder.dtcs(response, 'stored').single.code, 'P0104');
    expect(
      ObdDecoder.dtcs(
        ObdDecoder.messages('7E8 02 43 00 00 00 00 00 00', 6, 0x43),
        'stored',
      ),
      isEmpty,
    );
  });
  test(
    'Motor real: comandos, fragmentación, varias categorías y desconocidos',
    () async {
      final t = ObdTransportFake();
      final scanner = ObdDiagnosticScanner(t);
      addTearDown(scanner.dispose);
      await scanner.connect();
      final result = await scanner.scan(onProgress: (_) {});
      expect(result.observations.map((o) => o.code), [
        'P0301',
        'P3999',
        'P0301',
      ]);
      expect(result.observations.map((o) => o.kind), [
        'stored',
        'stored',
        'pending',
      ]);
      expect(result.services, {'03': 'ok', '07': 'ok', '0A': 'no_data'});
      expect(
        t.commands,
        containsAllInOrder([
          'ATI',
          'ATZ',
          'ATH1',
          '0100',
          '0101',
          '03',
          '07',
          '0A',
        ]),
      );
      expect(t.commands.contains('04'), isFalse);
    },
  );
  test('CAN multitrama reconstruye antes de decodificar', () {
    final frames = ObdDecoder.messages(
      '7E8 10 08 43 03 03 01 02 00\r7E8 21 01 71 00 00 00 00 00',
      6,
      0x43,
    );
    expect(ObdDecoder.dtcs(frames, 'stored').map((o) => o.code), [
      'P0301',
      'P0200',
      'P0171',
    ]);
  });
  test('Distingue ECU, CAN de 29 bits y códigos PCBU', () {
    final frames = ObdDecoder.messages(
      '18DAF110 06 43 02 43 00 C1 00 00\r18DAF118 04 43 01 80 01 00 00 00',
      7,
      0x43,
    );
    expect(ObdDecoder.dtcs(frames, 'stored').map((o) => o.code), [
      'C0300',
      'U0100',
      'B0001',
    ]);
    expect(frames.map((m) => m.ecu), ['18DAF110', '18DAF118']);
  });
  test('Protocolo heredado separa cabecera y checksum', () {
    final frames = ObdDecoder.messages(
      '48 6B 10 43 01 33 00 00 00 00 55',
      3,
      0x43,
    );
    expect(ObdDecoder.dtcs(frames, 'stored').single.code, 'P0133');
    expect(frames.single.ecu, '10');
  });
  test('Rechaza tramas incompletas, orden inválido y respuesta equivocada', () {
    for (final raw in [
      '7E8 10 08 43 03 03 01 02 00',
      '7E8 21 43 03 01 00 00 00 00',
      '7E8 03 47 03 01 00 00 00 00',
    ]) {
      expect(
        () => ObdDecoder.messages(raw, 6, 0x43),
        throwsA(isA<ObdException>()),
      );
    }
  });
  test(
    'NO DATA no se transforma en cero fallas cuando ECU declara códigos',
    () async {
      final t = ObdTransportFake()..responses['03'] = 'NO DATA\r>';
      final scanner = ObdDiagnosticScanner(t);
      addTearDown(scanner.dispose);
      await scanner.connect();
      await expectLater(
        scanner.scan(onProgress: (_) {}),
        throwsA(isA<ObdException>()),
      );
      expect(t.closed, isTrue);
    },
  );
  test(
    'Cero códigos comprobado y servicios no soportados permanecen distintos',
    () async {
      final t = ObdTransportFake()
        ..responses['0101'] = '7E8 06 41 01 00 00 00 00\r>'
        ..responses['03'] = 'NO DATA\r>'
        ..responses['07'] = '?\r>';
      final scanner = ObdDiagnosticScanner(t);
      addTearDown(scanner.dispose);
      await scanner.connect();
      final result = await scanner.scan(onProgress: (_) {});
      expect(result.services, {
        '03': 'empty',
        '07': 'unsupported',
        '0A': 'no_data',
      });
      expect(result.observations, isEmpty);
    },
  );
  test('Timeout invalida el contexto y exige reconectar', () async {
    final t = ObdTransportFake()..responses.remove('ATI');
    final client = Elm327Client(t);
    addTearDown(() async {
      await client.dispose();
      await t.dispose();
    });
    await expectLater(
      client.command('ATI', timeout: const Duration(milliseconds: 20)),
      throwsA(isA<ObdException>()),
    );
    expect(t.closed, isTrue);
    await expectLater(client.command('03'), throwsA(isA<ObdException>()));
  });
  test('Cancelar interrumpe la espera sin dejar comandos vivos', () async {
    final t = ObdTransportFake()..responses.remove('ATI');
    final client = Elm327Client(t);
    addTearDown(() async {
      await client.dispose();
      await t.dispose();
    });
    final result = expectLater(
      client.command('ATI'),
      throwsA(isA<ObdException>()),
    );
    await client.cancel();
    await result;
    await expectLater(client.command('04'), throwsA(isA<ObdException>()));
  });
}
