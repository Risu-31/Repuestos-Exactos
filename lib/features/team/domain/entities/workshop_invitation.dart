class WorkshopInvitation {
  const WorkshopInvitation({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.expiresAt,
  });
  final String id;
  final String email;
  final String role;
  final String status;
  final DateTime expiresAt;
  String get statusLabel => switch (status) {
    'pending' => 'Pendiente',
    'accepted' => 'Aceptada',
    'expired' => 'Vencida',
    'revoked' => 'Revocada',
    _ => status,
  };
}
