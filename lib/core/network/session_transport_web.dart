import 'dart:js_interop';

import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

@JS('localStorage')
external _Storage get _storage;

extension type _Storage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
}

const _logoutKey = 're_session_signed_out_v1';

/// El navegador custodia la cookie HttpOnly; no se guarda ningún token en storage.
void configureSessionTransport(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}

bool allowSessionRestore() {
  try {
    return _storage.getItem(_logoutKey) != 'true';
  } catch (_) {
    return false;
  }
}

/// Conserva sólo intención de cierre, para no reingresar tras un logout sin red.
void rememberSessionLogout(bool value) {
  try {
    _storage.setItem(_logoutKey, value ? 'true' : 'false');
  } catch (_) {}
}
