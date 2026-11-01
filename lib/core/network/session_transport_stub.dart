import 'package:dio/dio.dart';

bool _signedOut = false;
void configureSessionTransport(Dio dio) {}
bool allowSessionRestore() => !_signedOut;
void rememberSessionLogout(bool value) {
  _signedOut = value;
}
