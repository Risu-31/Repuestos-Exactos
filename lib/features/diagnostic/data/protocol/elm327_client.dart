import 'dart:async';
import 'dart:convert';

import 'package:autoscan/features/diagnostic/data/transports/obd_transport.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_exception.dart';

class Elm327Client {
  Elm327Client(this.transport) {
    _subscription = transport.bytes.listen(
      _receive,
      onError: _error,
      onDone: () => _error(const ObdException('Conexión cerrada.')),
    );
  }
  final ObdTransport transport;
  late final StreamSubscription<List<int>> _subscription;
  Completer<String>? _pending;
  String _buffer = '';
  bool _broken = false;
  static const _allowed = {
    'ATI',
    'ATZ',
    'ATE0',
    'ATL0',
    'ATS1',
    'ATH1',
    'ATSP0',
    'ATDPN',
    '0100',
    '0101',
    '03',
    '07',
    '0A',
    '0902',
  };
  void reset() {
    _broken = false;
    _buffer = '';
  }

  void _receive(List<int> data) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    _buffer += ascii.decode(data, allowInvalid: true);
    if (_buffer.length > 16384) {
      _error(
        const ObdException('Respuesta demasiado grande o sin terminador.'),
      );
      return;
    }
    final end = _buffer.indexOf('>');
    if (end >= 0) pending.complete(_buffer.substring(0, end));
  }

  void _error(Object error) {
    _broken = true;
    final p = _pending;
    if (p != null && !p.isCompleted) p.completeError(error);
  }

  Future<String> command(
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_allowed.contains(command)) {
      throw const ObdException('Comando fuera del alcance de lectura.');
    }
    if (_pending != null || _broken) {
      throw const ObdException(
        'Reconecta el adaptador para restablecer la comunicación.',
      );
    }
    _buffer = '';
    final pending = Completer<String>();
    _pending = pending;
    final reply = pending.future.timeout(timeout);
    try {
      unawaited(
        transport.write(ascii.encode('$command\r')).catchError((Object e) {
          _error(e);
        }),
      );
      final raw = await reply;
      return raw
          .split(RegExp(r'[\r\n]+'))
          .map((s) => s.trim())
          .where(
            (s) =>
                s.isNotEmpty && s.replaceAll(' ', '').toUpperCase() != command,
          )
          .join('\n');
    } on TimeoutException {
      _broken = true;
      await transport.disconnect();
      throw const ObdException(
        'El adaptador agotó el tiempo de respuesta. Reconecta antes de repetir la lectura.',
      );
    } finally {
      _pending = null;
      _buffer = '';
    }
  }

  Future<void> cancel() async {
    _error(const ObdException('Lectura cancelada.'));
    await transport.disconnect();
  }

  Future<void> dispose() async {
    await cancel();
    await _subscription.cancel();
  }
}
