import 'package:autoscan/features/diagnostic/data/protocol/obd_message.dart';
import 'package:autoscan/features/diagnostic/domain/entities/dtc_observation.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_exception.dart';

class ObdDecoder {
  static List<ObdMessage> messages(
    String response,
    int protocol,
    int positiveService, {
    bool allowNegative = false,
  }) {
    final results = <ObdMessage>[];
    final buffers = <String, List<int>>{};
    final lengths = <String, int>{};
    final sequences = <String, int>{};
    for (final original in response.toUpperCase().split(RegExp(r'[\r\n]+'))) {
      var line = original.trim();
      if (line.isEmpty || line == 'SEARCHING...' || line == 'BUS INIT: OK') {
        continue;
      }
      if (!RegExp(r'^[0-9A-F ]+$').hasMatch(line)) {
        throw const ObdException(
          'La ECU devolvió una respuesta no interpretable.',
        );
      }
      final tokens = line.split(RegExp(r'\s+'));
      String ecu;
      List<int> bytes;
      if (protocol >= 6 && protocol <= 9) {
        final headerLength = (protocol == 6 || protocol == 8) ? 3 : 8;
        line = tokens.join();
        if (line.length < headerLength + 2) {
          throw const ObdException('Trama CAN incompleta.');
        }
        ecu = line.substring(0, headerLength);
        final payload = line.substring(headerLength);
        if (payload.length.isOdd) {
          throw const ObdException('Longitud CAN inválida.');
        }
        bytes = [
          for (var i = 0; i < payload.length; i += 2)
            int.parse(payload.substring(i, i + 2), radix: 16),
        ];
        final pci = bytes.first >> 4;
        if (pci == 0) {
          final length = bytes.first & 15;
          if (length > bytes.length - 1) {
            throw const ObdException('Trama CAN truncada.');
          }
          bytes = bytes.sublist(1, 1 + length);
        } else if (pci == 1) {
          if (bytes.length < 3 || buffers.containsKey(ecu)) {
            throw const ObdException('Inicio multitrama inválido.');
          }
          lengths[ecu] = ((bytes[0] & 15) << 8) | bytes[1];
          buffers[ecu] = bytes.sublist(2);
          sequences[ecu] = 1;
          continue;
        } else if (pci == 2) {
          final data = buffers[ecu];
          if (data == null || bytes.first & 15 != sequences[ecu]) {
            throw const ObdException('Secuencia CAN incompleta.');
          }
          data.addAll(bytes.skip(1));
          sequences[ecu] = (sequences[ecu]! + 1) & 15;
          if (data.length < lengths[ecu]!) continue;
          bytes = data.take(lengths.remove(ecu)!).toList();
          buffers.remove(ecu);
          sequences.remove(ecu);
        } else {
          throw const ObdException(
            'Formato CAN no soportado por el perfil actual.',
          );
        }
      } else {
        final compact = tokens.join();
        if (compact.length < 10 || compact.length.isOdd) {
          throw const ObdException('Trama OBD incompleta.');
        }
        final all = [
          for (var i = 0; i < compact.length; i += 2)
            int.parse(compact.substring(i, i + 2), radix: 16),
        ];
        ecu = compact.substring(4, 6);
        bytes = all.sublist(3, all.length - 1);
      }
      if (bytes.isEmpty ||
          bytes.first != positiveService &&
              !(allowNegative && bytes.first == 0x7F && bytes.length >= 3)) {
        throw const ObdException(
          'Respuesta de un servicio diferente al solicitado.',
        );
      }
      results.add(ObdMessage(ecu, bytes, can: protocol >= 6));
    }
    if (buffers.isNotEmpty || results.isEmpty) {
      throw const ObdException('No se recibió una respuesta OBD completa.');
    }
    return results;
  }

  static List<DtcObservation> dtcs(List<ObdMessage> messages, String kind) {
    final result = <DtcObservation>[];
    final seen = <String>{};
    for (final m in messages) {
      if (m.can && m.data.length < 2) {
        throw const ObdException('Respuesta CAN sin contador DTC.');
      }
      final remaining = m.data.skip(m.can ? 2 : 1).toList();
      if (m.can &&
          (remaining.length < m.data[1] * 2 ||
              remaining.skip(m.data[1] * 2).any((b) => b != 0))) {
        throw const ObdException('Contador DTC CAN no coincide con la trama.');
      }
      final codes = m.can ? remaining.take(m.data[1] * 2).toList() : remaining;
      if (codes.length.isOdd) throw const ObdException('Código DTC truncado.');
      for (var i = 0; i < codes.length; i += 2) {
        final a = codes[i], b = codes[i + 1];
        if (a == 0 && b == 0) continue;
        final code =
            '${'PCBU'[a >> 6]}${(a >> 4) & 3}${(a & 15).toRadixString(16).toUpperCase()}${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
        if (seen.add('${m.ecu}|$code|$kind')) {
          result.add(DtcObservation(code: code, ecu: m.ecu, kind: kind));
        }
      }
    }
    return result;
  }
}
