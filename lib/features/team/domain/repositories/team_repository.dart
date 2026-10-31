import '../entities/workshop_invitation.dart';

abstract class TeamRepository {
  Future<List<WorkshopInvitation>> invitations();
  Future<String> invite(String email);
  Future<void> revoke(String id);
}
