import 'dart:async';
import 'dart:convert';

import 'package:autoscan/features/diagnostic/data/transports/obd_transport.dart';

class ObdTransportFake implements ObdTransport {
  final events = StreamController<List<int>>.broadcast(sync: true);
  final commands = <String>[];
  bool closed = false;
  final responses = <String, String>{
    'ATI': 'ELM327 v2.2\r>',
    'ATZ': 'ELM327 v2.2\r>',
    'ATE0': 'OK\r>',
    'ATL0': 'OK\r>',
    'ATS1': 'OK\r>',
    'ATH1': 'OK\r>',
    'ATSP0': 'OK\r>',
    '0100': 'SEARCHING...\r7E8 06 41 00 BE 3E B8 13\r>',
    'ATDPN': 'A6\r>',
    '0101': '7E8 06 41 01 02 00 00 00\r>',
    '03': '7E8 06 43 02 03 01 39 99 00\r>',
    '07': '7E8 04 47 01 03 01 00 00 00\r>',
    '0A': 'NO DATA\r>',
    '0902': 'NO DATA\r>',
  };
  @override
  bool get supported => true;
  @override
  Stream<List<int>> get bytes => events.stream;
  @override
  Future<void> connect() async {
    closed = false;
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (closed) throw StateError('closed');
    if (bytes.last != 13) throw StateError('command missing CR');
    final command = ascii.decode(bytes).trim();
    commands.add(command);
    final response = responses[command];
    if (response == null) return;
    final encoded = ascii.encode(response);
    for (var i = 0; i < encoded.length; i += 3) {
      events.add(
        encoded.sublist(i, i + 3 > encoded.length ? encoded.length : i + 3),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    closed = true;
  }

  @override
  Future<void> dispose() async {
    closed = true;
    await events.close();
  }
}
