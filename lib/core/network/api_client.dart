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
      final responseData = error.response?.data;
      final code = responseData is Map ? responseData['error'] : null;
      final authMessage = switch (code) {
        'mercadolibre_not_configured' => 'Mercado Libre todavía no está configurado. Puedes seguir usando el catálogo local.',
        'mercadolibre_authorization_required' =>
          'Es necesario autorizar la cuenta de Mercado Libre en el servidor.',
        'provider_access_denied' => 'Mercado Libre no autorizó la búsqueda de publicaciones para esta aplicación. El catálogo local sigue disponible.',
        'provider_rate_limited' =>
          'Mercado Libre alcanzó su límite de consultas. Intenta más tarde.',
        'provider_timeout' ||
        'provider_unavailable' ||
        'provider_invalid_response' =>
          'No pudimos consultar Mercado Libre. Intenta nuevamente.',
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
