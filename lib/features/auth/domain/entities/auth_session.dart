class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.userId,
    required this.workshopId,
    required this.name,
    required this.role,
  });
  final String accessToken;
  final DateTime expiresAt;
  final String userId;
  final String workshopId;
  final String name;
  final String role;

  String get roleLabel => switch (role) {
    'admin' => 'Administración',
    'mecanico' => 'Mecánica',
    'auditor' => 'Auditoría',
    _ => role,
  };
}
