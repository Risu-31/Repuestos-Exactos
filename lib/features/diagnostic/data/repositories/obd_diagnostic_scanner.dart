import 'dart:async';

import 'package:autoscan/features/diagnostic/data/protocol/obd_vin_decoder.dart';

import 'package:autoscan/features/diagnostic/data/protocol/elm327_client.dart';
import 'package:autoscan/features/diagnostic/data/protocol/obd_decoder.dart';
import 'package:autoscan/features/diagnostic/data/transports/obd_transport.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_scan.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_exception.dart';
import 'package:autoscan/features/diagnostic/domain/entities/dtc_observation.dart';
import 'package:autoscan/features/diagnostic/domain/repositories/diagnostic_scanner.dart';

class ObdDiagnosticScanner implements DiagnosticScanner {
  ObdDiagnosticScanner(this.transport) : client = Elm327Client(transport) {
    _errorsSubscription = transport.bytes.listen(
      (_) {},
      onError: (Object e) {
        _connected = false;
        if (!_connectionEvents.isClosed) _connectionEvents.add(e.toString());
        unawaited(disconnect());
      },
    );
  }
  final _connectionEvents = StreamController<String>.broadcast();
  late final StreamSubscription<List<int>> _errorsSubscription;
  @override
  Stream<String> get connectionErrors => _connectionEvents.stream;
  final ObdTransport transport;
  final Elm327Client client;
  bool _connected = false;
  @override
  bool get supported => transport.supported;
  @override
  Future<void> connect() async {
    await transport.connect();
    client.reset();
    try {
      final id = await client.command('ATI');
      if (!RegExp('ELM|VLINK|STN', caseSensitive: false).hasMatch(id)) {
        throw const ObdException(
          'El puerto elegido no responde como adaptador OBD compatible.',
        );
      }
      await client.command('ATZ');
      for (final command in ['ATE0', 'ATL0', 'ATS1', 'ATH1', 'ATSP0']) {
        if ((await client.command(command)).trim() != 'OK') {
          throw const ObdException(
            'El adaptador no aceptó su configuración de lectura.',
          );
        }
      }
      _connected = true;
    } catch (_) {
      await disconnect();
      rethrow;
    }
  }

  @override
  Future<ObdScan> scan({required void Function(String) onProgress}) async {
    if (!_connected) throw const ObdException('Conecta primero el vLinker MC.');
    try {
      onProgress('Identificando protocolo del vehículo…');
      final supported = await client.command(
        '0100',
        timeout: const Duration(seconds: 45),
      );
      final protocolText = (await client.command('ATDPN')).trim().toUpperCase();
      final number = int.tryParse(
        protocolText.replaceFirst(RegExp('^A'), ''),
        radix: 16,
      );
      if (number == null || number < 1 || number > 9) {
        throw const ObdException(
          'Protocolo no compatible con este primer incremento.',
        );
      }
      ObdDecoder.messages(supported, number, 0x41);
      final status = ObdDecoder.messages(
        await client.command('0101'),
        number,
        0x41,
      );
      final counts = <String, int>{};
      for (final m in status) {
        if (m.data.length < 6 || m.data[1] != 1) {
          throw const ObdException('Estado de la ECU incompleto.');
        }
        counts[m.ecu] = m.data[2] & 127;
      }
      final observations = <DtcObservation>[];
      final services = <String, String>{};
      for (final entry in {
        '03': 'stored',
        '07': 'pending',
        '0A': 'permanent',
      }.entries) {
        onProgress(
          'Leyendo ${entry.value == 'stored'
              ? 'fallas almacenadas'
              : entry.value == 'pending'
              ? 'fallas pendientes'
              : 'fallas permanentes'}…',
        );
        final raw = await client.command(entry.key);
        if (raw.trim() == 'NO DATA' || raw.trim() == '?') {
          if (entry.key == '03') {
            if (raw.trim() != 'NO DATA' ||
                counts.isEmpty ||
                counts.values.any((v) => v != 0)) {
              throw const ObdException(
                'No se pudieron recuperar todas las fallas almacenadas.',
              );
            }
            services[entry.key] = 'empty';
          } else {
            services[entry.key] = raw.trim() == '?' ? 'unsupported' : 'no_data';
          }
          continue;
        }
        final messages = ObdDecoder.messages(
          raw,
          number,
          int.parse(entry.key, radix: 16) + 0x40,
          allowNegative: entry.key != '03',
        );
        final rejected = messages.where((m) => m.data.first == 0x7F).toList();
        if (rejected.any(
          (m) =>
              m.data[1] != int.parse(entry.key, radix: 16) ||
              !{0x11, 0x12, 0x31}.contains(m.data[2]),
        )) {
          throw const ObdException(
            'La ECU no pudo completar la consulta. Repite la lectura.',
          );
        }
        final valid = messages.where((m) => m.data.first != 0x7F).toList();
        if (valid.isEmpty) {
          services[entry.key] = 'unsupported';
          continue;
        }
        final parsed = ObdDecoder.dtcs(valid, entry.value);
        if (entry.key == '03') {
          for (final e in counts.entries) {
            if (parsed.where((o) => o.ecu == e.key).length != e.value) {
              throw const ObdException(
                'La cantidad de fallas no coincide con la ECU; repite la lectura.',
              );
            }
          }
        }
        observations.addAll(parsed);
        if (observations.length > 256) {
          throw const ObdException(
            'El escaneo excede el límite de esta versión.',
          );
        }
        services[entry.key] = rejected.isNotEmpty
            ? 'partial'
            : parsed.isEmpty
            ? 'empty'
            : 'ok';
      }
      // El VIN es opcional y se consulta al final: nunca descarta DTC ya leídos.
      String? vin;
      var vinStatus = 'unavailable';
      onProgress('Leyendo VIN del vehículo…');
      try {
        final rawVin = await client.command('0902');
        if (rawVin.trim() != 'NO DATA' && rawVin.trim() != '?') {
          vin = ObdVinDecoder.decode(
            ObdDecoder.messages(rawVin, number, 0x49, allowNegative: true),
          );
          vinStatus = vin == null ? 'unsupported' : 'read';
        }
      } on ObdException {
        vinStatus = 'invalid_or_incomplete';
      }
      return ObdScan(
        vin: vin,
        vinStatus: vinStatus,
        capturedAt: DateTime.now().toUtc(),
        protocol: 'ELM protocolo $number',
        services: services,
        observations: observations,
      );
    } catch (_) {
      await disconnect();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    await client.cancel();
  }

  @override
  Future<void> dispose() async {
    await _errorsSubscription.cancel();
    await client.dispose();
    await transport.dispose();
    await _connectionEvents.close();
  }
}
