import 'auth_session.dart';

class GoogleLoginResult {
  const GoogleLoginResult({
    this.session,
    this.onboardingToken,
    this.email,
    this.name,
    this.requiresLink = false,
    this.canRegister = false,
  });
  final AuthSession? session;
  final String? onboardingToken;
  final String? email;
  final String? name;
  final bool requiresLink;
  final bool canRegister;
}
