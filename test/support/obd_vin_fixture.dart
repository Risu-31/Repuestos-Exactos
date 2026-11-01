// Identificador sintético: no corresponde al Peugeot del usuario.
const vin = 'VF300000000000001';
String hex(int value) => value.toRadixString(16).padLeft(2, '0').toUpperCase();
String canVin(String value, {String ecu = '7E8'}) {
  final bytes = [0x49, 2, 1, ...value.codeUnits];
  return [
    '$ecu 10 14 ${bytes.take(6).map(hex).join(' ')}',
    '$ecu 21 ${bytes.skip(6).take(7).map(hex).join(' ')}',
    '$ecu 22 ${bytes.skip(13).map(hex).join(' ')}',
  ].join('\n');
}
