import 'package:dio/dio.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_config.dart';

class ApiClient {
  ApiClient({Dio? dio, String? baseUrl}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 8),
      headers: {'accept': 'application/json'},
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final requestToken = error.requestOptions.extra['sessionToken'];
          if (error.response?.statusCode == 401 &&
              requestToken != null &&
              requestToken == _accessToken) {
            _accessToken = null;
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  String? _accessToken;
  void Function()? onUnauthorized;
  String? get accessToken => _accessToken;
  void setAccessToken(String? token) => _accessToken = token;
  void clearAccessTokenIfMatches(String? token) {
    if (_accessToken == token) _accessToken = null;
  }

  Future<Object?> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _request('GET', path, queryParameters: queryParameters);
  Future<Object?> post(
    String path, {
    Object? data,
    bool authenticated = true,
  }) => _request('POST', path, data: data, authenticated: authenticated);

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    bool authenticated = true,
  }) async {
    final token = authenticated ? _accessToken : null;
    if (authenticated && token == null) {
      throw const AppFailure('Vuelve a iniciar sesión.', statusCode: 401);
    }
    try {
      final response = await _dio.request<Object?>(
        path,
        queryParameters: queryParameters,
        data: data,
        options: Options(
          method: method,
          headers: {if (token != null) 'authorization': 'Bearer $token'},
          extra: {'sessionToken': ?token},
        ),
      );
      return response.data;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401) {
        throw AppFailure(
          authenticated
              ? 'Tu sesión terminó. Vuelve a ingresar.'
              : 'Correo o contraseña incorrectos.',
          statusCode: status,
        );
      }
      if (status == 400 || status == 413 || status == 415) {
        throw AppFailure('Revisa los datos ingresados.', statusCode: status);
      }
      if (status == 403) {
        throw AppFailure(
          'No tienes permiso para esta operación.',
          statusCode: status,
        );
      }
      if (status != null && status >= 500) {
        throw AppFailure(
          'El servicio no está disponible. Intenta nuevamente.',
          statusCode: status,
        );
      }
      final message = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'La conexión tardó demasiado. Intenta nuevamente.',
        DioExceptionType.connectionError =>
          'No pudimos conectar con el servicio. Revisa tu conexión.',
        DioExceptionType.cancel => 'La solicitud fue cancelada.',
        _ => 'No pudimos completar la solicitud. Intenta nuevamente.',
      };
      throw AppFailure(message, statusCode: status);
    }
  }

  void close() => _dio.close(force: true);
}
