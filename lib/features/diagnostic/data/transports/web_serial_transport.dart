import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:autoscan/features/diagnostic/data/transports/obd_transport.dart';
import 'package:autoscan/features/diagnostic/domain/entities/obd_exception.dart';

@JS('navigator')
external _Navigator get _navigator;
@JS('isSecureContext')
external bool get _secure;

extension type _Navigator(JSObject _) implements JSObject {
  external _Serial? get serial;
}

extension type _Serial(JSObject _) implements JSObject {
  external JSPromise<_Port> requestPort(JSObject options);
}

extension type _Port(JSObject _) implements JSObject {
  external JSPromise<JSAny?> open(JSObject options);
  external _Readable? get readable;
  external _Writable? get writable;
  external JSPromise<JSAny?> close();
}

extension type _Readable(JSObject _) implements JSObject {
  external _Reader getReader();
}

extension type _Writable(JSObject _) implements JSObject {
  external _Writer getWriter();
}

extension type _Reader(JSObject _) implements JSObject {
  external JSPromise<_ReadResult> read();
  external JSPromise<JSAny?> cancel();
  external void releaseLock();
}

extension type _Writer(JSObject _) implements JSObject {
  external JSPromise<JSAny?> write(JSUint8Array value);
  external JSPromise<JSAny?> abort();
  external void releaseLock();
}

extension type _ReadResult(JSObject _) implements JSObject {
  external bool get done;
  external JSUint8Array? get value;
}

ObdTransport createObdTransport() => WebSerialTransport();

class WebSerialTransport implements ObdTransport {
  final _events = StreamController<List<int>>.broadcast(sync: true);
  _Port? _port;
  _Reader? _reader;
  _Writer? _writer;
  Future<void>? _reading;
  Future<void>? _closing;
  int _generation = 0;
  bool _disposed = false;
  @override
  bool get supported => _secure && _navigator.serial != null;
  @override
  Stream<List<int>> get bytes => _events.stream;
  @override
  Future<void> connect() async {
    if (!supported) {
      throw const ObdException(
        'Abre la aplicación en Chrome de escritorio usando localhost o HTTPS. Web Serial no está disponible aquí.',
      );
    }
    if (_disposed || _port != null || _closing != null) {
      throw const ObdException(
        'La conexión anterior todavía se está cerrando.',
      );
    }
    final generation = ++_generation;
    try {
      // Debe ejecutarse desde el clic del usuario, antes de cualquier espera de red.
      final port = await _navigator.serial!
          .requestPort(
            {
                  'filters': [
                    {
                      'bluetoothServiceClassId':
                          '00001101-0000-1000-8000-00805f9b34fb',
                    },
                  ],
                }.jsify()!
                as JSObject,
          )
          .toDart;
      if (_disposed || generation != _generation) {
        throw const ObdException('Conexión cancelada.');
      }
      _port = port;
      var expired = false;
      final opening = port
          .open({'baudRate': 115200, 'bufferSize': 8192}.jsify()! as JSObject)
          .toDart;
      unawaited(
        opening.then((_) async {
          if (expired) {
            try {
              await port.close().toDart;
            } catch (_) {}
          }
        }, onError: (Object _) {}),
      );
      await opening.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          expired = true;
          throw const ObdException(
            'El puerto no respondió al abrir. Desconecta y vuelve a intentarlo.',
          );
        },
      );
      if (_disposed || generation != _generation) {
        await disconnect();
        throw const ObdException('Conexión cancelada.');
      }
      if (port.readable == null || port.writable == null) {
        throw const ObdException(
          'El dispositivo no expone un puerto serie de lectura y escritura.',
        );
      }
      _reader = port.readable!.getReader();
      _writer = port.writable!.getWriter();
      _reading = _read(generation, _reader!);
    } catch (error) {
      await disconnect();
      if (error is ObdException) rethrow;
      throw const ObdException(
        'No se abrió el puerto. Selecciona el vLinker MC emparejado y revisa que otra aplicación no lo esté usando.',
      );
    }
  }

  Future<void> _read(int generation, _Reader reader) async {
    try {
      while (!_disposed && generation == _generation) {
        final result = await reader.read().toDart;
        if (result.done) break;
        final value = result.value;
        if (value != null && generation == _generation && !_events.isClosed) {
          _events.add(List<int>.from(value.toDart));
        }
      }
      if (generation == _generation && !_events.isClosed) {
        _events.addError(
          const ObdException(
            'Se desconectó el adaptador. Vuelve a conectar antes de escanear.',
          ),
        );
      }
    } catch (_) {
      if (generation == _generation && !_events.isClosed) {
        _events.addError(
          const ObdException('Se interrumpió la lectura del puerto Bluetooth.'),
        );
      }
    } finally {
      reader.releaseLock();
    }
  }

  @override
  Future<void> write(List<int> bytes) async {
    final writer = _writer;
    if (writer == null) {
      throw const ObdException('Conecta primero el adaptador.');
    }
    try {
      await writer
          .write(Uint8List.fromList(bytes).toJS)
          .toDart
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      throw const ObdException('No se pudo enviar el comando al adaptador.');
    }
  }

  @override
  Future<void> disconnect() =>
      _closing ??= _close().whenComplete(() => _closing = null);
  Future<void> _close() async {
    ++_generation;
    final reader = _reader;
    final writer = _writer;
    final port = _port;
    final reading = _reading;
    _reader = null;
    _writer = null;
    _port = null;
    _reading = null;
    if (reader != null) {
      try {
        await reader.cancel().toDart.timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    if (reading != null) {
      try {
        await reading.timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    if (writer != null) {
      try {
        await writer.abort().toDart.timeout(const Duration(seconds: 2));
      } catch (_) {
      } finally {
        writer.releaseLock();
      }
    }
    if (port != null) {
      try {
        await port.close().toDart.timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disconnect();
    await _events.close();
  }
}
