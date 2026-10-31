import '../entities/auth_session.dart';
import '../entities/google_login_result.dart';

abstract class GoogleAuthRepository {
  Future<String?> clientId();
  Future<String> challenge();
  Future<GoogleLoginResult> login(String idToken, String nonce);
  Future<AuthSession> complete(
    String ticket,
    String action, {
    String? workshopName,
    String? invitationToken,
    String? password,
  });
}
