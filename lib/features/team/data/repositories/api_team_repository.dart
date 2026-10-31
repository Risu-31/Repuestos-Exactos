import 'package:autoscan/core/errors/app_failure.dart';
import 'package:autoscan/core/network/api_client.dart';

import '../../domain/entities/workshop_invitation.dart';
import '../../domain/repositories/team_repository.dart';

class ApiTeamRepository implements TeamRepository {
  const ApiTeamRepository(this._client);
  final ApiClient _client;
  @override
  Future<List<WorkshopInvitation>> invitations() async {
    final data = await _client.get('/invitations');
    try {
      if (data is! Map<String, dynamic> || data['data'] is! List) {
        throw const FormatException();
      }
      return (data['data'] as List).map((value) {
        if (value is! Map<String, dynamic>) throw const FormatException();
        final id = value['id_publico'];
        final email = value['email'];
        final role = value['rol'];
        final status = value['status'];
        final expiry = value['vence_en'];
        if (id is! String ||
            email is! String ||
            role is! String ||
            !{'admin', 'mecanico', 'auditor'}.contains(role) ||
            status is! String ||
            !{'pending', 'accepted', 'expired', 'revoked'}.contains(status) ||
            expiry is! String) {
          throw const FormatException();
        }
        return WorkshopInvitation(
          id: id,
          email: email,
          role: role,
          status: status,
          expiresAt: DateTime.parse(expiry),
        );
      }).toList();
    } on FormatException {
      throw const AppFailure('La lista de invitaciones no es válida.');
    }
  }

  @override
  Future<String> invite(String email) async {
    final data = await _client.post(
      '/invitations',
      data: {'email': email.trim().toLowerCase()},
    );
    if (data is! Map<String, dynamic> || data['invitation_url'] is! String) {
      throw const AppFailure('No pudimos generar el enlace.');
    }
    return data['invitation_url'] as String;
  }

  @override
  Future<void> revoke(String id) async {
    await _client.post('/invitations/${Uri.encodeComponent(id)}/revoke');
  }
}
