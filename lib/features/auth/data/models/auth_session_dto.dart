import 'package:autoscan/core/network/json_reader.dart';
import 'package:autoscan/features/auth/domain/entities/auth_session.dart';

class AuthSessionDto {
  static AuthSession parse(Object? data, {String? accessToken}) {
    final json = JsonReader.object(data);
    final user = JsonReader.object(json['usuario']);
    final workshop = JsonReader.object(json['taller']);
    final token = accessToken ?? JsonReader.text(json, 'access_token');
    final expires = DateTime.tryParse(JsonReader.text(json, 'expires_at'));
    final role = JsonReader.text(user, 'rol');
    final userId = JsonReader.text(user, 'id_publico');
    final workshopId = JsonReader.text(workshop, 'id_publico');
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
    );
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token) ||
        expires == null ||
        !{'admin', 'mecanico', 'auditor'}.contains(role) ||
        !uuid.hasMatch(userId) ||
        !uuid.hasMatch(workshopId) ||
        (accessToken == null && json['token_type'] != 'Bearer')) {
      throw const FormatException('Sesión inválida.');
    }
    return AuthSession(
      accessToken: token,
      expiresAt: expires.toUtc(),
      userId: userId,
      workshopId: workshopId,
      name: JsonReader.text(user, 'nombre'),
      role: role,
    );
  }
}
