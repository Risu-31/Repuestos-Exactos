import 'package:autoscan/features/diagnostic/data/transports/obd_transport.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_exception.dart';

ObdTransport createObdTransport() => _UnsupportedTransport();

class _UnsupportedTransport implements ObdTransport {
  @override
  bool get supported => false;
  @override
  Stream<List<int>> get bytes => const Stream.empty();
  @override
  Future<void> connect() async => throw const ObdException(
    'Este incremento requiere Chrome de escritorio y Web Serial.',
  );
  @override
  Future<void> write(List<int> bytes) async =>
      throw const ObdException('Transporte no disponible.');
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> dispose() async {}
}
