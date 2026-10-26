import 'package:autoscan/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  set onUnauthorized(void Function()? callback);
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> verify(AuthSession session);
  Future<void> logout();
  void clearSession();
}
