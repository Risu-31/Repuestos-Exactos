import 'package:autoscan/features/diagnostic/domain/entities/obd_scan.dart';

abstract interface class DiagnosticScanner {
  bool get supported;
  Stream<String> get connectionErrors;
  Future<void> connect();
  Future<ObdScan> scan({required void Function(String) onProgress});
  Future<void> disconnect();
  Future<void> dispose();
}
