import 'package:autoscan/features/diagnostic/data/protocol/obd_message.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_exception.dart';

/// SAE mode 09 PID 02, con cabeceras activas e ISO-TP ya reensamblado.
class ObdVinDecoder {
  static String? decode(List<ObdMessage> messages) {
    final values = <String>{};
    final legacy = <String, Map<int, List<int>>>{};
    for (final m in messages) {
      final data = m.data;
      if (data.first == 0x7F) {
        if (data.length != 3 ||
            data[1] != 9 ||
            !{0x11, 0x12, 0x31}.contains(data[2])) {
          throw const ObdException('La ECU no completó la identificación VIN.');
        }
        continue;
      }
      if (data.length < 4 || data[0] != 0x49 || data[1] != 2) {
        throw const ObdException('Respuesta VIN incompleta.');
      }
      if (m.can) {
        if (data.length != 20 || data[2] != 1) {
          throw const ObdException('Longitud VIN CAN inválida.');
        }
        values.add(_vin(data.sublist(3)));
      } else {
        if (data.length != 7 || data[2] < 1 || data[2] > 5) {
          throw const ObdException('Segmento VIN inválido.');
        }
        final segments = legacy.putIfAbsent(m.ecu, () => {});
        if (segments.containsKey(data[2])) {
          throw const ObdException('Segmento VIN duplicado.');
        }
        segments[data[2]] = data.sublist(3);
      }
    }
    for (final parts in legacy.values) {
      if (parts.length != 5 || parts[1]!.take(3).any((b) => b != 0)) {
        throw const ObdException('VIN heredado incompleto.');
      }
      values.add(_vin([for (var i = 1; i <= 5; i++) ...parts[i]!].sublist(3)));
    }
    if (values.length > 1) {
      throw const ObdException('Las ECU devolvieron VIN diferentes.');
    }
    return values.singleOrNull;
  }

  static String _vin(List<int> bytes) {
    final value = String.fromCharCodes(bytes);
    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(value) ||
        value.split('').toSet().length == 1) {
      throw const ObdException('El vehículo devolvió un VIN inválido.');
    }
    return value;
  }
}
