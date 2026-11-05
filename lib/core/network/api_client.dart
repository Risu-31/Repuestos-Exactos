import 'package:dio/dio.dart';
import 'package:autoscan/core/network/session_transport.dart';
import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_config.dart';

class ApiClient {
  ApiClient({Dio? dio, String? baseUrl}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 8),
      headers: {'accept': 'application/json', 'x-re-session': '1'},
    );
    if (dio == null) configureSessionTransport(_dio);
  }

  final Dio _dio;
  String? _accessToken;
  int _epoch = 0;
  bool _ending = false;
  Future<Object?>? _refreshing;
  void Function(Object?)? onSessionRenewed;
  void Function()? onUnauthorized;
  String? get accessToken => _accessToken;
  void setAccessToken(String? token) {
    _epoch++;
    _accessToken = token;
  }

  void acceptLoginToken(String token) {
    rememberSessionLogout(false);
    setAccessToken(token);
  }

  bool get canRestoreSession => allowSessionRestore();
  void clearAccessTokenIfMatches(String? token) {
    if (_accessToken == token) setAccessToken(null);
  }

  /// Una sola renovación por cliente; las llamadas concurrentes comparten resultado.
  Future<Object?> renewSession() {
    if (_ending || !canRestoreSession) {
      return Future.error(
        const AppFailure('Vuelve a iniciar sesión.', statusCode: 401),
      );
    }
    return _refreshing ??= _renew().whenComplete(() => _refreshing = null);
  }

  Future<Object?> _renew() async {
    final epoch = _epoch;
    Object? data;
    for (var attempt = 0; ; attempt++) {
      try {
        data = await _request('POST', '/auth/refresh', authenticated: false);
        break;
      } on AppFailure catch (e) {
        if (e.statusCode != 409 || attempt >= 3) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 150 * (attempt + 1)));
      }
    }
    if (epoch != _epoch || _ending) {
      throw const AppFailure('La solicitud fue cancelada.');
    }
    if (data is! Map<String, dynamic> ||
        data['access_token'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$')
            .hasMatch(data['access_token'] as String)) {
      throw const AppFailure('El servicio devolvió una sesión inválida.');
    }
    _accessToken = data['access_token'] as String;
    try {
      onSessionRenewed?.call(data);
    } catch (_) {
      setAccessToken(null);
      onUnauthorized?.call();
      rethrow;
    }
    return data;
  }

  /// Espera una rotación pendiente y revoca la cookie más reciente antes de salir.
  Future<void> endSession() async {
    final oldToken = _accessToken;
    rememberSessionLogout(true);
    _ending = true;
    _epoch++;
    _accessToken = null;
    try {
      try {
        await _refreshing;
      } catch (_) {}
      await _dio.post<Object?>(
        '/auth/logout',
        options: Options(
          headers: {if (oldToken != null) 'authorization': 'Bearer $oldToken'},
        ),
      );
    } on DioException catch (_) {
      throw const AppFailure('No pudimos confirmar el cierre en el servidor.');
    } finally {
      _ending = false;
    }
  }

  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) => _request(
    'GET',
    path,
    queryParameters: queryParameters,
    authenticated: authenticated,
  );
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
    bool retryRefresh = true,
  }) async {
    final token = authenticated ? _accessToken : null;
    final requestEpoch = _epoch;
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
          receiveTimeout: path == '/offers/search'
              ? const Duration(seconds: 25)
              : null,
          headers: {if (token != null) 'authorization': 'Bearer $token'},
          extra: {'sessionToken': ?token},
        ),
      );
      return response.data;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 && authenticated && requestEpoch != _epoch) {
        throw const AppFailure('La solicitud fue cancelada.');
      }
      if (status == 401 &&
          authenticated &&
          retryRefresh &&
          !_ending &&
          !{'/auth/logout', '/auth/refresh'}.contains(path)) {
        if (token == _accessToken) {
          try {
            await renewSession();
          } on AppFailure catch (e) {
            if (e.statusCode == 401 || e.statusCode == 403) {
              setAccessToken(null);
              onUnauthorized?.call();
            }
            rethrow;
          }
        }
        if (_accessToken != null) {
          return _request(
            method,
            path,
            data: data,
            queryParameters: queryParameters,
            authenticated: true,
            retryRefresh: false,
          );
        }
      }
      if (status == 401 && authenticated && token == _accessToken) {
        setAccessToken(null);
        onUnauthorized?.call();
      }
      final responseData = error.response?.data;
      final code = responseData is Map ? responseData['error'] : null;
      final authMessage = switch (code) {
        'vin_vehicle_mismatch' => 'El VIN leído no corresponde al vehículo seleccionado. La lectura se conserva.',
        'vehicle_vin_conflict' =>
          'Este VIN ya está registrado en otro vehículo del taller.',
        'invalid_vin' => 'El VIN debe contener 17 caracteres válidos.',
        'invalid_scan' =>
          'La captura no es válida o está incompleta. Repite la lectura.',
        'scan_context_not_found' =>
          'El vehículo o adaptador ya no está disponible en tu taller.',
        'diagnostic_not_found' =>
          'El diagnóstico no está disponible para tu perfil.',
        'invalid_device' => 'Revisa el nombre y los datos del adaptador.',
        'ebay_not_configured' => 'eBay todavía no está configurado. Puedes consultar el otro proveedor.',
        'ebay_credentials_rejected' => 'No se pudo autorizar eBay. Revisa las credenciales del entorno en el servidor.',
        'provider_not_configured' =>
          'El proveedor seleccionado no está habilitado.',
        'invalid_offer_provider' => 'Selecciona un proveedor válido.',
        'mercadolibre_not_configured' => 'Mercado Libre todavía no está configurado. Puedes seguir usando el catálogo local.',
        'mercadolibre_authorization_required' =>
          'Es necesario autorizar la cuenta de Mercado Libre en el servidor.',
        'provider_access_denied' => 'El proveedor no autorizó la búsqueda para esta aplicación. El catálogo local sigue disponible.',
        'provider_rate_limited' =>
          'El proveedor alcanzó su límite de consultas. Intenta más tarde.',
        'provider_timeout' ||
        'provider_unavailable' ||
        'provider_invalid_response' =>
          'No pudimos consultar el proveedor de repuestos. Intenta nuevamente.',
        'offer_expired' =>
          'La oferta venció. Repite la búsqueda antes de guardar.',
        'idempotency_conflict' =>
          'Esta solicitud ya se usó para otra selección. Repite la búsqueda.',
        'invalid_dtc_component' =>
          'Selecciona un componente asociado a esta falla.',
        'invalid_vehicle_context' ||
        'invalid_diagnostic_context' ||
        'invalid_saved_context' => 'El vehículo o diagnóstico ya no está disponible para guardar esta alternativa.',
        'owner_required' =>
          'Esta operación está reservada al propietario del taller.',
        'mechanic_invitation_required' =>
          'Sólo se pueden incorporar mecánicos mediante invitación.',
        'owner_protected' => 'El propietario no se puede desactivar ni cambiar mediante esta operación.',
        'profile_not_enabled' => 'Tu cuenta no tiene un perfil habilitado. Contacta al propietario del taller.',
        'google_not_configured' => 'El ingreso con Google estará disponible próximamente. Puedes ingresar con tu contraseña.',
        'google_unavailable' =>
          'Google no está disponible. Intenta nuevamente.',
        'invalid_google_token' || 'invalid_google_challenge' =>
          'El acceso con Google venció. Vuelve a intentarlo.',
        'invalid_onboarding_token' =>
          'El registro venció. Vuelve a continuar con Google.',
        'invalid_invitation' => 'La invitación no es válida, venció o corresponde a otro correo. Pide un nuevo enlace al administrador.',
        'link_required' => 'Esta cuenta ya existe. Vincula Google confirmando tu contraseña actual.',
        'already_linked' =>
          'La cuenta ya está vinculada. Vuelve a ingresar con Google.',
        'email_verification_required' => 'Para registrar un taller o aceptar una invitación usa una cuenta Gmail o Google Workspace.',
        'account_disabled' =>
          'Tu cuenta o taller está desactivado. Contacta al administrador.',
        'already_member' => 'La persona ya pertenece a tu taller.',
        'account_conflict' => 'La cuenta ya fue registrada. Vuelve a ingresar.',
        'invalid_workshop_name' =>
          'Ingresa un nombre de taller entre 2 y 120 caracteres.',
        'too_many_attempts' || 'invitation_limit' =>
          'Se alcanzó el límite de solicitudes. Intenta más tarde.',
        _ => null,
      };
      if (authMessage != null) {
        throw AppFailure(authMessage, statusCode: status);
      }
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
